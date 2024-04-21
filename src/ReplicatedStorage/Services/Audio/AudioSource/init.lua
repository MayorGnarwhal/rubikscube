local Source = {}
Source.__index = Source

--// Dependencies
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Defaults = require(script.Defaults)
local lib = require(script.Parent.lib)
local CustomRange = lib.CustomRange

--// Constructor
function Source.new(soundGroup: SoundGroup)
	local self = setmetatable({
		SoundGroup = soundGroup;
		SoundEffects = {};
		Volume = CustomRange.new(1);
		Pitch = CustomRange.new(1);
	}, Source)
	
	return self
end

--// Helper functions
local function ApplySoundEffect(self, effectName: string, propertyMap: {[Property]: CustomRange})
	local effect = self.SoundEffects[effectName]
	if not effect then
		effect = {
			Instance = Instance.new(effectName);
			Properties = nil;
		}
		self.SoundEffects[effectName] = effect
	end
	
	effect.Properties = propertyMap
end

--// Methods
function Source:Play(sound: Sound|string|number, adornee: Instance?)
	sound = lib.CleanSound(sound)
	
	for effectClass, effectInfo in pairs(self.SoundEffects) do
		local effect = effectInfo.Instance:Clone()
		for property, range in pairs(effectInfo.Properties) do
			effect[property] = range:GetValue()
		end
		effect.Parent = sound
	end
	
	sound.Volume *= self.Volume:GetValue()
	sound.SoundGroup = self.SoundGroup or sound.SoundGroup
	sound.Parent = adornee or SoundService
	
	if sound.Looped then
		sound:Play()
		return sound
	else
		sound.PlayOnRemove = true
		sound:Destroy()
	end
end

function Source:SetVolume(min: number?, max: number?)
	self.Volume = lib.CreateCustomRange(min, max, Defaults.SoundGroup.Volume)
end

function Source:SetPitch(min: number?, max: number?)
	self.Pitch = lib.CreateCustomRange(min, max, Defaults.PitchShiftSoundEffect.Octave)
	ApplySoundEffect(self, "PitchShiftSoundEffect", {
		Octave = self.Pitch;
	})
end

--//
return Source