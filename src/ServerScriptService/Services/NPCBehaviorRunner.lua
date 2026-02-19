--[[
NPCBehaviorRunner
- Router behavior berdasarkan class/type NPC.
- Menjalankan hook animasi dasar (idle/walk/emote) secara safe agar spawn loop tidak crash saat asset bermasalah.
]]

local NPCBehaviorsFolder = script.Parent:WaitForChild("NPCBehaviors")
local NormalBehaviors = require(NPCBehaviorsFolder:WaitForChild("NormalBehaviors"))
local AnomalyBehaviors = require(NPCBehaviorsFolder:WaitForChild("AnomalyBehaviors"))
local MemeBehaviors = require(NPCBehaviorsFolder:WaitForChild("MemeBehaviors"))

local NPCBehaviorRunner = {}
NPCBehaviorRunner.__index = NPCBehaviorRunner

function NPCBehaviorRunner.new(services)
	local self = setmetatable({}, NPCBehaviorRunner)
	self._services = services or {}
	self._classHandlers = {
		normal = NormalBehaviors,
		anomaly = AnomalyBehaviors,
		meme = MemeBehaviors,
	}
	return self
end

function NPCBehaviorRunner:SetServices(services)
	self._services = services or {}
end

function NPCBehaviorRunner:_ensureAnimator(npcModel)
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn(("NPCBehaviorRunner: '%s' missing Humanoid"):format(npcModel.Name))
		return nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	return animator
end

function NPCBehaviorRunner:_loadAnimationTrack(animator, animationId, trackName)
	if type(animationId) ~= "string" or animationId == "" then
		return nil
	end

	local ok, trackOrError = pcall(function()
		local animation = Instance.new("Animation")
		animation.AnimationId = animationId
		local track = animator:LoadAnimation(animation)
		track.Name = trackName
		animation:Destroy()
		return track
	end)

	if not ok then
		warn(("NPCBehaviorRunner: gagal load animation '%s' (%s)"):format(trackName, tostring(trackOrError)))
		return nil
	end

	return trackOrError
end

function NPCBehaviorRunner:_playTrack(track, isLooped)
	if not track then
		return false
	end

	local ok, err = pcall(function()
		track.Looped = isLooped and true or false
		track:Play(0.15)
	end)
	if not ok then
		warn(("NPCBehaviorRunner: gagal play animation track: %s"):format(tostring(err)))
		return false
	end

	return true
end

function NPCBehaviorRunner:_setupAnimationBundle(npcModel, npcData)
	local animator = self:_ensureAnimator(npcModel)
	if not animator then
		return {
			idle = nil,
			walk = nil,
			emote = nil,
		}
	end

	local animations = npcData.animations or {}
	local bundle = {
		idle = self:_loadAnimationTrack(animator, animations.idle, "Idle"),
		walk = self:_loadAnimationTrack(animator, animations.walk, "Walk"),
		emote = self:_loadAnimationTrack(animator, animations.emote, "Emote"),
	}

	self:_playTrack(bundle.idle, true)
	return bundle
end

function NPCBehaviorRunner:_playEmote(animationBundle)
	if not animationBundle or not animationBundle.emote then
		return false
	end

	local played = self:_playTrack(animationBundle.emote, false)
	if not played then
		return false
	end

	if animationBundle.idle then
		task.delay(1.0, function()
			self:_playTrack(animationBundle.idle, true)
		end)
	end

	return true
end

function NPCBehaviorRunner:RunBehavior(npcModel, npcData)
	if not npcModel or not npcData then
		return false
	end

	local className = npcData.class
	local handlerModule = self._classHandlers[className]
	if not handlerModule then
		warn(("NPCBehaviorRunner: unknown NPC class '%s'"):format(tostring(className)))
		return false
	end

	local animationBundle = self:_setupAnimationBundle(npcModel, npcData)
	local behaviorContext = {
		services = self._services,
		playEmote = function(chance)
			local rollChance = tonumber(chance) or 1
			if math.random() <= rollChance then
				self:_playEmote(animationBundle)
			end
		end,
	}

	local ok, didRun, reason = pcall(function()
		return handlerModule.Execute(npcModel, npcData, behaviorContext)
	end)
	if not ok then
		warn(("NPCBehaviorRunner: handler panic untuk '%s': %s"):format(tostring(npcData.id), tostring(didRun)))
		return false
	end

	if not didRun then
		warn(("NPCBehaviorRunner: handler gagal untuk '%s' (%s)"):format(tostring(npcData.id), tostring(reason)))
	end

	return didRun and true or false
end

return NPCBehaviorRunner
