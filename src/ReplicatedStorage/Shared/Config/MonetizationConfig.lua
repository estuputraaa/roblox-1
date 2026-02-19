--[[
MonetizationConfig
- Placeholder IDs untuk GamePass dan Developer Product.
- Ganti semua ID sebelum release publik.
]]

local function normalizeId(idValue)
	local parsed = tonumber(idValue)
	if not parsed or parsed <= 0 then
		return 0
	end
	return math.floor(parsed)
end

local function clampToNonNegativeInteger(value, fallback)
	local parsed = tonumber(value)
	if not parsed then
		return math.max(0, math.floor(fallback or 0))
	end
	return math.max(0, math.floor(parsed))
end

local MonetizationConfig = {
	-- Legacy ID map tetap dipertahankan untuk backward compatibility.
	GamePasses = {
		FastRepair = 0,
		LuckyShift = 0,
	},
	-- Metadata map dipakai untuk runtime guard dan dokumentasi.
	GamePassCatalog = {
		FastRepair = {
			id = 0,
			enabled = false,
			notes = "Perk placeholder: bonus speed saat mini-game repair.",
		},
		LuckyShift = {
			id = 0,
			enabled = false,
			notes = "Perk placeholder: bonus kecil reward harian.",
		},
	},
	DevProducts = {
		EmergencyCash = 0,
		ChaosShield = 0,
		ContinueRun = 0,
	},
	DevProductCatalog = {
		EmergencyCash = {
			id = 0,
			enabled = true,
			notes = "Grant cash dummy, tetap dijaga non-breaking.",
		},
		ChaosShield = {
			id = 0,
			enabled = true,
			notes = "Buff placeholder anti penalty anomali sementara.",
		},
		ContinueRun = {
			id = 0,
			enabled = true,
			notes = "Continue unlimited attempts; display price naik per usage.",
		},
	},
	Rewards = {
		EmergencyCash = 150,
		EmergencyCashMaxGrant = 250,
		ChaosShieldDurationSeconds = 120,
		ChaosShieldMaxDurationSeconds = 180,
		FastRepairScoreBonusMultiplier = 1.1,
		LuckyShiftDailyBonusMultiplier = 1.1,
	},
	ContinuePolicy = {
		basePriceRobux = 20,
		stepPriceRobux = 20,
		maxPriceRobux = 200,
		allowUnlimitedContinue = true,
		recoveryCashFloor = 100,
	},
}

local function getCatalogEntry(catalog, key)
	if type(catalog) ~= "table" then
		return nil
	end
	local entry = catalog[key]
	if type(entry) ~= "table" then
		return nil
	end
	return entry
end

function MonetizationConfig.GetGamePassEntry(passKey)
	return getCatalogEntry(MonetizationConfig.GamePassCatalog, passKey)
end

function MonetizationConfig.GetDevProductEntry(productKey)
	return getCatalogEntry(MonetizationConfig.DevProductCatalog, productKey)
end

function MonetizationConfig.GetGamePassId(passKey)
	local entry = MonetizationConfig.GetGamePassEntry(passKey)
	if entry then
		return normalizeId(entry.id)
	end
	return normalizeId(MonetizationConfig.GamePasses[passKey])
end

function MonetizationConfig.GetDevProductId(productKey)
	local entry = MonetizationConfig.GetDevProductEntry(productKey)
	if entry then
		return normalizeId(entry.id)
	end
	return normalizeId(MonetizationConfig.DevProducts[productKey])
end

function MonetizationConfig.IsGamePassEnabled(passKey)
	local entry = MonetizationConfig.GetGamePassEntry(passKey)
	if entry then
		return entry.enabled == true and MonetizationConfig.GetGamePassId(passKey) > 0
	end
	return MonetizationConfig.GetGamePassId(passKey) > 0
end

function MonetizationConfig.IsDevProductEnabled(productKey)
	local entry = MonetizationConfig.GetDevProductEntry(productKey)
	if entry then
		return entry.enabled == true and MonetizationConfig.GetDevProductId(productKey) > 0
	end
	return MonetizationConfig.GetDevProductId(productKey) > 0
end

function MonetizationConfig.GetRewardValue(rewardKey, fallbackValue)
	return clampToNonNegativeInteger(
		MonetizationConfig.Rewards[rewardKey],
		fallbackValue or 0
	)
end

function MonetizationConfig.ResolveContinueDisplayPrice(continueUsageCount)
	local policy = MonetizationConfig.ContinuePolicy or {}
	local usageCount = clampToNonNegativeInteger(continueUsageCount, 0)
	local basePrice = clampToNonNegativeInteger(policy.basePriceRobux, 20)
	local stepPrice = clampToNonNegativeInteger(policy.stepPriceRobux, 20)
	local rawPrice = basePrice + (usageCount * stepPrice)
	local maxPrice = clampToNonNegativeInteger(policy.maxPriceRobux, rawPrice)
	if maxPrice > 0 then
		return math.min(rawPrice, maxPrice)
	end
	return rawPrice
end

function MonetizationConfig.GetContinueRecoveryCashFloor()
	local policy = MonetizationConfig.ContinuePolicy or {}
	return clampToNonNegativeInteger(policy.recoveryCashFloor, 100)
end

return MonetizationConfig
