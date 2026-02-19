--[[
NPCSpawner
- Mengelola spawn NPC berbasis weighted random.
- Memisahkan pemilihan class dan pemilihan NPC spesifik untuk balancing yang fleksibel.
- Ini skeleton; integrasi model spawn points dan pathfinding disiapkan sebagai TODO.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local NPCBehaviorConfig = require(ConfigFolder:WaitForChild("NPCBehaviorConfig"))
local NPCConfigValidator = require(script.Parent:WaitForChild("NPCConfigValidator"))

local NPCSpawner = {}
NPCSpawner.__index = NPCSpawner

function NPCSpawner.new(options)
	local self = setmetatable({}, NPCSpawner)
	local spawnOptions = options or {}

	self._rng = Random.new()
	self._activeNPCs = {}
	self._defaultProfile = "Day"
	self._maxActiveNPCs = 25
	self._behaviorRunner = spawnOptions.behaviorRunner
	self._validationWarnings = {}

	local validationResult = NPCConfigValidator.Validate(NPCBehaviorConfig)
	self._isConfigValid = validationResult.isValid
	self._validationWarnings = validationResult.warnings or {}
	if self._isConfigValid then
		self._config = validationResult.normalizedConfig
		self._defaultProfile = self._config.DefaultProfile or self._defaultProfile
		if type(self._config.SpawnPolicy) == "table" and type(self._config.SpawnPolicy.maxActiveGlobal) == "number" then
			self._maxActiveNPCs = self._config.SpawnPolicy.maxActiveGlobal
		end
	else
		self._config = nil
	end

	for _, warningText in ipairs(self._validationWarnings) do
		warn(("NPCSpawner config warning: %s"):format(warningText))
	end

	return self
end

-- Weighted pick generic untuk table key->weight.
local function weightedPickFromMap(rng, weightedMap)
	local total = 0
	for _, weight in pairs(weightedMap) do
		total += weight
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber(0, total)
	local cursor = 0
	for key, weight in pairs(weightedMap) do
		cursor += weight
		if roll <= cursor then
			return key
		end
	end

	return nil
end

-- Weighted pick generic untuk array item dengan field spawnWeight.
local function weightedPickFromArray(rng, items)
	local total = 0
	for _, item in ipairs(items) do
		total += item.spawnWeight or 0
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber(0, total)
	local cursor = 0
	for _, item in ipairs(items) do
		cursor += item.spawnWeight or 0
		if roll <= cursor then
			return item
		end
	end

	return nil
end

function NPCSpawner:_getNPCsByClass(className)
	local pool = {}
	if not self._config then
		return pool
	end

	for _, npcData in ipairs(self._config.NPCs) do
		if npcData.class == className then
			table.insert(pool, npcData)
		end
	end
	return pool
end

function NPCSpawner:SelectNPC(profileName)
	if not self._isConfigValid or not self._config then
		return nil
	end

	local selectedProfile = profileName or self._defaultProfile
	local classWeights = self._config.SpawnProfiles[selectedProfile]
	if not classWeights then
		warn(("NPCSpawner: SpawnProfile '%s' tidak ditemukan"):format(tostring(selectedProfile)))
		return nil
	end

	local selectedClass = weightedPickFromMap(self._rng, classWeights)
	if not selectedClass then
		return nil
	end

	local pool = self:_getNPCsByClass(selectedClass)
	return weightedPickFromArray(self._rng, pool)
end

function NPCSpawner:_applyBehavior(npcModel, npcData)
	if self._behaviorRunner and self._behaviorRunner.RunBehavior then
		local ok, err = pcall(function()
			self._behaviorRunner:RunBehavior(npcModel, npcData)
		end)
		if not ok then
			warn(("NPCSpawner: behavior runner error untuk '%s': %s"):format(npcData.id, tostring(err)))
		end
	end

	-- Fallback marker jika runner belum tersedia.
	npcModel:SetAttribute("BehaviorType", npcData.behavior.type)
end

function NPCSpawner:SpawnNPC(profileName, spawnCFrame)
	if not self._isConfigValid then
		warn("NPCSpawner: spawn dibatalkan karena config invalid")
		return nil
	end

	if #self._activeNPCs >= self._maxActiveNPCs then
		return nil
	end

	local npcData = self:SelectNPC(profileName)
	if not npcData then
		return nil
	end

	local npcTemplateFolder = ServerStorage:FindFirstChild("NPCTemplates")
	if not npcTemplateFolder then
		warn("NPCSpawner: Folder ServerStorage/NPCTemplates belum ada")
		return nil
	end

	local template = npcTemplateFolder:FindFirstChild(npcData.modelName)
	if not template then
		warn(("NPCSpawner: Template model '%s' tidak ditemukan"):format(npcData.modelName))
		return nil
	end

	local npcModel = template:Clone()
	npcModel.Name = npcData.displayName
	npcModel:SetAttribute("NPCId", npcData.id)
	npcModel:SetAttribute("NPCClass", npcData.class)
	npcModel:SetAttribute("SpawnProfile", profileName or self._defaultProfile)

	if npcModel.PrimaryPart and spawnCFrame then
		npcModel:PivotTo(spawnCFrame)
	end

	npcModel.Parent = workspace:FindFirstChild("NPCs") or workspace
	self:_applyBehavior(npcModel, npcData)
	table.insert(self._activeNPCs, npcModel)

	return npcModel, npcData
end

function NPCSpawner:DespawnNPC(npcModel)
	for index, model in ipairs(self._activeNPCs) do
		if model == npcModel then
			table.remove(self._activeNPCs, index)
			break
		end
	end
	if npcModel and npcModel.Parent then
		npcModel:Destroy()
	end
end

function NPCSpawner:GetActiveCount()
	return #self._activeNPCs
end

function NPCSpawner:GetValidationWarnings()
	return self._validationWarnings
end

return NPCSpawner
