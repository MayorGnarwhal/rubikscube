--[[
	Additional Collect methods specifically for handling connections
]]

local macros = {}

--// Dependencies
local lib = require(script.Parent.Parent)
local followPath = lib.followPath


--// Methods
-- Connect event to each value and returns collection of connections
function macros:Connect(event: string, closure: Function)
	return self:map(function(value, key)
		return value[event]:Connect(function(...)
			closure(value, ...)
		end)
	end)
end

-- Connect Changed event to each ValueBase and returns collection of connections
function macros:Changed(closure: Function)
	return self:Connect("Changed", closure)
end

-- Disconnect all entries of collection
function macros:Disconnect(path: string?)
	for key, value in pairs(self._table) do
		followPath(value, path):Disconnect()
	end
end

-- Listen for Attribute change and returns collection of connections
function macros:GetAttributeChangedSignal(attribute: string, closure: Function)
	return self:map(function(value, key)
		return value:GetAttributeChangedSignal(attribute):Connect(function()
			closure(value, value:GetAttribute(attribute))
		end)
	end)
end

-- Listen for Property change and returns collection of connections
function macros:GetPropertyChangedSignal(property: string, closure: Function)
	return self:map(function(value, key)
		return value:GetPropertyChangedSignal(property):Connect(function()
			closure(value, value[property])
		end)
	end)
end

--//
return macros