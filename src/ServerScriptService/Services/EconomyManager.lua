--[[
EconomyManager
- Menangani saldo uang pemain, reward mini-game, bonus survive harian, dan penalty operasional.
- Ini skeleton: persistence DataStore dan anti-exploit server validation perlu dilengkapi.
]]

local Players = game:GetService("Players")

local EconomyManager = {}
EconomyManager.__index = EconomyManager

local DEFAULT_BALANCE = 150
local FLAT_OPERATIONAL_COST = 30

function EconomyManager.new()
	local self = setmetatable({}, EconomyManager)
	self._playerData = {}
	return self
end

function EconomyManager:Init()
	Players.PlayerAdded:Connect(function(player)
		self:RegisterPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:UnregisterPlayer(player)
	end)
end

function EconomyManager:RegisterPlayer(player)
	self._playerData[player.UserId] = {
		balance = DEFAULT_BALANCE,
		daySurvived = 0,
		totalMiniGamesPlayed = 0,
		totalMiniGameSuccess = 0,
		flags = {},
	}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = DEFAULT_BALANCE
	cash.Parent = leaderstats
end

function EconomyManager:UnregisterPlayer(player)
	-- TODO: Persist data ke DataStore sebelum cleanup.
	self._playerData[player.UserId] = nil
end

function EconomyManager:GetData(player)
	return self._playerData[player.UserId]
end

function EconomyManager:GetBalance(player)
	local data = self:GetData(player)
	if not data then
		return 0
	end
	return data.balance
end

function EconomyManager:_syncLeaderstats(player)
	local data = self:GetData(player)
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local cash = leaderstats:FindFirstChild("Cash")
	if cash then
		cash.Value = data.balance
	end
end

function EconomyManager:AddCash(player, amount, reason)
	local data = self:GetData(player)
	if not data then
		return false
	end

	data.balance += math.max(0, math.floor(amount))
	self:_syncLeaderstats(player)
	-- TODO: Emit analytics event with reason.
	return true
end

function EconomyManager:TrySpendCash(player, amount, reason)
	local data = self:GetData(player)
	if not data then
		return false
	end

	local spend = math.max(0, math.floor(amount))
	if data.balance < spend then
		return false
	end

	data.balance -= spend
	self:_syncLeaderstats(player)
	-- TODO: Emit analytics event with reason.
	return true
end

function EconomyManager:ApplyMiniGameResult(player, miniGameId, score, success, baseReward, failurePenalty)
	local data = self:GetData(player)
	if not data then
		return
	end

	data.totalMiniGamesPlayed += 1
	if success then
		data.totalMiniGameSuccess += 1
	end

	local normalizedScore = math.clamp(score or 0, 0, 100) / 100
	if success then
		local reward = math.floor((baseReward or 0) * (0.5 + normalizedScore))
		self:AddCash(player, reward, ("MiniGameReward:%s"):format(miniGameId))
	else
		local penalty = math.floor((failurePenalty or 0) * (1.0 - normalizedScore * 0.5))
		self:TrySpendCash(player, penalty, ("MiniGamePenalty:%s"):format(miniGameId))
	end
end

function EconomyManager:AwardDailySurvival(player, dayNumber)
	local dayBonus = 30 + (dayNumber * 10)
	self:AddCash(player, dayBonus, "DailySurvivalBonus")

	local data = self:GetData(player)
	if data then
		data.daySurvived = math.max(data.daySurvived, dayNumber)
	end
end

function EconomyManager:ApplyOperationalCost(player, _dayNumber)
	self:TrySpendCash(player, FLAT_OPERATIONAL_COST, "OperationalCost")
end

function EconomyManager:SetFlag(player, flagName, flagValue)
	local data = self:GetData(player)
	if not data then
		return
	end
	data.flags[flagName] = flagValue
end

function EconomyManager:GetFlag(player, flagName)
	local data = self:GetData(player)
	if not data then
		return nil
	end
	return data.flags[flagName]
end

return EconomyManager
