--[[
NormalBehaviors
- Menangani behavior baseline untuk NPC kelas normal.
- Setiap route mengubah attribute state agar sistem lain bisa membaca intent NPC.
]]

local NormalBehaviors = {}

local handlers = {
	browse_computers = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "BrowsingPC")
		npcModel:SetAttribute("TargetRole", "ComputerSeat")
		npcModel:SetAttribute("MoveSpeed", npcData.behavior.moveSpeed or 12)
		if context.playEmote then
			context.playEmote(0.35)
		end
	end,
	request_pc_and_snack = function(npcModel, npcData, context)
		npcModel:SetAttribute("BehaviorState", "RequestingPCAndSnack")
		npcModel:SetAttribute("TargetRole", "Cashier")
		npcModel:SetAttribute("NeedSnackChance", npcData.behavior.snackChance or 0.25)
		if context.playEmote then
			context.playEmote(0.5)
		end
	end,
	drop_package_then_leave = function(npcModel, npcData)
		npcModel:SetAttribute("BehaviorState", "DropPackage")
		npcModel:SetAttribute("LeaveAfterSeconds", npcData.behavior.staySeconds or 10)
		npcModel:SetAttribute("TargetRole", "FrontDoor")
	end,
}

function NormalBehaviors.Execute(npcModel, npcData, context)
	local behaviorType = npcData.behavior and npcData.behavior.type
	local handler = handlers[behaviorType]
	if not handler then
		warn(("NormalBehaviors: unknown behavior type '%s'"):format(tostring(behaviorType)))
		return false, "unknown_behavior_type"
	end

	local ok, err = pcall(function()
		handler(npcModel, npcData, context or {})
	end)
	if not ok then
		warn(("NormalBehaviors: failed to run '%s': %s"):format(behaviorType, tostring(err)))
		return false, err
	end

	return true
end

return NormalBehaviors
