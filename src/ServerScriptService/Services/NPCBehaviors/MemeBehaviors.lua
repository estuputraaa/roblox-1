--[[
MemeBehaviors
- Menangani behavior NPC meme Indonesia dengan tone komedi.
- Efek utama berupa attribute marker agar bisa dipakai oleh sistem event/ending di phase berikutnya.
]]

local MemeBehaviors = {}

local handlers = {
	bonk_player_for_event = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "BonkPlayer")
		local flagName = npcData.behavior.setsFlag or "wasHitByTungTung"
		npcModel:SetAttribute("SetsFlag", flagName)
		npcModel:SetAttribute("BonkDamage", npcData.behavior.bonkDamage or 0)
		if context.setPlayerFlag then
			context.setPlayerFlag(flagName, true)
		end
		if context.playEmote then
			context.playEmote(0.9)
		end
	end,
	spin_and_drop_bonus = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "SpinBonus")
		npcModel:SetAttribute("BonusChance", npcData.behavior.bonusChance or 0.1)
		if context.playEmote then
			context.playEmote(0.75)
		end
	end,
	command_speech_buff = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "SpeechBuff")
		npcModel:SetAttribute("BonusMorale", npcData.behavior.bonusMorale or 3)
		if context.playEmote then
			context.playEmote(0.7)
		end
	end,
	quick_visit_then_quote = function(npcModel, npcData)
		npcModel:SetAttribute("BehaviorState", "QuickQuote")
		npcModel:SetAttribute("LeaveAfterSeconds", npcData.behavior.staySeconds or 6)
	end,
	inspection_event = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "Inspection")
		npcModel:SetAttribute("InspectionBoost", npcData.behavior.inspectionScoreBoost or 5)
		if context.playEmote then
			context.playEmote(0.65)
		end
	end,
	debate_and_redirect_queue = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "DebateQueue")
		npcModel:SetAttribute("QueueShuffleIntensity", npcData.behavior.queueShuffleIntensity or 0.4)
		if context.playEmote then
			context.playEmote(0.8)
		end
	end,
}

function MemeBehaviors.Execute(npcModel, npcData, context)
	local behaviorType = npcData.behavior and npcData.behavior.type
	local handler = handlers[behaviorType]
	if not handler then
		warn(("MemeBehaviors: unknown behavior type '%s'"):format(tostring(behaviorType)))
		return false, "unknown_behavior_type"
	end

	local ok, err = pcall(function()
		handler(npcModel, npcData, context or {})
	end)
	if not ok then
		warn(("MemeBehaviors: failed to run '%s': %s"):format(behaviorType, tostring(err)))
		return false, err
	end

	return true
end

return MemeBehaviors
