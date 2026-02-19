--[[
NPCConfigValidator
- Memvalidasi dan menormalisasi NPCBehaviorConfig agar runtime spawn aman.
- Entry invalid di-skip dengan warning, bukan menyebabkan crash service.
]]

local NPCConfigValidator = {}

local REQUIRED_PROFILES = {
	Day = true,
	Night = true,
	EventAnomaly = true,
}

local function isPositiveNumber(value)
	return type(value) == "number" and value > 0
end

local function shallowCopyTable(source)
	local result = {}
	for key, value in pairs(source) do
		result[key] = value
	end
	return result
end

local function validateProfile(profileName, profileData, supportedClasses, warnings)
	if type(profileData) ~= "table" then
		table.insert(warnings, ("Profile '%s' invalid: expected table"):format(profileName))
		return nil
	end

	local normalized = {}
	local total = 0
	for className in pairs(supportedClasses) do
		local weight = profileData[className]
		if type(weight) ~= "number" or weight < 0 then
			weight = 0
			table.insert(warnings, ("Profile '%s' class '%s' invalid weight, fallback 0"):format(profileName, className))
		end
		normalized[className] = weight
		total += weight
	end

	if total <= 0 then
		table.insert(warnings, ("Profile '%s' has zero total weight"):format(profileName))
		return nil
	end

	return normalized
end

local function validateNpcEntry(index, entry, supportedClasses, warnings)
	if type(entry) ~= "table" then
		table.insert(warnings, ("NPC entry #%d invalid: expected table"):format(index))
		return nil
	end

	local className = entry.class
	if type(className) ~= "string" or not supportedClasses[className] then
		table.insert(warnings, ("NPC entry #%d invalid class '%s'"):format(index, tostring(className)))
		return nil
	end

	if type(entry.id) ~= "string" or entry.id == "" then
		table.insert(warnings, ("NPC entry #%d missing id"):format(index))
		return nil
	end

	if type(entry.modelName) ~= "string" or entry.modelName == "" then
		table.insert(warnings, ("NPC '%s' missing modelName"):format(entry.id))
		return nil
	end

	if not isPositiveNumber(entry.spawnWeight) then
		table.insert(warnings, ("NPC '%s' invalid spawnWeight"):format(entry.id))
		return nil
	end

	if type(entry.behavior) ~= "table" or type(entry.behavior.type) ~= "string" or entry.behavior.type == "" then
		table.insert(warnings, ("NPC '%s' invalid behavior.type"):format(entry.id))
		return nil
	end

	if type(entry.animations) ~= "table" then
		table.insert(warnings, ("NPC '%s' missing animations table"):format(entry.id))
		return nil
	end

	local idleAnim = entry.animations.idle
	local walkAnim = entry.animations.walk
	local emoteAnim = entry.animations.emote
	if type(idleAnim) ~= "string" or type(walkAnim) ~= "string" or type(emoteAnim) ~= "string" then
		table.insert(warnings, ("NPC '%s' invalid animation ids"):format(entry.id))
		return nil
	end

	local normalized = shallowCopyTable(entry)
	normalized.behavior = shallowCopyTable(entry.behavior)
	normalized.animations = shallowCopyTable(entry.animations)
	return normalized
end

function NPCConfigValidator.Validate(rawConfig)
	local warnings = {}
	local result = {
		isValid = false,
		normalizedConfig = nil,
		warnings = warnings,
	}

	if type(rawConfig) ~= "table" then
		table.insert(warnings, "Config root invalid: expected table")
		return result
	end

	local supportedClasses = rawConfig.SupportedClasses
	if type(supportedClasses) ~= "table" or next(supportedClasses) == nil then
		supportedClasses = {
			normal = true,
			anomaly = true,
			meme = true,
		}
		table.insert(warnings, "SupportedClasses missing: fallback default classes used")
	end

	local normalizedProfiles = {}
	local sourceProfiles = rawConfig.SpawnProfiles
	if type(sourceProfiles) ~= "table" then
		table.insert(warnings, "SpawnProfiles missing/invalid")
		return result
	end

	for profileName in pairs(REQUIRED_PROFILES) do
		if sourceProfiles[profileName] == nil then
			table.insert(warnings, ("Required profile '%s' missing"):format(profileName))
		end
	end

	for profileName, profileData in pairs(sourceProfiles) do
		local normalized = validateProfile(profileName, profileData, supportedClasses, warnings)
		if normalized then
			normalizedProfiles[profileName] = normalized
		end
	end

	local normalizedNpcs = {}
	local sourceNpcs = rawConfig.NPCs
	if type(sourceNpcs) ~= "table" then
		table.insert(warnings, "NPCs missing/invalid")
		return result
	end

	for index, entry in ipairs(sourceNpcs) do
		local normalized = validateNpcEntry(index, entry, supportedClasses, warnings)
		if normalized then
			table.insert(normalizedNpcs, normalized)
		end
	end

	local hasRequiredProfiles = true
	for profileName in pairs(REQUIRED_PROFILES) do
		if normalizedProfiles[profileName] == nil then
			hasRequiredProfiles = false
			break
		end
	end

	if not hasRequiredProfiles then
		table.insert(warnings, "Config invalid: one or more required profiles failed validation")
		return result
	end

	if #normalizedNpcs == 0 then
		table.insert(warnings, "Config invalid: no valid NPC entries after validation")
		return result
	end

	local normalizedPolicy = rawConfig.SpawnPolicy
	if type(normalizedPolicy) ~= "table" then
		normalizedPolicy = {
			maxActiveGlobal = 25,
			maxActiveByClass = {
				normal = 12,
				anomaly = 8,
				meme = 8,
			},
		}
		table.insert(warnings, "SpawnPolicy missing: fallback defaults used")
	end

	result.normalizedConfig = {
		SchemaVersion = rawConfig.SchemaVersion or "unknown",
		DefaultProfile = rawConfig.DefaultProfile or "Day",
		SupportedClasses = shallowCopyTable(supportedClasses),
		SpawnProfiles = normalizedProfiles,
		NPCs = normalizedNpcs,
		SpawnPolicy = normalizedPolicy,
	}
	result.isValid = true
	return result
end

return NPCConfigValidator
