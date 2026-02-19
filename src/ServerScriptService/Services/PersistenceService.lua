--[[
PersistenceService
- Placeholder persistence untuk Phase 1.
- Saat ini menyimpan snapshot di memori runtime dan menyiapkan kontrak menuju DataStore.
]]

local PersistenceService = {}
PersistenceService.__index = PersistenceService

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

function PersistenceService.new()
	local self = setmetatable({}, PersistenceService)
	self._sessionCache = {}
	return self
end

function PersistenceService:LoadPlayerState(player)
	if not player then
		return nil
	end
	local snapshot = self._sessionCache[player.UserId]
	if not snapshot then
		return nil
	end
	return cloneTableDeep(snapshot)
end

function PersistenceService:SavePlayerState(player, snapshot)
	if not player or not snapshot then
		return false
	end

	local existing = self._sessionCache[player.UserId] or {}
	local normalizedSnapshot = cloneTableDeep(snapshot)
	if existing.lastDaySnapshot and not normalizedSnapshot.lastDaySnapshot then
		normalizedSnapshot.lastDaySnapshot = cloneTableDeep(existing.lastDaySnapshot)
	end
	normalizedSnapshot.updatedAt = os.time()

	self._sessionCache[player.UserId] = normalizedSnapshot
	-- TODO: Persist snapshot ke DataStoreService.
	return true
end

function PersistenceService:SaveDaySnapshot(player, daySnapshot)
	if not player or not daySnapshot then
		return false
	end

	local existing = cloneTableDeep(self._sessionCache[player.UserId] or {})
	existing.lastDaySnapshot = cloneTableDeep(daySnapshot)
	existing.day = daySnapshot.day
	existing.phase = daySnapshot.phase
	existing.updatedAt = os.time()

	self._sessionCache[player.UserId] = existing
	-- TODO: Persist day snapshot ke DataStoreService.
	return true
end

return PersistenceService
