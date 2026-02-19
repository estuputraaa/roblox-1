--[[
MonetizationService
- Placeholder integrasi GamePass dan DevProduct.
- Jangan gunakan ID 0 pada produksi; ini hanya scaffold.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local MonetizationConfig = require(ConfigFolder:WaitForChild("MonetizationConfig"))

local MonetizationService = {}
MonetizationService.__index = MonetizationService

local GAMEPASS_CACHE_TTL_SECONDS = 45
local RECEIPT_CACHE_SOFT_LIMIT = 500

local function clampNonNegativeInteger(value, fallback)
	local parsed = tonumber(value)
	if not parsed then
		return math.max(0, math.floor(fallback or 0))
	end
	return math.max(0, math.floor(parsed))
end

local function getRewardNumber(rewardKey, fallbackValue)
	if MonetizationConfig.GetRewardValue then
		return MonetizationConfig.GetRewardValue(rewardKey, fallbackValue)
	end
	return clampNonNegativeInteger((MonetizationConfig.Rewards or {})[rewardKey], fallbackValue)
end

function MonetizationService.new(economyManager)
	local self = setmetatable({}, MonetizationService)
	self._economy = economyManager
	self._pendingContinuePrompt = {}
	self._gamePassOwnershipCache = {}
	self._processedReceipts = {}
	self._processedReceiptOrder = {}
	self._devProductKeyById = {}

	self._onContinueGranted = nil
	self._onContinueDeclined = nil

	self:_rebuildProductLookup()

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		self:_onProductPromptFinished(userId, productId, wasPurchased)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)

	return self
end

function MonetizationService:_rebuildProductLookup()
	self._devProductKeyById = {}

	local legacyMap = MonetizationConfig.DevProducts or {}
	for productKey, productId in pairs(legacyMap) do
		local normalizedId = clampNonNegativeInteger(productId, 0)
		if normalizedId > 0 then
			self._devProductKeyById[normalizedId] = productKey
		end
	end

	local catalogMap = MonetizationConfig.DevProductCatalog or {}
	for productKey, entry in pairs(catalogMap) do
		if type(entry) == "table" then
			local normalizedId = clampNonNegativeInteger(entry.id, 0)
			if normalizedId > 0 then
				self._devProductKeyById[normalizedId] = productKey
			end
		end
	end
end

function MonetizationService:_getDevProductId(productKey)
	if MonetizationConfig.GetDevProductId then
		return MonetizationConfig.GetDevProductId(productKey)
	end
	return clampNonNegativeInteger((MonetizationConfig.DevProducts or {})[productKey], 0)
end

function MonetizationService:_isDevProductEnabled(productKey)
	if MonetizationConfig.IsDevProductEnabled then
		return MonetizationConfig.IsDevProductEnabled(productKey)
	end
	return self:_getDevProductId(productKey) > 0
end

function MonetizationService:_getGamePassId(passKey)
	if MonetizationConfig.GetGamePassId then
		return MonetizationConfig.GetGamePassId(passKey)
	end
	return clampNonNegativeInteger((MonetizationConfig.GamePasses or {})[passKey], 0)
end

function MonetizationService:_isGamePassEnabled(passKey)
	if MonetizationConfig.IsGamePassEnabled then
		return MonetizationConfig.IsGamePassEnabled(passKey)
	end
	return self:_getGamePassId(passKey) > 0
end

function MonetizationService:_resolveContinueDisplayPrice(usageCount)
	if MonetizationConfig.ResolveContinueDisplayPrice then
		return MonetizationConfig.ResolveContinueDisplayPrice(usageCount)
	end

	local policy = MonetizationConfig.ContinuePolicy or {}
	local base = clampNonNegativeInteger(policy.basePriceRobux, 20)
	local step = clampNonNegativeInteger(policy.stepPriceRobux, 20)
	local cap = clampNonNegativeInteger(policy.maxPriceRobux, base + (step * 10))
	return math.min(base + (clampNonNegativeInteger(usageCount, 0) * step), cap)
end

function MonetizationService:_getContinueRecoveryCashFloor()
	if MonetizationConfig.GetContinueRecoveryCashFloor then
		return MonetizationConfig.GetContinueRecoveryCashFloor()
	end

	local policy = MonetizationConfig.ContinuePolicy or {}
	return clampNonNegativeInteger(policy.recoveryCashFloor, 100)
end

function MonetizationService:_makeReceiptKey(receiptInfo)
	local purchaseId = receiptInfo and receiptInfo.PurchaseId
	if purchaseId then
		return tostring(purchaseId)
	end

	local playerId = receiptInfo and receiptInfo.PlayerId or 0
	local productId = receiptInfo and receiptInfo.ProductId or 0
	return ("%s:%s"):format(tostring(playerId), tostring(productId))
end

function MonetizationService:_isReceiptAlreadyProcessed(receiptKey)
	return self._processedReceipts[receiptKey] == true
end

function MonetizationService:_rememberProcessedReceipt(receiptKey)
	if self._processedReceipts[receiptKey] then
		return
	end

	self._processedReceipts[receiptKey] = true
	table.insert(self._processedReceiptOrder, receiptKey)

	if #self._processedReceiptOrder <= RECEIPT_CACHE_SOFT_LIMIT then
		return
	end

	local overflowCount = #self._processedReceiptOrder - RECEIPT_CACHE_SOFT_LIMIT
	for _ = 1, overflowCount do
		local evictedKey = table.remove(self._processedReceiptOrder, 1)
		if evictedKey then
			self._processedReceipts[evictedKey] = nil
		end
	end
end

function MonetizationService:_getContinueUsageCount(player)
	if not (self._economy and self._economy.GetContinueUsageCount) then
		return 0
	end
	return clampNonNegativeInteger(self._economy:GetContinueUsageCount(player), 0)
end

function MonetizationService:_buildContinueOffer(player)
	local usageCount = self:_getContinueUsageCount(player)
	local displayPrice = self:_resolveContinueDisplayPrice(usageCount)
	local nextDisplayPrice = self:_resolveContinueDisplayPrice(usageCount + 1)
	local continueProductId = self:_getContinueProductId()

	return {
		productKey = "ContinueRun",
		productId = continueProductId,
		usageCount = usageCount,
		displayPriceRobux = displayPrice,
		nextDisplayPriceRobux = nextDisplayPrice,
		available = continueProductId > 0 and self:_isDevProductEnabled("ContinueRun"),
		timestamp = os.time(),
	}
end

function MonetizationService:_getContinueProductId()
	return self:_getDevProductId("ContinueRun")
end

function MonetizationService:_resolveDevProductKey(productId)
	local normalized = clampNonNegativeInteger(productId, 0)
	if normalized <= 0 then
		return nil
	end
	return self._devProductKeyById[normalized]
end

function MonetizationService:_onProductPromptFinished(userId, productId, wasPurchased)
	local continueProductId = self:_getContinueProductId()
	if continueProductId == 0 or productId ~= continueProductId then
		return
	end
	if not self._pendingContinuePrompt[userId] then
		return
	end

	if not wasPurchased then
		local player = Players:GetPlayerByUserId(userId)
		if player and self._onContinueDeclined then
			self._onContinueDeclined(player, self._pendingContinuePrompt[userId])
		end
		self._pendingContinuePrompt[userId] = nil
	end
end

function MonetizationService:SetContinueHandlers(onGranted, onDeclined)
	self._onContinueGranted = onGranted
	self._onContinueDeclined = onDeclined
end

function MonetizationService:GetContinuePrice(player)
	return self:_resolveContinueDisplayPrice(self:_getContinueUsageCount(player))
end

function MonetizationService:GetContinueOffer(player)
	return self:_buildContinueOffer(player)
end

function MonetizationService:GetContinueRecoveryCashFloor()
	return self:_getContinueRecoveryCashFloor()
end

function MonetizationService:GetPendingContinueOffer(player)
	if not player then
		return nil
	end
	return self._pendingContinuePrompt[player.UserId]
end

function MonetizationService:PlayerHasGamePass(player, passKey)
	if not player or not passKey then
		return false
	end

	local passId = self:_getGamePassId(passKey)
	if passId <= 0 or not self:_isGamePassEnabled(passKey) then
		return false
	end

	local now = os.clock()
	local userCache = self._gamePassOwnershipCache[player.UserId]
	if userCache and userCache[passKey] then
		local cached = userCache[passKey]
		if cached.expiresAt and cached.expiresAt > now then
			return cached.owns == true
		end
	end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if not ok then
		return false
	end

	self._gamePassOwnershipCache[player.UserId] = self._gamePassOwnershipCache[player.UserId] or {}
	self._gamePassOwnershipCache[player.UserId][passKey] = {
		owns = owns == true,
		expiresAt = now + GAMEPASS_CACHE_TTL_SECONDS,
	}

	return owns
end

function MonetizationService:PromptDevProductPurchase(player, productKey)
	if not player then
		return false
	end

	local productId = self:_getDevProductId(productKey)
	if productId <= 0 or not self:_isDevProductEnabled(productKey) then
		warn(("MonetizationService: Product key '%s' belum punya ID valid"):format(tostring(productKey)))
		return false
	end

	local ok, promptError = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	if not ok then
		warn(("MonetizationService: gagal prompt product '%s': %s"):format(tostring(productKey), tostring(promptError)))
		return false
	end
	return true
end

function MonetizationService:PromptContinuePurchase(player)
	if not player then
		return false, nil
	end

	local offer = self:_buildContinueOffer(player)
	if not offer.available then
		warn("MonetizationService: ContinueRun product ID belum valid")
		return false, offer
	end

	self._pendingContinuePrompt[player.UserId] = offer
	local ok, promptError = pcall(function()
		MarketplaceService:PromptProductPurchase(player, offer.productId)
	end)
	if not ok then
		self._pendingContinuePrompt[player.UserId] = nil
		warn(("MonetizationService: gagal menampilkan continue prompt: %s"):format(tostring(promptError)))
		return false, offer
	end

	return true, offer
end

function MonetizationService:_applyEmergencyCashReward(player)
	local emergencyCash = getRewardNumber("EmergencyCash", 150)
	local emergencyCashCap = getRewardNumber("EmergencyCashMaxGrant", emergencyCash)
	local grantAmount = math.min(emergencyCash, emergencyCashCap)
	if grantAmount <= 0 then
		return false
	end
	if not (self._economy and self._economy.AddCash) then
		return false
	end
	return self._economy:AddCash(player, grantAmount, "DevProductEmergencyCash")
end

function MonetizationService:_applyChaosShieldReward(player)
	if not (self._economy and self._economy.SetFlag) then
		return true
	end

	local baseDuration = getRewardNumber("ChaosShieldDurationSeconds", 120)
	local maxDuration = getRewardNumber("ChaosShieldMaxDurationSeconds", baseDuration)
	local duration = math.min(baseDuration, maxDuration)
	if duration <= 0 then
		return true
	end

	self._economy:SetFlag(player, "chaosShieldExpiresAt", os.time() + duration)
	return true
end

function MonetizationService:_applyContinueReward(player, context)
	local continueContext = context or self._pendingContinuePrompt[player.UserId]
	self._pendingContinuePrompt[player.UserId] = nil

	if self._economy and self._economy.IncrementContinueUsageCount then
		self._economy:IncrementContinueUsageCount(player)
	end

	if self._onContinueGranted then
		self._onContinueGranted(player, continueContext)
		return true
	end

	if self._economy and self._economy.RecoverToMinimumBalance then
		self._economy:RecoverToMinimumBalance(player, self:_getContinueRecoveryCashFloor(), "ContinueRecovery")
	end
	return true
end

function MonetizationService:ApplyPassiveDailyBonus(player, dayNumber)
	if not player then
		return 0
	end
	if not self:PlayerHasGamePass(player, "LuckyShift") then
		return 0
	end
	if not (self._economy and self._economy.AddCash) then
		return 0
	end

	local rewards = MonetizationConfig.Rewards or {}
	local dailyMultiplier = tonumber(rewards.LuckyShiftDailyBonusMultiplier) or 1
	if dailyMultiplier <= 1 then
		return 0
	end

	local baseBonus = 30 + (clampNonNegativeInteger(dayNumber, 1) * 10)
	local extraBonus = math.floor(baseBonus * (dailyMultiplier - 1))
	local clampedBonus = math.clamp(extraBonus, 0, 40)
	if clampedBonus <= 0 then
		return 0
	end

	local ok = self._economy:AddCash(player, clampedBonus, "GamePassLuckyShift")
	if not ok then
		return 0
	end

	return clampedBonus
end

function MonetizationService:RefreshPlayerPerkFlags(player)
	if not (player and self._economy and self._economy.SetFlag) then
		return
	end
	self._economy:SetFlag(player, "perkFastRepair", self:PlayerHasGamePass(player, "FastRepair"))
	self._economy:SetFlag(player, "perkLuckyShift", self:PlayerHasGamePass(player, "LuckyShift"))
end

function MonetizationService:GetMonetizationStatus(player)
	local continueOffer = self:GetContinueOffer(player)
	return {
		continueOffer = continueOffer,
		passes = {
			FastRepair = self:PlayerHasGamePass(player, "FastRepair"),
			LuckyShift = self:PlayerHasGamePass(player, "LuckyShift"),
		},
	}
end

function MonetizationService:ProcessReceipt(receiptInfo)
	if type(receiptInfo) ~= "table" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = self:_makeReceiptKey(receiptInfo)
	if self:_isReceiptAlreadyProcessed(receiptKey) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local productKey = self:_resolveDevProductKey(receiptInfo.ProductId)
	if not productKey then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local granted = false
	if productKey == "EmergencyCash" then
		granted = self:_applyEmergencyCashReward(player)
	elseif productKey == "ChaosShield" then
		granted = self:_applyChaosShieldReward(player)
	elseif productKey == "ContinueRun" then
		local context = self._pendingContinuePrompt[player.UserId] or self:_buildContinueOffer(player)
		granted = self:_applyContinueReward(player, context)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not granted then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	self:_rememberProcessedReceipt(receiptKey)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:OnPlayerRemoving(player)
	if not player then
		return
	end
	self._pendingContinuePrompt[player.UserId] = nil
	self._gamePassOwnershipCache[player.UserId] = nil
end

return MonetizationService
