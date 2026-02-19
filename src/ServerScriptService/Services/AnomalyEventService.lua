--[[
AnomalyEventService
- Menjadwalkan dan memicu event anomali.
- Menjaga trigger anomali tetap terkontrol lewat cooldown + budget phase.
]]

local AnomalyEventService = {}
AnomalyEventService.__index = AnomalyEventService

local DEFAULT_MIN_COOLDOWN_SECONDS = 40
local DEFAULT_MAX_COOLDOWN_SECONDS = 85
local DEFAULT_PROFILE_OVERRIDE_SECONDS = 8

function AnomalyEventService.new(npcSpawner, miniGameService)
	local self = setmetatable({}, AnomalyEventService)
	self._spawner = npcSpawner
	self._miniGameService = miniGameService
	self._gameDirector = nil
	self._warningRemote = nil
	self._isEventActive = false
	self._elapsedSinceLastEvent = 0
	self._rng = Random.new()
	self._nextEventAtSeconds = self:_rollNextEventWindow()
	return self
end

function AnomalyEventService:SetRuntimeContext(options)
	options = options or {}
	self._gameDirector = options.gameDirector
	self._warningRemote = options.warningRemote
end

function AnomalyEventService:_rollNextEventWindow()
	return self._rng:NextNumber(DEFAULT_MIN_COOLDOWN_SECONDS, DEFAULT_MAX_COOLDOWN_SECONDS)
end

function AnomalyEventService:_publishWarning(payload)
	if not self._warningRemote then
		return
	end

	local ok, err = pcall(function()
		self._warningRemote:FireAllClients(payload)
	end)
	if not ok then
		warn(("AnomalyEventService: gagal publish warning: %s"):format(tostring(err)))
	end
end

function AnomalyEventService:_computeTriggerChance(context)
	local difficulty = context and context.difficulty
	local phaseName = context and context.phaseName or "Morning"
	local objectivePressure = difficulty and difficulty.objectivePressure or 1
	local baseChance = 0.12 * objectivePressure
	if phaseName == "Night" then
		baseChance += 0.1
	end
	return math.clamp(baseChance, 0.1, 0.65)
end

function AnomalyEventService:_consumeBudget()
	if not self._gameDirector or not self._gameDirector.ConsumeEventBudget then
		return true
	end
	return self._gameDirector:ConsumeEventBudget(1)
end

function AnomalyEventService:TriggerAnomalyEvent(player, spawnCFrame, context)
	if self._isEventActive then
		return nil
	end

	if not player then
		return nil
	end

	self._isEventActive = true
	context = context or {}

	if self._gameDirector and self._gameDirector.ForceSpawnProfile then
		self._gameDirector:ForceSpawnProfile("EventAnomaly", context.profileDurationSeconds or DEFAULT_PROFILE_OVERRIDE_SECONDS)
	end

	self:_publishWarning({
		type = "AnomalyStart",
		message = "Anomali terdeteksi! Tangani sekarang.",
		phase = context.phaseName,
	})

	local npcModel, npcData = self._spawner:SpawnNPC({
		profileName = "EventAnomaly",
		spawnCFrame = spawnCFrame,
		gameDirector = self._gameDirector,
	})
	local miniGameResult = self._miniGameService:RunMiniGame(player, "AnomalyResponse", {
		threatLevel = context.threatLevel or "high",
	})

	local completedPayload = {
		type = "AnomalyResolved",
		message = miniGameResult and miniGameResult.success and "Anomali berhasil ditangani." or "Anomali lolos, kondisi warnet terguncang!",
		success = miniGameResult and miniGameResult.success or false,
		npcId = npcData and npcData.id or nil,
	}
	self:_publishWarning(completedPayload)

	self._isEventActive = false
	self._elapsedSinceLastEvent = 0
	self._nextEventAtSeconds = self:_rollNextEventWindow()

	return {
		npcModel = npcModel,
		npcId = npcData and npcData.id or nil,
		miniGameResult = miniGameResult,
	}
end

function AnomalyEventService:Tick(deltaTime, context)
	if deltaTime <= 0 then
		return nil
	end
	if self._isEventActive then
		return nil
	end

	self._elapsedSinceLastEvent += deltaTime
	if self._elapsedSinceLastEvent < self._nextEventAtSeconds then
		return nil
	end

	local activePlayer = context and context.player
	if not activePlayer then
		if self._gameDirector and self._gameDirector.GetActivePlayer then
			activePlayer = self._gameDirector:GetActivePlayer()
		end
	end
	if not activePlayer then
		self._nextEventAtSeconds = self:_rollNextEventWindow()
		self._elapsedSinceLastEvent = 0
		return nil
	end

	local chance = self:_computeTriggerChance(context)
	local roll = self._rng:NextNumber(0, 1)
	if roll > chance then
		self._nextEventAtSeconds = self._rng:NextNumber(8, 22)
		self._elapsedSinceLastEvent = 0
		return nil
	end

	if not self:_consumeBudget() then
		self._nextEventAtSeconds = 12
		self._elapsedSinceLastEvent = 0
		return nil
	end

	return self:TriggerAnomalyEvent(activePlayer, context and context.spawnCFrame or nil, context)
end

function AnomalyEventService:IsEventActive()
	return self._isEventActive
end

return AnomalyEventService
