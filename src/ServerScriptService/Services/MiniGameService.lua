--[[
MiniGameService
- Registry mini-game dan contract hasil eksekusi.
- Menjaga satu jalur server-authoritative untuk simulasi hasil mini-game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local MiniGameConfig = require(ConfigFolder:WaitForChild("MiniGameConfig"))

local MiniGameService = {}
MiniGameService.__index = MiniGameService

local DEFAULT_SUCCESS_THRESHOLD = 60

local function cloneShallow(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

function MiniGameService.new(economyManager)
	local self = setmetatable({}, MiniGameService)
	self._economy = economyManager
	self._rng = Random.new()
	self._handlers = {
		CookNoodle = function(service, player, config, context)
			return service:_handleCookNoodle(player, config, context)
		end,
		RepairComputer = function(service, player, config, context)
			return service:_handleRepairComputer(player, config, context)
		end,
		AnomalyResponse = function(service, player, config, context)
			return service:_handleAnomalyResponse(player, config, context)
		end,
	}
	return self
end

function MiniGameService:HasMiniGame(miniGameId)
	return MiniGameConfig[miniGameId] ~= nil and self._handlers[miniGameId] ~= nil
end

function MiniGameService:GetMiniGameConfig(miniGameId)
	local config = MiniGameConfig[miniGameId]
	if not config then
		return nil
	end
	return cloneShallow(config)
end

function MiniGameService:ListMiniGames()
	local ids = {}
	for miniGameId, _ in pairs(self._handlers) do
		table.insert(ids, miniGameId)
	end
	table.sort(ids)
	return ids
end

function MiniGameService:_computeImpact(miniGameId, score, success, config)
	local normalizedScore = math.clamp(score or 0, 0, 100) / 100
	if success then
		local reward = math.floor((config.baseReward or 0) * (0.5 + normalizedScore))
		return reward, 0
	end

	local contextualMultiplier = 1.0
	if miniGameId == "AnomalyResponse" then
		contextualMultiplier = 1.35
	end

	local penalty = math.floor((config.failurePenalty or 0) * (1.0 - normalizedScore * 0.5) * contextualMultiplier)
	return 0, penalty
end

function MiniGameService:_normalizeResult(miniGameId, config, rawResult)
	local score = math.clamp(math.floor(rawResult.score or 0), 0, config.maxScore or 100)
	local threshold = config.successThreshold or DEFAULT_SUCCESS_THRESHOLD
	local success = rawResult.success
	if success == nil then
		success = score >= threshold
	end

	local rewardApplied, penaltyApplied = self:_computeImpact(miniGameId, score, success, config)
	local tags = {}
	if type(rawResult.tags) == "table" then
		for _, tag in ipairs(rawResult.tags) do
			table.insert(tags, tag)
		end
	end

	if success then
		table.insert(tags, "success")
	else
		table.insert(tags, "failed")
	end

	return {
		miniGameId = miniGameId,
		score = score,
		success = success,
		rewardApplied = rewardApplied,
		penaltyApplied = penaltyApplied,
		durationSeconds = config.durationSeconds or 0,
		tags = tags,
	}
end

function MiniGameService:_rollInRange(config)
	local minScore = math.floor(config.scoreRangeMin or 0)
	local maxScore = math.floor(config.scoreRangeMax or config.maxScore or 100)
	if maxScore < minScore then
		maxScore = minScore
	end
	return self._rng:NextInteger(minScore, maxScore)
end

function MiniGameService:_handleCookNoodle(_player, config, _context)
	local score = self:_rollInRange(config)
	local tags = { "cooking", "quick_task" }
	if score >= (config.successThreshold or DEFAULT_SUCCESS_THRESHOLD) then
		table.insert(tags, "noodle_served")
	else
		table.insert(tags, "overcooked")
	end
	return {
		score = score,
		tags = tags,
	}
end

function MiniGameService:_handleRepairComputer(_player, config, _context)
	local score = self:_rollInRange(config)
	local tags = { "repair", "technical" }
	if score >= (config.successThreshold or DEFAULT_SUCCESS_THRESHOLD) then
		table.insert(tags, "pc_restored")
	else
		table.insert(tags, "pc_still_broken")
	end
	return {
		score = score,
		tags = tags,
	}
end

function MiniGameService:_handleAnomalyResponse(_player, config, context)
	local score = self:_rollInRange(config)
	local tags = { "anomaly", "high_pressure" }
	local threatLevel = (context and context.threatLevel) or "normal"
	table.insert(tags, ("threat_%s"):format(tostring(threatLevel)))
	if score >= (config.successThreshold or DEFAULT_SUCCESS_THRESHOLD) then
		table.insert(tags, "anomalyHandled")
	else
		table.insert(tags, "anomalyEscalated")
	end
	return {
		score = score,
		tags = tags,
	}
end

function MiniGameService:RunMiniGame(player, miniGameId, context)
	local config = MiniGameConfig[miniGameId]
	local handler = self._handlers[miniGameId]
	if not config or not handler then
		warn(("MiniGameService: miniGameId '%s' tidak dikenal"):format(tostring(miniGameId)))
		return nil
	end

	local rawResult = handler(self, player, config, context or {}) or {}
	local result = self:_normalizeResult(miniGameId, config, rawResult)

	if self._economy and self._economy.ApplyMiniGameResult then
		self._economy:ApplyMiniGameResult(
			player,
			miniGameId,
			result.score,
			result.success,
			config.baseReward,
			config.failurePenalty
		)
	end

	return result
end

return MiniGameService
