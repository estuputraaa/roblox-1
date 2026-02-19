--[[
Main.server
- Bootstrap service utama dan pipeline feedback server->client.
- Menjaga HUD/event feed tetap sinkron dengan state runtime game.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServicesFolder = script.Parent:WaitForChild("Services")

local EconomyManager = require(ServicesFolder:WaitForChild("EconomyManager"))
local NPCSpawner = require(ServicesFolder:WaitForChild("NPCSpawner"))
local NPCBehaviorRunner = require(ServicesFolder:WaitForChild("NPCBehaviorRunner"))
local MiniGameService = require(ServicesFolder:WaitForChild("MiniGameService"))
local AnomalyEventService = require(ServicesFolder:WaitForChild("AnomalyEventService"))
local EndingService = require(ServicesFolder:WaitForChild("EndingService"))
local MonetizationService = require(ServicesFolder:WaitForChild("MonetizationService"))
local GameDirector = require(ServicesFolder:WaitForChild("GameDirector"))
local PersistenceService = require(ServicesFolder:WaitForChild("PersistenceService"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SharedRemotes = Shared:WaitForChild("Remotes")
local RemoteNames = require(SharedRemotes:WaitForChild("RemoteNames"))

local economy = EconomyManager.new()
economy:Init()

local spawner = NPCSpawner.new()
local miniGames = MiniGameService.new(economy)
local anomaly = AnomalyEventService.new(spawner, miniGames)
local ending = EndingService.new({
	economy = economy,
})
local monetization = MonetizationService.new(economy)
local persistence = PersistenceService.new()
local behaviorRunner = NPCBehaviorRunner.new({
	economy = economy,
	miniGames = miniGames,
	anomaly = anomaly,
	ending = ending,
})
spawner:SetBehaviorRunner(behaviorRunner)

local gameDirector = GameDirector.new({
	economy = economy,
	spawner = spawner,
	miniGames = miniGames,
	anomaly = anomaly,
	ending = ending,
	monetization = monetization,
	persistence = persistence,
})

local serverRemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not serverRemotesFolder then
	serverRemotesFolder = Instance.new("Folder")
	serverRemotesFolder.Name = "Remotes"
	serverRemotesFolder.Parent = ReplicatedStorage
end

local function ensureRemoteEvent(remoteName)
	local remote = serverRemotesFolder:FindFirstChild(remoteName)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if remote then
		remote:Destroy()
	end

	local created = Instance.new("RemoteEvent")
	created.Name = remoteName
	created.Parent = serverRemotesFolder
	return created
end

local remotes = {
	[RemoteNames.HUDUpdate] = ensureRemoteEvent(RemoteNames.HUDUpdate),
	[RemoteNames.EventFeed] = ensureRemoteEvent(RemoteNames.EventFeed),
	[RemoteNames.MiniGamePrompt] = ensureRemoteEvent(RemoteNames.MiniGamePrompt),
	[RemoteNames.DayTransition] = ensureRemoteEvent(RemoteNames.DayTransition),
	[RemoteNames.DayPhaseUpdate] = ensureRemoteEvent(RemoteNames.DayPhaseUpdate),
	[RemoteNames.DayTimerUpdate] = ensureRemoteEvent(RemoteNames.DayTimerUpdate),
	[RemoteNames.FailTriggered] = ensureRemoteEvent(RemoteNames.FailTriggered),
	[RemoteNames.ContinuePrompt] = ensureRemoteEvent(RemoteNames.ContinuePrompt),
	[RemoteNames.EndingTriggered] = ensureRemoteEvent(RemoteNames.EndingTriggered),
	[RemoteNames.MiniGameResult] = ensureRemoteEvent(RemoteNames.MiniGameResult),
	[RemoteNames.AnomalyWarning] = ensureRemoteEvent(RemoteNames.AnomalyWarning),
}

local function fireAllSafe(remoteEvent, payload)
	if not remoteEvent then
		return
	end
	local ok, err = pcall(function()
		remoteEvent:FireAllClients(payload)
	end)
	if not ok then
		warn(("Main.server: gagal kirim remote '%s': %s"):format(remoteEvent.Name, tostring(err)))
	end
end

local function publishEventFeed(message, level, eventType)
	fireAllSafe(remotes[RemoteNames.EventFeed], {
		type = eventType or "system",
		level = level or "info",
		message = message,
		timestamp = os.time(),
	})
end

ending:SetRuntimeContext({
	endingRemote = remotes[RemoteNames.EndingTriggered],
})

anomaly:SetRuntimeContext({
	gameDirector = gameDirector,
	endingService = ending,
	economy = economy,
	warningRemote = remotes[RemoteNames.AnomalyWarning],
	publishEventFeed = function(payload)
		local message = (type(payload) == "table" and payload.message) or "Anomali terdeteksi."
		local eventType = (type(payload) == "table" and payload.type) or "anomaly"
		local level = "warning"
		if eventType == "HiddenPortalDiscovered" then
			level = "critical"
		end
		publishEventFeed(message, level, tostring(eventType))
	end,
})

behaviorRunner:SetServices({
	economy = economy,
	miniGames = miniGames,
	anomaly = anomaly,
	ending = ending,
	gameDirector = gameDirector,
})

MarketplaceService.ProcessReceipt = function(receiptInfo)
	return monetization:ProcessReceipt(receiptInfo)
end

local function getRandomSpawnCFrame()
	local spawnPointsFolder = workspace:FindFirstChild("NPCSpawnPoints")
	if not spawnPointsFolder then
		return nil
	end

	local points = {}
	for _, instance in ipairs(spawnPointsFolder:GetChildren()) do
		if instance:IsA("BasePart") then
			table.insert(points, instance)
		end
	end

	if #points == 0 then
		return nil
	end

	local randomIndex = math.random(1, #points)
	return points[randomIndex].CFrame
end

local function getPhaseLabel(phaseName)
	if phaseName == "Night" then
		return "Malam"
	end
	return "Pagi"
end

local function buildHudPayload()
	local activePlayer = gameDirector:GetActivePlayer()
	local day = gameDirector:GetCurrentDay()
	local phaseName = gameDirector:GetCurrentPhase()
	local stateName = gameDirector:GetState()
	local timeRemaining = math.max(0, math.floor(gameDirector:GetPhaseTimeRemaining()))
	local cash = activePlayer and economy:GetBalance(activePlayer) or 0
	local objective = gameDirector.GetHudObjectiveText and gameDirector:GetHudObjectiveText() or "Survive sampai hari 7"

	return {
		day = day,
		phase = phaseName,
		phaseLabel = getPhaseLabel(phaseName),
		state = stateName,
		timeRemainingSeconds = timeRemaining,
		cash = cash,
		eventBudget = gameDirector:GetEventBudgetForPhase(),
		objective = objective,
		hint = "Hint ending: survive day 7, cari bonk TungTung atau portal tersembunyi.",
		timestamp = os.time(),
	}
end

local spawnAccumulator = 0
local hudAccumulator = 0
local baseSpawnIntervalSeconds = 2.25
local minimumSpawnIntervalSeconds = 0.4
local hudPushIntervalSeconds = 0.5

local lastState = {
	day = nil,
	phase = nil,
	state = nil,
	endingCode = nil,
}

local function publishTransitionsIfChanged()
	local currentDay = gameDirector:GetCurrentDay()
	local currentPhase = gameDirector:GetCurrentPhase()
	local currentState = gameDirector:GetState()
	local currentEndingCode = gameDirector:GetLastEndingCode()

	if lastState.day and lastState.day ~= currentDay then
		fireAllSafe(remotes[RemoteNames.DayTransition], {
			fromDay = lastState.day,
			toDay = currentDay,
			timestamp = os.time(),
		})
		publishEventFeed(("Hari %d dimulai."):format(currentDay), "info", "day_transition")
	end

	if lastState.phase and lastState.phase ~= currentPhase then
		fireAllSafe(remotes[RemoteNames.DayPhaseUpdate], {
			phase = currentPhase,
			label = getPhaseLabel(currentPhase),
			timestamp = os.time(),
		})
		publishEventFeed(("Fase berganti: %s"):format(getPhaseLabel(currentPhase)), currentPhase == "Night" and "warning" or "info", "phase_change")
	end

	if lastState.state and lastState.state ~= currentState then
		if currentState == "GameOver" then
			fireAllSafe(remotes[RemoteNames.FailTriggered], {
				reason = gameDirector:GetLastFailReason() or "unknown",
				timestamp = os.time(),
			})
			publishEventFeed("Kondisi kritis! Run gagal sementara.", "critical", "fail")
		elseif currentState == "LobbyReturn" then
			fireAllSafe(remotes[RemoteNames.ContinuePrompt], {
				status = "declined",
				timestamp = os.time(),
			})
			publishEventFeed("Continue ditolak. Kembali ke lobby.", "warning", "continue")
		elseif currentState == "DayInProgress" and lastState.state == "GameOver" then
			fireAllSafe(remotes[RemoteNames.ContinuePrompt], {
				status = "granted",
				timestamp = os.time(),
			})
			publishEventFeed("Continue berhasil. Run dilanjutkan.", "info", "continue")
		elseif currentState == "Completed" then
			publishEventFeed("Run selesai. Periksa hasil ending.", "info", "run_complete")
		end
	end

	if currentEndingCode and lastState.endingCode ~= currentEndingCode then
		publishEventFeed(("Ending tercapai: %s"):format(currentEndingCode), "critical", "ending")
	end

	lastState.day = currentDay
	lastState.phase = currentPhase
	lastState.state = currentState
	lastState.endingCode = currentEndingCode
end

local function pushHudSnapshot(reason)
	local payload = buildHudPayload()
	payload.reason = reason or "periodic"
	fireAllSafe(remotes[RemoteNames.HUDUpdate], payload)
	fireAllSafe(remotes[RemoteNames.DayTimerUpdate], {
		timeRemainingSeconds = payload.timeRemainingSeconds,
		phase = payload.phase,
		timestamp = payload.timestamp,
	})
end

RunService.Heartbeat:Connect(function(deltaTime)
	gameDirector:Tick(deltaTime)
	publishTransitionsIfChanged()

	hudAccumulator += deltaTime
	if hudAccumulator >= hudPushIntervalSeconds then
		hudAccumulator = 0
		pushHudSnapshot("periodic")
	end

	if not gameDirector:IsRunActive() then
		return
	end

	spawnAccumulator += deltaTime
	local difficulty = gameDirector:GetDifficultyForCurrentDay()
	local spawnRateMultiplier = difficulty and difficulty.spawnRateMultiplier or 1
	local effectiveInterval = math.max(minimumSpawnIntervalSeconds, baseSpawnIntervalSeconds / math.max(0.1, spawnRateMultiplier))
	if spawnAccumulator < effectiveInterval then
		return
	end
	spawnAccumulator = 0

	local spawnProfile = gameDirector:GetSpawnProfile()
	local canSpawn = spawner:CanAttemptSpawn(spawnProfile, gameDirector)
	if canSpawn then
		spawner:SpawnNPC({
			profileName = spawnProfile,
			spawnCFrame = getRandomSpawnCFrame(),
			gameDirector = gameDirector,
		})
	end

	anomaly:Tick(deltaTime, {
		player = gameDirector:GetActivePlayer(),
		spawnCFrame = getRandomSpawnCFrame(),
		difficulty = difficulty,
		phaseName = gameDirector:GetCurrentPhase(),
	})
end)

local function startRunForPlayer(player)
	local snapshot = persistence:LoadPlayerState(player)
	if snapshot then
		if snapshot.balance and economy.SetBalance then
			economy:SetBalance(player, snapshot.balance, "LoadSavedState")
		end
		if snapshot.day and gameDirector.HydrateRunState then
			gameDirector:HydrateRunState(snapshot.day, snapshot.phase)
		end
		if snapshot.miniGameStats and economy.SetMiniGameStats then
			economy:SetMiniGameStats(player, snapshot.miniGameStats)
		end
	end

	if gameDirector:GetState() == "Idle" then
		gameDirector:StartRun(player)
	end

	pushHudSnapshot("player_join")
	publishEventFeed("Selamat datang di Jaga Warnet. Bertahan sampai hari 7.", "info", "welcome")
end

Players.PlayerAdded:Connect(function(player)
	startRunForPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
	persistence:SavePlayerState(player, {
		day = gameDirector:GetCurrentDay(),
		phase = gameDirector:GetCurrentPhase(),
		balance = economy:GetBalance(player),
		miniGameStats = economy:GetMiniGameStats(player),
	})
end)

local existingPlayers = Players:GetPlayers()
if #existingPlayers > 0 then
	startRunForPlayer(existingPlayers[1])
end

pushHudSnapshot("bootstrap")
print("Jaga Warnet bootstrap initialized", gameDirector:GetCurrentDay(), gameDirector:GetState())
