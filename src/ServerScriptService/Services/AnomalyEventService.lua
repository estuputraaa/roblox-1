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
	self._endingService = nil
	self._economy = nil
	self._warningRemote = nil
	self._eventPublisher = nil
	self._isEventActive = false
	self._elapsedSinceLastEvent = 0
	self._rng = Random.new()
	self._nextEventAtSeconds = self:_rollNextEventWindow()
	return self
end

function AnomalyEventService:SetRuntimeContext(options)
	options = options or {}
	self._gameDirector = options.gameDirector
	self._endingService = options.endingService
	self._economy = options.economy
	self._warningRemote = options.warningRemote
	self._eventPublisher = options.publishEventFeed
end

function AnomalyEventService:_rollNextEventWindow()
	return self._rng:NextNumber(DEFAULT_MIN_COOLDOWN_SECONDS, DEFAULT_MAX_COOLDOWN_SECONDS)
end

function AnomalyEventService:_publishWarning(payload)
	if not self._warningRemote then
		-- no-op, continue to optional publisher callback below
	else
		local ok, err = pcall(function()
			self._warningRemote:FireAllClients(payload)
		end)
		if not ok then
			warn(("AnomalyEventService: gagal publish warning: %s"):format(tostring(err)))
		end
	end

	if self._eventPublisher then
		local ok, err = pcall(function()
			self._eventPublisher(payload)
		end)
		if not ok then
			warn(("AnomalyEventService: gagal publish callback warning: %s"):format(tostring(err)))
		end
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

function AnomalyEventService:_recordEndingFlag(player, flagName, value)
	if self._endingService and self._endingService.RecordFlag then
		return self._endingService:RecordFlag(player, flagName, value)
	end
	if self._economy and self._economy.SetFlag then
		self._economy:SetFlag(player, flagName, value)
		return true
	end
	return false
end

function AnomalyEventService:_getEndingFlag(player, flagName)
	if self._endingService and self._endingService.GetFlag then
		return self._endingService:GetFlag(player, flagName)
	end
	if self._economy and self._economy.GetFlag then
		return self._economy:GetFlag(player, flagName)
	end
	return nil
end

function AnomalyEventService:_maybeTriggerHiddenPortal(player, context)
	if not player then
		return false
	end
	if self:_getEndingFlag(player, "enteredHiddenPortal") == true then
		return false
	end

	local discoveryChance = context.portalDiscoveryChance
	if type(discoveryChance) ~= "number" then
		discoveryChance = 0.08
	end
	local shouldDiscover = context.forceHiddenPortal == true or self._rng:NextNumber(0, 1) <= math.clamp(discoveryChance, 0, 1)
	if not shouldDiscover then
		return false
	end

	self:_recordEndingFlag(player, "enteredHiddenPortal", true)
	self:_publishWarning({
		type = "HiddenPortalDiscovered",
		message = "Portal tersembunyi terbuka sesaat. Ending rahasia terdeteksi.",
	})
	return true
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
	if miniGameResult and miniGameResult.success then
		self:_maybeTriggerHiddenPortal(player, context)
	end

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
