--[[
DayCycleConfig
- Kontrak pacing Phase 1:
  - 1 hari in-game = 10 menit
  - Pagi 5 menit, malam 5 menit
  - Event budget: pagi 1, malam 2
- Difficulty harian dibuat deterministic per run seed, dengan hari ke-7 dipaksa peak.
]]

local DayCycleConfig = {}

DayCycleConfig.MaxDays = 7
DayCycleConfig.DayDurationSeconds = 600
DayCycleConfig.MorningDurationSeconds = 300
DayCycleConfig.NightDurationSeconds = 300

DayCycleConfig.EventBudgetByPhase = {
	Morning = 1,
	Night = 2,
}

DayCycleConfig.NightSpawnComposition = {
	normal = 50,
	anomaly = 35,
	meme = 15,
}

DayCycleConfig.DifficultyProfiles = {
	Breathing = {
		id = "breathing",
		spawnRateMultiplier = 0.9,
		penaltyMultiplier = 0.9,
		miniGameComplexity = 0.9,
		objectivePressure = 0.85,
	},
	Steady = {
		id = "steady",
		spawnRateMultiplier = 1.0,
		penaltyMultiplier = 1.0,
		miniGameComplexity = 1.0,
		objectivePressure = 1.0,
	},
	Spike = {
		id = "spike",
		spawnRateMultiplier = 1.2,
		penaltyMultiplier = 1.15,
		miniGameComplexity = 1.15,
		objectivePressure = 1.2,
	},
	Peak = {
		id = "peak",
		spawnRateMultiplier = 1.4,
		penaltyMultiplier = 1.35,
		miniGameComplexity = 1.35,
		objectivePressure = 1.45,
	},
}

local randomWavePool = {
	"Breathing",
	"Steady",
	"Spike",
	"Steady",
	"Breathing",
}

local function cloneProfile(profile)
	return {
		id = profile.id,
		spawnRateMultiplier = profile.spawnRateMultiplier,
		penaltyMultiplier = profile.penaltyMultiplier,
		miniGameComplexity = profile.miniGameComplexity,
		objectivePressure = profile.objectivePressure,
	}
end

function DayCycleConfig.GetPhaseDurationSeconds(phaseName)
	if phaseName == "Morning" then
		return DayCycleConfig.MorningDurationSeconds
	end
	if phaseName == "Night" then
		return DayCycleConfig.NightDurationSeconds
	end
	return 0
end

function DayCycleConfig.GetDifficultyForDay(dayNumber, runSeed)
	if dayNumber >= DayCycleConfig.MaxDays then
		return cloneProfile(DayCycleConfig.DifficultyProfiles.Peak)
	end

	local seed = (runSeed or 1) + (dayNumber * 7919)
	local rng = Random.new(seed)
	local selected = randomWavePool[rng:NextInteger(1, #randomWavePool)]
	return cloneProfile(DayCycleConfig.DifficultyProfiles[selected])
end

return DayCycleConfig
