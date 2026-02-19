--[[
PersistenceService
- Placeholder persistence untuk Phase 1.
- Saat ini menyimpan snapshot di memori runtime dan menyiapkan kontrak menuju DataStore.
]]

local PersistenceService = {}
PersistenceService.__index = PersistenceService

function PersistenceService.new()
	local self = setmetatable({}, PersistenceService)
	self._sessionCache = {}
	return self
end

function PersistenceService:LoadPlayerState(player)
	if not player then
		return nil
	end
	return self._sessionCache[player.UserId]
end

function PersistenceService:SavePlayerState(player, snapshot)
	if not player or not snapshot then
		return false
	end

	self._sessionCache[player.UserId] = snapshot
	-- TODO: Persist snapshot ke DataStoreService.
	return true
end

function PersistenceService:SaveDaySnapshot(player, daySnapshot)
	if not player or not daySnapshot then
		return false
	end

	local existing = self._sessionCache[player.UserId] or {}
	existing.lastDaySnapshot = daySnapshot
	existing.day = daySnapshot.day
	existing.phase = daySnapshot.phase

	self._sessionCache[player.UserId] = existing
	-- TODO: Persist day snapshot ke DataStoreService.
	return true
end

return PersistenceService
