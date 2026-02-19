--[[
Main.server
- Bootstrap sederhana untuk menghubungkan service utama.
- Cocok sebagai titik awal wiring pada project Roblox.
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
local ending = EndingService.new(economy)
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

local anomalyWarningRemote = ensureRemoteEvent(RemoteNames.AnomalyWarning)
ensureRemoteEvent(RemoteNames.EventFeed)
ensureRemoteEvent(RemoteNames.MiniGameResult)

anomaly:SetRuntimeContext({
	gameDirector = gameDirector,
	warningRemote = anomalyWarningRemote,
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

local spawnAccumulator = 0
local baseSpawnIntervalSeconds = 2.25
local minimumSpawnIntervalSeconds = 0.4

RunService.Heartbeat:Connect(function(deltaTime)
	gameDirector:Tick(deltaTime)
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
	if not canSpawn then
		-- Tetap proses anomaly tick walau spawn NPC reguler sedang tidak tersedia.
	else
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

print("Jaga Warnet bootstrap initialized", gameDirector:GetCurrentDay(), gameDirector:GetState())
