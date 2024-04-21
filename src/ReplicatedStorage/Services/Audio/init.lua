local Audio = {}

--// Dependencies
local lib = require(script.lib)
local AudioSource = require(script.AudioSource)

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ReplicateSound = script:WaitForChild("Replicate")
Audio.Sounds = SoundService.SFX

--// Constructors
--[[
	Returns a new Sound Instance parent to adornee, given an existing Sound Instance, 
	a name of a Sound in SoundService, or a SoundId
]]
function Audio.sound(sound: Sound|string|number, adornee: Instance?)
	assert(adornee == nil or typeof(adornee) == "Instance", "Invalid adornee given.")
	
	sound = lib.CleanSound(sound)
	sound.Parent = adornee or SoundService
	
	return sound
end

--[[
	Returns a new AudioSource that plays sounds on a given SoundGroup
]]
function Audio.source(soundGroup: SoundGroup?)
	soundGroup = lib.CleanSoundGroup(soundGroup)
	
	return AudioSource.new(soundGroup)
end


--// Methods
--[[
	Lightweight method of playing a given sound on an Instance
	If Sound is looped, then it is returned and must be manually cleaned
		If a Sound Instance is given, a clone of that Sound is returned
]]
function Audio.Play(sound: Sound|string|number, adornee: Instance?)
	sound = Audio.sound(sound, adornee)
	
	if sound.Looped then
		sound:Play()
		return sound
	else
		sound.PlayOnRemove = true
		sound:Destroy()
	end
end

--[[
	Tween a given Sound's Volume to 0 and destroy Instance
]]
function Audio.Fade(sound: Instance, duration: number?)
	assert(typeof(sound) == "Instance" and sound:IsA("Sound"), "Invalid Sound given.")
	
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration or 0.5, Enum.EasingStyle.Sine),
		{Volume = 0}
	)
	
	task.spawn(function()
		tween:Play()
		tween.Completed:Wait()
		sound:Destroy()
	end)
end

if RunService:IsClient() then
	function Audio.PlayOnServer(...)
		ReplicateSound:FireServer(...)
	end
	
	ReplicateSound.OnClientEvent:Connect(Audio.Play)
end

if RunService:IsServer() then
	ReplicateSound.OnServerEvent:Connect(function(player, ...)
		Audio.Play(...)
	end)
	
	function Audio.PlayOnClient(player, ...)
		ReplicateSound:FireClient(player, ...)
	end
end

--//
return Audio