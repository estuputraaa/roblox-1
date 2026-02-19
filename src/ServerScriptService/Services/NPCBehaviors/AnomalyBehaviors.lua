--[[
AnomalyBehaviors
- Menangani behavior khusus NPC anomali.
- Efek dibuat ringan (attribute markers) agar aman untuk skeleton server.
]]

local AnomalyBehaviors = {}

local handlers = {
	hop_and_interrupt_power = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "HopPowerInterference")
		npcModel:SetAttribute("JumpscareChance", npcData.behavior.jumpscareChance or 0.2)
		npcModel:SetAttribute("AnomalySeverity", 2)
		if context.playEmote then
			context.playEmote(0.6)
		end
	end,
	haunt_and_confuse_customers = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "Haunting")
		npcModel:SetAttribute("TerrorRadius", npcData.behavior.terrorRadius or 16)
		npcModel:SetAttribute("AnomalySeverity", 3)
		if context.playEmote then
			context.playEmote(0.45)
		end
	end,
	crawl_and_sabotage_pc = function(npcModel, npcData)
		npcModel:SetAttribute("BehaviorState", "SabotagePC")
		npcModel:SetAttribute("SabotageChance", npcData.behavior.sabotageChance or 0.25)
		npcModel:SetAttribute("AnomalySeverity", 3)
	end,
	roar_and_force_minigame = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "RoarChallenge")
		npcModel:SetAttribute("PushForce", npcData.behavior.pushForce or 30)
		npcModel:SetAttribute("AnomalySeverity", 4)
		if context.playEmote then
			context.playEmote(0.8)
		end
	end,
}

function AnomalyBehaviors.Execute(npcModel, npcData, context)
	local behaviorType = npcData.behavior and npcData.behavior.type
	local handler = handlers[behaviorType]
	if not handler then
		warn(("AnomalyBehaviors: unknown behavior type '%s'"):format(tostring(behaviorType)))
		return false, "unknown_behavior_type"
	end

	local ok, err = pcall(function()
		handler(npcModel, npcData, context or {})
	end)
	if not ok then
		warn(("AnomalyBehaviors: failed to run '%s': %s"):format(behaviorType, tostring(err)))
		return false, err
	end

	return true
end

return AnomalyBehaviors
