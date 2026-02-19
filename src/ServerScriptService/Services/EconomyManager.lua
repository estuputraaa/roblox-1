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

local function cloneTableDeep(source)
	if type(source) ~= "table" then
		return source
	end

	local copy = {}
	for key, value in pairs(source) do
		copy[key] = cloneTableDeep(value)
	end
	return copy
end

local function createDefaultMiniGameStats()
	return {
		totalPlayed = 0,
		totalSuccess = 0,
		byId = {},
		lastResult = nil,
	}
end

function EconomyManager.new()
	local self = setmetatable({}, EconomyManager)
	self._playerData = {}
	self._onBalanceDepleted = nil
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
		continueUsedCount = 0,
		flags = {},
		miniGameStats = createDefaultMiniGameStats(),
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

function EconomyManager:SetBalance(player, newBalance, reason)
	local data = self:GetData(player)
	if not data then
		return false
	end

	data.balance = math.max(0, math.floor(newBalance))
	self:_syncLeaderstats(player)
	self:_notifyIfBalanceDepleted(player, reason)
	-- TODO: Emit analytics event with reason.
	return true
end

function EconomyManager:RecoverToMinimumBalance(player, minimumBalance, reason)
	local data = self:GetData(player)
	if not data then
		return false
	end

	local floor = math.max(0, math.floor(minimumBalance or 0))
	if data.balance < floor then
		return self:SetBalance(player, floor, reason or "RecoveryFloor")
	end
	return true
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

function EconomyManager:_notifyIfBalanceDepleted(player, reason)
	if not self._onBalanceDepleted then
		return
	end

	local data = self:GetData(player)
	if not data then
		return
	end

	if data.balance <= 0 then
		self._onBalanceDepleted(player, reason or "cash_depleted")
	end
end

function EconomyManager:SetBalanceDepletedHandler(handler)
	self._onBalanceDepleted = handler
end

function EconomyManager:AddCash(player, amount, reason)
	local data = self:GetData(player)
	if not data then
		return false
	end

	data.balance += math.max(0, math.floor(amount))
	self:_syncLeaderstats(player)
	self:_notifyIfBalanceDepleted(player, reason)
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
	self:_notifyIfBalanceDepleted(player, reason)
	-- TODO: Emit analytics event with reason.
	return true
end

function EconomyManager:_getFailurePenaltyMultiplier(miniGameId)
	if miniGameId == "AnomalyResponse" then
		return 1.35
	end
	return 1.0
end

function EconomyManager:_ensureMiniGameStats(data)
	if type(data.miniGameStats) ~= "table" then
		data.miniGameStats = createDefaultMiniGameStats()
	end
	if type(data.miniGameStats.byId) ~= "table" then
		data.miniGameStats.byId = {}
	end
	return data.miniGameStats
end

function EconomyManager:_getOrCreateMiniGameBucket(data, miniGameId)
	local stats = self:_ensureMiniGameStats(data)
	local bucket = stats.byId[miniGameId]
	if type(bucket) ~= "table" then
		bucket = {
			played = 0,
			success = 0,
			totalScore = 0,
			averageScore = 0,
			lastResult = nil,
		}
		stats.byId[miniGameId] = bucket
	end
	return bucket, stats
end

function EconomyManager:_updateMiniGameStats(data, envelope)
	local bucket, stats = self:_getOrCreateMiniGameBucket(data, envelope.miniGameId)
	bucket.played += 1
	if envelope.success then
		bucket.success += 1
	end
	bucket.totalScore += envelope.score
	bucket.averageScore = bucket.played > 0 and (bucket.totalScore / bucket.played) or 0
	bucket.lastResult = {
		score = envelope.score,
		success = envelope.success,
		rewardApplied = envelope.rewardApplied,
		penaltyApplied = envelope.penaltyApplied,
		netDelta = envelope.netDelta,
		timestamp = os.time(),
	}

	stats.totalPlayed += 1
	if envelope.success then
		stats.totalSuccess += 1
	end
	stats.lastResult = {
		miniGameId = envelope.miniGameId,
		score = envelope.score,
		success = envelope.success,
		rewardApplied = envelope.rewardApplied,
		penaltyApplied = envelope.penaltyApplied,
		netDelta = envelope.netDelta,
		timestamp = os.time(),
	}
end

