--[[
EndingService
- Mengevaluasi kondisi ending utama dan easter egg endings.
- Menyediakan bridge flag tracking dan notifikasi ending secara fail-safe.
]]

local EndingService = {}
EndingService.__index = EndingService

local ENDING_DEFINITIONS = {
	{
		code = "EASTER_TUNGTUNG",
		title = "Sahur Bonk Ending",
		description = "Kamu kena bonk TungTung Sahur dan masuk ending rahasia.",
		type = "easter",
		priority = 300,
		condition = function(service, context)
			return service:GetFlag(context.player, "wasHitByTungTung") == true
		end,
	},
	{
		code = "EASTER_PORTAL",
		title = "Portal Tersembunyi Ending",
		description = "Kamu menemukan portal misterius di tengah kekacauan anomali.",
		type = "easter",
		priority = 250,
		condition = function(service, context)
			return service:GetFlag(context.player, "enteredHiddenPortal") == true
		end,
	},
	{
		code = "MAIN_ENDING",
		title = "Warnet Bertahan 7 Hari",
		description = "Kamu berhasil menjaga warnet sampai hari ke-7.",
		type = "main",
		priority = 100,
		condition = function(_service, context)
			return (context.currentDay or 0) >= 7 and not context.isGameOver
		end,
	},
}

local function cloneShallow(source)
	local copy = {}
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function getPlayerUserId(player)
	if not player then
		return nil
	end
	return player.UserId
end

local function sortDefinitionsByPriority(definitions)
	local ordered = table.clone(definitions)
	table.sort(ordered, function(a, b)
		if a.priority == b.priority then
			return a.code < b.code
		end
		return a.priority > b.priority
	end)
	return ordered
end

function EndingService.new(deps)
	local self = setmetatable({}, EndingService)
	if type(deps) == "table" and deps.economy then
		self._economy = deps.economy
	else
		self._economy = deps
	end

	self._endingRemote = nil
	self._notifiedByPlayer = {}
	self._definitions = sortDefinitionsByPriority(ENDING_DEFINITIONS)
	return self
end

function EndingService:SetRuntimeContext(options)
	options = options or {}
	self._endingRemote = options.endingRemote
end

function EndingService:GetFlag(player, flagName)
	if not self._economy or not self._economy.GetFlag then
		return nil
	end
	return self._economy:GetFlag(player, flagName)
end

function EndingService:RecordFlag(player, flagName, flagValue)
	if not player or type(flagName) ~= "string" or flagName == "" then
		return false
	end
	if not self._economy or not self._economy.SetFlag then
		return false
	end

	self._economy:SetFlag(player, flagName, flagValue)
	return true
end

function EndingService:GetEndingDefinition(endingCode)
	for _, definition in ipairs(self._definitions) do
		if definition.code == endingCode then
			return cloneShallow(definition)
		end
	end
	return nil
end

function EndingService:GetUnlockedEndings(player)
	if not player then
		return {}
	end

	local unlocked = {}
	for _, definition in ipairs(self._definitions) do
		local isUnlocked = self:GetFlag(player, ("endingUnlocked:%s"):format(definition.code)) == true
		if isUnlocked then
			table.insert(unlocked, definition.code)
		end
	end
	return unlocked
end

function EndingService:_notifyEnding(player, endingCode, context)
	local userId = getPlayerUserId(player)
	if not userId then
		return
	end

	if self._notifiedByPlayer[userId] == endingCode then
		return
	end
	self._notifiedByPlayer[userId] = endingCode

	if not self._endingRemote then
		return
	end

	local definition = self:GetEndingDefinition(endingCode)
	if not definition then
		return
	end

	local payload = {
		code = endingCode,
		title = definition.title,
		description = definition.description,
		type = definition.type,
		day = context.currentDay,
		source = context.source or "unknown",
	}

	local ok, err = pcall(function()
		self._endingRemote:FireClient(player, payload)
	end)
	if not ok then
		warn(("EndingService: gagal kirim notifikasi ending '%s': %s"):format(endingCode, tostring(err)))
	end
end

function EndingService:_markEndingUnlocked(player, endingCode)
	self:RecordFlag(player, ("endingUnlocked:%s"):format(endingCode), true)
	self:RecordFlag(player, "lastEndingCode", endingCode)
end

function EndingService:ResolveEnding(player, currentDay, isGameOver, options)
	if not player then
		return nil
	end

	local context = {
		player = player,
		currentDay = currentDay,
		isGameOver = isGameOver == true,
		source = options and options.source or "end_of_day",
	}

	for _, definition in ipairs(self._definitions) do
		local ok, matched = pcall(function()
			return definition.condition(self, context)
		end)
		if ok and matched then
			self:_markEndingUnlocked(player, definition.code)
			self:_notifyEnding(player, definition.code, context)
			return definition.code
		end
		if not ok then
			warn(("EndingService: condition error pada '%s'"):format(definition.code))
		end
	end

	return nil
end

return EndingService
