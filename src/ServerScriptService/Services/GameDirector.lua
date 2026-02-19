--[[
GameDirector
- Orkestrator progression hari dengan state machine deterministic.
- Mengunci kontrak pacing Phase 1: 10 menit/hari (5 pagi + 5 malam).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local DayCycleConfig = require(ConfigFolder:WaitForChild("DayCycleConfig"))

local GameDirector = {}
GameDirector.__index = GameDirector

function GameDirector.new(services)
	local self = setmetatable({}, GameDirector)

	self._services = services
	self._activePlayer = nil
	self._currentDay = 1
	self._currentPhase = "Morning"
	self._currentDifficulty = DayCycleConfig.GetDifficultyForDay(1, os.time())
	self._runSeed = os.time()

	self._state = "Idle"
	self._isGameOver = false
	self._lastFailReason = nil
	self._lastEndingCode = nil

	self._phaseElapsedSeconds = 0
	self._phaseTimeRemainingSeconds = DayCycleConfig.MorningDurationSeconds
	self._phaseEventBudget = DayCycleConfig.EventBudgetByPhase.Morning or 0
	self._consumedEventsInPhase = 0

	if self._services.economy and self._services.economy.SetBalanceDepletedHandler then
		self._services.economy:SetBalanceDepletedHandler(function(player, reason)
			self:TriggerFail(player, reason)
		end)
	end

	if self._services.monetization and self._services.monetization.SetContinueHandlers then
		self._services.monetization:SetContinueHandlers(
			function(player)
				self:ApplyContinueRecovery(player)
			end,
			function(player)
				self:HandleContinueDeclined(player)
			end
		)
	end

	return self
end

function GameDirector:_enterPhase(phaseName)
	self._currentPhase = phaseName
	self._phaseElapsedSeconds = 0
	self._phaseTimeRemainingSeconds = DayCycleConfig.GetPhaseDurationSeconds(phaseName)
	self._phaseEventBudget = DayCycleConfig.EventBudgetByPhase[phaseName] or 0
	self._consumedEventsInPhase = 0
end

function GameDirector:StartRun(player)
	if player then
		self._activePlayer = player
	end
	if not self._activePlayer then
		return false
	end
	if self._state ~= "Idle" then
		return true
	end

	self._state = "Running"
	self._isGameOver = false
	self._currentDay = 1
	self._currentDifficulty = DayCycleConfig.GetDifficultyForDay(self._currentDay, self._runSeed)
	self:StartDay(self._activePlayer)

	return true
end

function GameDirector:StartDay(player)
	if self._isGameOver then
		return false
	end

	if player then
		self._activePlayer = player
	end
	if not self._activePlayer then
		return false
	end

	self._state = "DayInProgress"
	self._currentDifficulty = DayCycleConfig.GetDifficultyForDay(self._currentDay, self._runSeed)
	if self._services.economy and self._services.economy.ApplyOperationalCost then
		self._services.economy:ApplyOperationalCost(self._activePlayer, self._currentDay)
	end
	self:_enterPhase("Morning")

	return true
end

function GameDirector:_advancePhase()
	if self._currentPhase == "Morning" then
		self:_enterPhase("Night")
		return
	end

	if self._currentPhase == "Night" then
		self:EndDay(self._activePlayer)
	end
end

function GameDirector:Tick(deltaTime)
	if self._state ~= "DayInProgress" or self._isGameOver then
		return
	end
	if deltaTime <= 0 then
		return
	end

	self._phaseElapsedSeconds += deltaTime
	self._phaseTimeRemainingSeconds = math.max(0, self._phaseTimeRemainingSeconds - deltaTime)

	if self._phaseTimeRemainingSeconds <= 0 then
		self:_advancePhase()
	end
end

function GameDirector:EndDay(player)
	if self._isGameOver then
		return nil
	end

	local targetPlayer = player or self._activePlayer
	if not targetPlayer then
		return nil
	end

	self._state = "EndDay"
	if self._services.economy and self._services.economy.AwardDailySurvival then
		self._services.economy:AwardDailySurvival(targetPlayer, self._currentDay)
	end

	if self._services.persistence and self._services.persistence.SaveDaySnapshot then
		self._services.persistence:SaveDaySnapshot(targetPlayer, {
			day = self._currentDay,
			phase = self._currentPhase,
			difficulty = self._currentDifficulty,
		})
	end

	local endingCode = nil
	if self._services.ending and self._services.ending.ResolveEnding then
		endingCode = self._services.ending:ResolveEnding(targetPlayer, self._currentDay, self._isGameOver)
	end
	if endingCode then
		self._lastEndingCode = endingCode
		self._state = "Completed"
		return endingCode
	end

	if self._currentDay >= DayCycleConfig.MaxDays then
		self._lastEndingCode = "MAIN_ENDING"
		self._state = "Completed"
		return self._lastEndingCode
	end

	self._currentDay += 1
	self:StartDay(targetPlayer)
	return nil
end

function GameDirector:ConsumeEventBudget(amount)
	local consumeAmount = math.max(1, math.floor(amount or 1))
	if self._consumedEventsInPhase + consumeAmount > self._phaseEventBudget then
		return false
	end
	self._consumedEventsInPhase += consumeAmount
	return true
end

function GameDirector:TriggerFail(player, reason)
	if self._isGameOver then
		return false
	end

	self._isGameOver = true
	self._state = "GameOver"
	self._lastFailReason = reason or "cash_depleted"

	local targetPlayer = player or self._activePlayer
	if self._services.monetization and self._services.monetization.PromptContinuePurchase then
		self._services.monetization:PromptContinuePurchase(targetPlayer)
	end

	return true
end

function GameDirector:ApplyContinueRecovery(player)
	if not self._isGameOver then
		return false
	end

	local targetPlayer = player or self._activePlayer
	if not targetPlayer then
		return false
	end

	if self._services.economy and self._services.economy.RecoverToMinimumBalance then
		self._services.economy:RecoverToMinimumBalance(targetPlayer, 100, "ContinueRecovery")
	end
	self._isGameOver = false
	self._state = "DayInProgress"
	return true
end

function GameDirector:HandleContinueDeclined(player)
	local targetPlayer = player or self._activePlayer
	if targetPlayer and targetPlayer.Parent then
		pcall(function()
			targetPlayer:LoadCharacter()
		end)
	end
	self._state = "GameOver"
	return true
end

function GameDirector:GetCurrentDay()
	return self._currentDay
end

function GameDirector:GetCurrentPhase()
	return self._currentPhase
end

function GameDirector:GetPhaseTimeRemaining()
	return self._phaseTimeRemainingSeconds
end

function GameDirector:GetEventBudgetForPhase()
	return math.max(0, self._phaseEventBudget - self._consumedEventsInPhase)
end

function GameDirector:GetState()
	return self._state
end

function GameDirector:GetDifficultyForCurrentDay()
	return self._currentDifficulty
end

function GameDirector:GetLastFailReason()
	return self._lastFailReason
end

function GameDirector:GetLastEndingCode()
	return self._lastEndingCode
end

function GameDirector:IsGameOver()
	return self._isGameOver
end

return GameDirector