function EconomyManager:_normalizeMiniGameEnvelope(envelope, baseReward, failurePenalty)
	if type(envelope) ~= "table" then
		return nil
	end

	local miniGameId = envelope.miniGameId
	if type(miniGameId) ~= "string" or miniGameId == "" then
		return nil
	end

	local score = math.clamp(math.floor(envelope.score or 0), 0, 100)
	local success = envelope.success == true

	local rewardApplied = envelope.rewardApplied
	local penaltyApplied = envelope.penaltyApplied
	if type(rewardApplied) ~= "number" or rewardApplied < 0 then
		local normalizedScore = score / 100
		rewardApplied = math.floor((baseReward or 0) * (0.5 + normalizedScore))
	end
	if type(penaltyApplied) ~= "number" or penaltyApplied < 0 then
		local normalizedScore = score / 100
		local contextualMultiplier = self:_getFailurePenaltyMultiplier(miniGameId)
		penaltyApplied = math.floor((failurePenalty or 0) * (1.0 - normalizedScore * 0.5) * contextualMultiplier)
	end

	if success then
		penaltyApplied = 0
	else
		rewardApplied = 0
	end

	return {
		miniGameId = miniGameId,
		score = score,
		success = success,
		rewardApplied = math.max(0, math.floor(rewardApplied)),
		penaltyApplied = math.max(0, math.floor(penaltyApplied)),
	}
end

function EconomyManager:ApplyMiniGameResult(player, miniGameId, score, success, baseReward, failurePenalty)
	return self:ApplyMiniGameResultEnvelope(player, {
		miniGameId = miniGameId,
		score = score,
		success = success,
	}, baseReward, failurePenalty)
end

function EconomyManager:ApplyMiniGameResultEnvelope(player, envelope, baseReward, failurePenalty)
	local data = self:GetData(player)
	if not data then
		return nil
	end

	local normalizedEnvelope = self:_normalizeMiniGameEnvelope(envelope, baseReward, failurePenalty)
	if not normalizedEnvelope then
		warn("EconomyManager: envelope mini-game invalid, result diabaikan")
		return nil
	end

	local rewardApplied = normalizedEnvelope.rewardApplied
	local penaltyApplied = normalizedEnvelope.penaltyApplied

	if normalizedEnvelope.success then
		self:AddCash(player, rewardApplied, ("MiniGameReward:%s"):format(normalizedEnvelope.miniGameId))
	else
		self:TrySpendCash(player, penaltyApplied, ("MiniGamePenalty:%s"):format(normalizedEnvelope.miniGameId))
	end

	data.totalMiniGamesPlayed += 1
	if normalizedEnvelope.success then
		data.totalMiniGameSuccess += 1
	end

	local impact = {
		miniGameId = normalizedEnvelope.miniGameId,
		score = normalizedEnvelope.score,
		success = normalizedEnvelope.success,
		rewardApplied = rewardApplied,
		penaltyApplied = penaltyApplied,
		netDelta = rewardApplied - penaltyApplied,
		balanceAfter = data.balance,
	}

	self:_updateMiniGameStats(data, impact)
	return impact
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

function EconomyManager:GetMiniGameStats(player)
	local data = self:GetData(player)
	if not data then
		return nil
	end
	self:_ensureMiniGameStats(data)
	return cloneTableDeep(data.miniGameStats)
end

function EconomyManager:SetMiniGameStats(player, statsSnapshot)
	local data = self:GetData(player)
	if not data or type(statsSnapshot) ~= "table" then
		return false
	end

	local snapshot = cloneTableDeep(statsSnapshot)
	local normalized = createDefaultMiniGameStats()
	normalized.totalPlayed = math.max(0, math.floor(snapshot.totalPlayed or 0))
	normalized.totalSuccess = math.max(0, math.floor(snapshot.totalSuccess or 0))
	if type(snapshot.byId) == "table" then
		normalized.byId = snapshot.byId
	end
	if type(snapshot.lastResult) == "table" then
		normalized.lastResult = snapshot.lastResult
	end

	data.miniGameStats = normalized
	data.totalMiniGamesPlayed = normalized.totalPlayed
	data.totalMiniGameSuccess = normalized.totalSuccess
	return true
end

function EconomyManager:GetContinueUsageCount(player)
	local data = self:GetData(player)
	if not data then
		return 0
	end
	return data.continueUsedCount or 0
end

function EconomyManager:IncrementContinueUsageCount(player)
	local data = self:GetData(player)
	if not data then
		return 0
	end
	data.continueUsedCount = (data.continueUsedCount or 0) + 1
	return data.continueUsedCount
end

return EconomyManager
