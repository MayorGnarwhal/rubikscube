--[[
	List of macros to extend Collect's functionality
		- Automatically uses 
		Collect:macro(macroName: string, closure: Function)
	
	Macro packages can be parented to this module for easier drag-and-drop functionality
]]

local macros = {}

local lib = require(script.Parent)
local followPath = lib.followPath
local evaluate = lib.evaluate

for i, package in ipairs(script:GetChildren()) do
	for macroName, macroFunction in pairs(require(package)) do
		macros[macroName] = macroFunction
	end
end

-- list macros here
-- function macros:myFunction(...)

return macros