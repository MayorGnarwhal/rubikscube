local lib = {}

--// Dependencies
lib.CustomRange = require(script.CustomRange)

local SoundService = game:GetService("SoundService")

local AssetPrefix = "rbxassetid://"

--// Methods
function lib.CleanSound(soundId: Sound|string|number)
	if typeof(soundId) == "Instance" then
		assert(soundId:IsA("Sound"), "Expected Sound instance. Recieved " .. soundId.ClassName .. ".")
		return soundId:Clone()
	elseif typeof(soundId) == "string" then
		if string.sub(soundId, string.len(AssetPrefix) + 1) == AssetPrefix then
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			return sound
		elseif tonumber(soundId) ~= nil then
			soundId = tonumber(soundId)
		else
			local sound = SoundService:FindFirstChild(soundId, true)
			assert(sound ~= nil, 'Could not find sound "' .. soundId .. '" in SoundService.')
			assert(sound:IsA("Sound"), "Expected Sound instance. Recieved " .. sound.ClassName .. ".")
			return sound:Clone()
		end
	end
	
	if typeof(soundId) == "number" then
		local sound = Instance.new("Sound")
		sound.SoundId = AssetPrefix .. soundId
		return sound
	end
	
	error("Invalid Sound given.")
end

function lib.CleanSoundGroup(soundGroupId: SoundGroup|string)
	if soundGroupId == nil then
		return nil
	elseif typeof(soundGroupId) == "Instance" then
		assert(soundGroupId:IsA("SoundGroup"), "Expected SoundGroup instance. Recieved " .. soundGroupId.ClassName .. ".")
		return soundGroupId:Clone()
	elseif typeof(soundGroupId) == "string" then
		local soundGroup = SoundService:FindFirstChild(soundGroupId, true)
		if soundGroup then
			assert(soundGroup:IsA("SoundGroup"), "Expected SoundGroup instance. Recieved " .. soundGroup.ClassName .. ".")
			return soundGroup
		else
			soundGroup = Instance.new("SoundGroup")
			soundGroup.Name = soundGroupId
			return soundGroup
		end
	end
	
	error("Invalid SoundGroup given.")
end

function lib.CreateCustomRange(min: number?, max: number?, default: number?)
	if min == nil then
		return lib.CustomRange.new(default)
	else
		return lib.CustomRange.new(min, max)
	end
end

--//
return lib