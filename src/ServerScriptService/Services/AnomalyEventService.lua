--[[
AnomalyEventService
- Menjadwalkan dan memicu event anomali.
- Dapat mengubah SpawnProfile ke mode anomali sementara.
]]

local AnomalyEventService = {}
AnomalyEventService.__index = AnomalyEventService

function AnomalyEventService.new(npcSpawner, miniGameService)
	local self = setmetatable({}, AnomalyEventService)
	self._spawner = npcSpawner
	self._miniGameService = miniGameService
	self._isEventActive = false
	return self
end

function AnomalyEventService:TriggerAnomalyEvent(player, spawnCFrame)
	if self._isEventActive then
		return nil
	end

	self._isEventActive = true
	local npcModel, npcData = self._spawner:SpawnNPC("EventAnomaly", spawnCFrame)
	local miniGameResult = self._miniGameService:RunMiniGame(player, "AnomalyResponse")

	-- TODO: Broadcast warning/event feed ke client via remotes.

	self._isEventActive = false
	return {
		npcId = npcData and npcData.id or nil,
		miniGameResult = miniGameResult,
	}
end

function AnomalyEventService:IsEventActive()
	return self._isEventActive
end

return AnomalyEventService
