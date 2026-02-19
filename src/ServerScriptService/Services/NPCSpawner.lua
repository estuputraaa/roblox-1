--[[
NPCSpawner
- Mengelola spawn NPC berbasis weighted random.
- Memisahkan pemilihan class dan pemilihan NPC spesifik untuk balancing yang fleksibel.
- Menambahkan policy runtime (cooldown/caps/throttle) agar heartbeat tidak memicu over-spawn.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ConfigFolder = Shared:WaitForChild("Config")
local NPCBehaviorConfig = require(ConfigFolder:WaitForChild("NPCBehaviorConfig"))
local NPCConfigValidator = require(script.Parent:WaitForChild("NPCConfigValidator"))

local NPCSpawner = {}
NPCSpawner.__index = NPCSpawner

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

function NPCSpawner.new(options)
	local self = setmetatable({}, NPCSpawner)
	local spawnOptions = options or {}

	self._rng = Random.new()
	self._activeNPCs = {}
	self._classActiveCounts = {}
	self._npcPoolsByClass = {}
	self._lastSpawnByClass = {}
	self._lastSpawnAttemptAt = 0

	self._defaultProfile = "Day"
	self._maxActiveNPCs = 25
	self._maxActiveByClass = {}
	self._spawnThrottleSeconds = 1.25
	self._classCooldownSeconds = {}
	self._profileClassCooldownSeconds = {}

	self._behaviorRunner = spawnOptions.behaviorRunner
	self._validationWarnings = {}

	local validationResult = NPCConfigValidator.Validate(NPCBehaviorConfig)
	self._isConfigValid = validationResult.isValid
	self._validationWarnings = validationResult.warnings or {}
	if self._isConfigValid then
		self._config = validationResult.normalizedConfig
		self._defaultProfile = self._config.DefaultProfile or self._defaultProfile

		local spawnPolicy = self._config.SpawnPolicy or {}
		self._maxActiveNPCs = spawnPolicy.maxActiveGlobal or self._maxActiveNPCs
		self._maxActiveByClass = spawnPolicy.maxActiveByClass or {}
		self._spawnThrottleSeconds = spawnPolicy.spawnThrottleSeconds or self._spawnThrottleSeconds
		self._classCooldownSeconds = spawnPolicy.classCooldownSeconds or {}
		self._profileClassCooldownSeconds = spawnPolicy.profileClassCooldownSeconds or {}

		for _, npcData in ipairs(self._config.NPCs) do
			if not self._npcPoolsByClass[npcData.class] then
				self._npcPoolsByClass[npcData.class] = {}
			end
			table.insert(self._npcPoolsByClass[npcData.class], npcData)
		end
	else
		self._config = nil
	end

	for _, warningText in ipairs(self._validationWarnings) do
		warn(("NPCSpawner config warning: %s"):format(warningText))
	end

	return self
end

function NPCSpawner:SetBehaviorRunner(behaviorRunner)
	self._behaviorRunner = behaviorRunner
end

function NPCSpawner:_pruneInactiveNPCs()
	for index = #self._activeNPCs, 1, -1 do
		local entry = self._activeNPCs[index]
		local npcModel = entry.model
		if not npcModel or npcModel.Parent == nil then
			table.remove(self._activeNPCs, index)
			if entry.className then
				self._classActiveCounts[entry.className] = math.max(0, (self._classActiveCounts[entry.className] or 1) - 1)
			end
		end
	end
end

function NPCSpawner:_untrackNPCModel(npcModel)
	local removedClass = nil
	for index, entry in ipairs(self._activeNPCs) do
		if entry.model == npcModel then
			removedClass = entry.className
			table.remove(self._activeNPCs, index)
			break
		end
	end

	if removedClass then
		self._classActiveCounts[removedClass] = math.max(0, (self._classActiveCounts[removedClass] or 1) - 1)
	end
end

function NPCSpawner:_trackSpawnedNPC(npcModel, npcData)
	local entry = {
		model = npcModel,
		className = npcData.class,
	}
	table.insert(self._activeNPCs, entry)
	self._classActiveCounts[npcData.class] = (self._classActiveCounts[npcData.class] or 0) + 1

	npcModel.Destroying:Connect(function()
		self:_untrackNPCModel(npcModel)
	end)
end

function NPCSpawner:_getClassCooldownSeconds(profileName, className)
	local profileCooldowns = self._profileClassCooldownSeconds[profileName]
	if type(profileCooldowns) == "table" and type(profileCooldowns[className]) == "number" then
		return math.max(0, profileCooldowns[className])
	end

	if type(self._classCooldownSeconds[className]) == "number" then
		return math.max(0, self._classCooldownSeconds[className])
	end

	return 0
end

function NPCSpawner:_isClassWithinCap(className)
	local classCap = self._maxActiveByClass[className]
	if type(classCap) ~= "number" then
		return true
	end
	return (self._classActiveCounts[className] or 0) < classCap
end

function NPCSpawner:_isClassOffCooldown(className, profileName, nowSeconds)
	local cooldownSeconds = self:_getClassCooldownSeconds(profileName, className)
	local lastSpawnAt = self._lastSpawnByClass[className] or -math.huge
	return (nowSeconds - lastSpawnAt) >= cooldownSeconds
end

function NPCSpawner:_getEligibleClassWeights(profileName, nowSeconds)
	local eligible = {}
	local classWeights = self._config.SpawnProfiles[profileName]
	if not classWeights then
		return eligible
	end

	for className, weight in pairs(classWeights) do
		local hasPool = self._npcPoolsByClass[className] and #self._npcPoolsByClass[className] > 0
		if weight > 0 and hasPool and self:_isClassWithinCap(className) and self:_isClassOffCooldown(className, profileName, nowSeconds) then
			eligible[className] = weight
		end
	end

	return eligible
end

function NPCSpawner:_canPassGlobalGuards(nowSeconds)
	self:_pruneInactiveNPCs()

	if #self._activeNPCs >= self._maxActiveNPCs then
		return false
	end

	if (nowSeconds - self._lastSpawnAttemptAt) < self._spawnThrottleSeconds then
		return false
	end

	return true
end

function NPCSpawner:_getNPCsByClass(className)
	if not self._config then
		return {}
	end
	return self._npcPoolsByClass[className] or {}
end

function NPCSpawner:ResolveSpawnProfile(profileName, gameDirector)
	if not self._isConfigValid or not self._config then
		return nil
	end

	if type(profileName) == "string" and self._config.SpawnProfiles[profileName] then
		return profileName
	end

	if gameDirector and gameDirector.GetSpawnProfile then
		local stateProfile = gameDirector:GetSpawnProfile()
		if type(stateProfile) == "string" and self._config.SpawnProfiles[stateProfile] then
			return stateProfile
		end
	end

	return self._defaultProfile
end

function NPCSpawner:SelectNPC(profileName, nowSeconds, gameDirector)
	if not self._isConfigValid or not self._config then
		return nil
	end

	local resolvedProfile = self:ResolveSpawnProfile(profileName, gameDirector)
	if not resolvedProfile then
		return nil
	end

	local eligibleClassWeights = self:_getEligibleClassWeights(resolvedProfile, nowSeconds or os.clock())
	local selectedClass = weightedPickFromMap(self._rng, eligibleClassWeights)
	if not selectedClass then
		return nil
	end

	local pool = self:_getNPCsByClass(selectedClass)
	local npcData = weightedPickFromArray(self._rng, pool)
	if not npcData then
		return nil
	end

	return npcData, selectedClass, resolvedProfile
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

function NPCSpawner:CanAttemptSpawn(profileName, gameDirector)
	if not self._isConfigValid then
		return false, nil
	end

	local nowSeconds = os.clock()
	if not self:_canPassGlobalGuards(nowSeconds) then
		return false, nil
	end

	local resolvedProfile = self:ResolveSpawnProfile(profileName, gameDirector)
	if not resolvedProfile then
		return false, nil
	end

	local eligibleClassWeights = self:_getEligibleClassWeights(resolvedProfile, nowSeconds)
	local hasEligibleClass = next(eligibleClassWeights) ~= nil
	return hasEligibleClass, resolvedProfile
end

function NPCSpawner:SpawnNPC(profileNameOrOptions, spawnCFrame)
	if not self._isConfigValid then
		warn("NPCSpawner: spawn dibatalkan karena config invalid")
		return nil
	end

	local options = nil
	if type(profileNameOrOptions) == "table" then
		options = profileNameOrOptions
	else
		options = {
			profileName = profileNameOrOptions,
			spawnCFrame = spawnCFrame,
		}
	end

	local gameDirector = options.gameDirector
	local resolvedSpawnCFrame = options.spawnCFrame
	local nowSeconds = os.clock()
	if not self:_canPassGlobalGuards(nowSeconds) then
		return nil
	end

	local npcData, selectedClass, resolvedProfile = self:SelectNPC(options.profileName, nowSeconds, gameDirector)
	self._lastSpawnAttemptAt = nowSeconds
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
	npcModel:SetAttribute("SpawnProfile", resolvedProfile)

	if npcModel.PrimaryPart and resolvedSpawnCFrame then
		npcModel:PivotTo(resolvedSpawnCFrame)
	end

	npcModel.Parent = workspace:FindFirstChild("NPCs") or workspace
	self._lastSpawnByClass[selectedClass] = nowSeconds
	self:_applyBehavior(npcModel, npcData)
	self:_trackSpawnedNPC(npcModel, npcData)

	return npcModel, npcData
end

function NPCSpawner:DespawnNPC(npcModel)
	self:_untrackNPCModel(npcModel)

	if npcModel and npcModel.Parent then
		npcModel:Destroy()
	end
end

function NPCSpawner:GetActiveCount()
	self:_pruneInactiveNPCs()
	return #self._activeNPCs
end

function NPCSpawner:GetActiveCountByClass(className)
	self:_pruneInactiveNPCs()
	return self._classActiveCounts[className] or 0
end

function NPCSpawner:GetValidationWarnings()
	return self._validationWarnings
end

return NPCSpawner
