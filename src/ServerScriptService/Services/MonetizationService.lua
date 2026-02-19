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

function MonetizationService.new(economyManager)
	local self = setmetatable({}, MonetizationService)
	self._economy = economyManager
	self._pendingContinuePrompt = {}
	self._onContinueGranted = nil
	self._onContinueDeclined = nil

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		self:_onProductPromptFinished(userId, productId, wasPurchased)
	end)

	return self
end

function MonetizationService:_getContinueProductId()
	return MonetizationConfig.DevProducts.ContinueRun
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
			self._onContinueDeclined(player)
		end
		self._pendingContinuePrompt[userId] = nil
	end
end

function MonetizationService:SetContinueHandlers(onGranted, onDeclined)
	self._onContinueGranted = onGranted
	self._onContinueDeclined = onDeclined
end

function MonetizationService:GetContinuePrice(player)
	local policy = MonetizationConfig.ContinuePolicy
	if not policy then
		return 0
	end

	local usageCount = 0
	if self._economy and self._economy.GetContinueUsageCount then
		usageCount = self._economy:GetContinueUsageCount(player)
	end

	local base = policy.basePriceRobux or 20
	local step = policy.stepPriceRobux or 20
	local cap = policy.maxPriceRobux or 120
	return math.min(base + (usageCount * step), cap)
end

function MonetizationService:PlayerHasGamePass(player, passKey)
	local passId = MonetizationConfig.GamePasses[passKey]
	if not passId or passId == 0 then
		return false
	end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	if not ok then
		return false
	end
	return owns
end

function MonetizationService:PromptDevProductPurchase(player, productKey)
	local productId = MonetizationConfig.DevProducts[productKey]
	if not productId or productId == 0 then
		warn(("MonetizationService: Product key '%s' belum punya ID valid"):format(tostring(productKey)))
		return
	end
	MarketplaceService:PromptProductPurchase(player, productId)
end

function MonetizationService:PromptContinuePurchase(player)
	if not player then
		return false
	end

	local continueProductId = self:_getContinueProductId()
	if not continueProductId or continueProductId == 0 then
		warn("MonetizationService: ContinueRun product ID belum valid")
		return false
	end

	self._pendingContinuePrompt[player.UserId] = true
	local ok, promptError = pcall(function()
		MarketplaceService:PromptProductPurchase(player, continueProductId)
	end)
	if not ok then
		self._pendingContinuePrompt[player.UserId] = nil
		warn(("MonetizationService: gagal menampilkan continue prompt: %s"):format(tostring(promptError)))
		return false
	end

	return true
end

function MonetizationService:ProcessReceipt(receiptInfo)
	-- TODO: Hubungkan callback ini ke MarketplaceService.ProcessReceipt.
	-- Placeholder logic untuk EmergencyCash.
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	for key, productId in pairs(MonetizationConfig.DevProducts) do
		if productId == receiptInfo.ProductId then
			if key == "EmergencyCash" then
				self._economy:AddCash(player, MonetizationConfig.Rewards.EmergencyCash, "DevProductEmergencyCash")
			elseif key == "ContinueRun" then
				self._pendingContinuePrompt[player.UserId] = nil
				if self._economy and self._economy.IncrementContinueUsageCount then
					self._economy:IncrementContinueUsageCount(player)
				end
				if self._onContinueGranted then
					self._onContinueGranted(player)
				elseif self._economy and self._economy.RecoverToMinimumBalance then
					local policy = MonetizationConfig.ContinuePolicy or {}
					self._economy:RecoverToMinimumBalance(player, policy.recoveryCashFloor or 100, "ContinueRecovery")
				end
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return MonetizationService
