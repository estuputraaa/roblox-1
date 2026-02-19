--[[
Main.server
- Bootstrap sederhana untuk menghubungkan service utama.
- Cocok sebagai titik awal wiring pada project Roblox.
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local ServicesFolder = script.Parent:WaitForChild("Services")

local EconomyManager = require(ServicesFolder:WaitForChild("EconomyManager"))
local NPCSpawner = require(ServicesFolder:WaitForChild("NPCSpawner"))
local MiniGameService = require(ServicesFolder:WaitForChild("MiniGameService"))
local AnomalyEventService = require(ServicesFolder:WaitForChild("AnomalyEventService"))
local EndingService = require(ServicesFolder:WaitForChild("EndingService"))
local MonetizationService = require(ServicesFolder:WaitForChild("MonetizationService"))
local GameDirector = require(ServicesFolder:WaitForChild("GameDirector"))

local economy = EconomyManager.new()
economy:Init()

local spawner = NPCSpawner.new()
local miniGames = MiniGameService.new(economy)
local anomaly = AnomalyEventService.new(spawner, miniGames)
local ending = EndingService.new(economy)
local monetization = MonetizationService.new(economy)

local gameDirector = GameDirector.new({
	economy = economy,
	spawner = spawner,
	miniGames = miniGames,
	anomaly = anomaly,
	ending = ending,
	monetization = monetization,
})

MarketplaceService.ProcessReceipt = function(receiptInfo)
	return monetization:ProcessReceipt(receiptInfo)
end

RunService.Heartbeat:Connect(function(deltaTime)
	gameDirector:Tick(deltaTime)
end)

local function startRunForPlayer(player)
	if gameDirector:GetState() == "Idle" then
		gameDirector:StartRun(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	startRunForPlayer(player)
end)

local existingPlayers = Players:GetPlayers()
if #existingPlayers > 0 then
	startRunForPlayer(existingPlayers[1])
end

print("Jaga Warnet bootstrap initialized", gameDirector:GetCurrentDay(), gameDirector:GetState())
