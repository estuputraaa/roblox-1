--[[
MonetizationConfig
- Placeholder IDs untuk GamePass dan Developer Product.
- Ganti semua ID sebelum release publik.
]]

local MonetizationConfig = {
	GamePasses = {
		FastRepair = 0,
		LuckyShift = 0,
	},
	DevProducts = {
		EmergencyCash = 0,
		ChaosShield = 0,
		ContinueRun = 0,
	},
	Rewards = {
		EmergencyCash = 150,
		ChaosShieldDurationSeconds = 120,
	},
	ContinuePolicy = {
		basePriceRobux = 20,
		stepPriceRobux = 20,
		maxPriceRobux = 120,
		recoveryCashFloor = 100,
	},
}

return MonetizationConfig
