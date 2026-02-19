--[[
MiniGameConfig
- Mendefinisikan mini-game inti dan kurva reward/penalty awal.
- Angka di bawah bersifat baseline tuning awal, bukan balancing final.
]]

local MiniGameConfig = {
	CookNoodle = {
		label = "Masak Mie",
		durationSeconds = 25,
		riskTier = "low",
		baseReward = 25,
		failurePenalty = 18,
		maxScore = 100,
		successThreshold = 58,
		scoreRangeMin = 50,
		scoreRangeMax = 100,
	},
	RepairComputer = {
		label = "Perbaiki Komputer",
		durationSeconds = 30,
		riskTier = "medium",
		baseReward = 42,
		failurePenalty = 30,
		maxScore = 100,
		successThreshold = 65,
		scoreRangeMin = 38,
		scoreRangeMax = 98,
	},
	AnomalyResponse = {
		label = "Tangani Anomali",
		durationSeconds = 20,
		riskTier = "high",
		baseReward = 70,
		failurePenalty = 52,
		maxScore = 100,
		successThreshold = 62,
		scoreRangeMin = 30,
		scoreRangeMax = 100,
	},
}

return MiniGameConfig
