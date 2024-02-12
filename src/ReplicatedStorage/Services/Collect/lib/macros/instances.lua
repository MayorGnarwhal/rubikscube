--[[
	Additional Collect methods specifically for handling tables that contain Instances
]]

local macros = {}

--// Dependencies
local lib = require(script.Parent.Parent)
local followPath = lib.followPath

local CollectionService = game:GetService("CollectionService")


--// Methods
-- Destroys all entries
function macros:Destroy(path: string?)
	for key, value in pairs(self._table) do
		followPath(value, path):Destroy()
	end
end

-- Gets children of each entry
function macros:GetChildren(path: string?)
	return self:map(function(value, key)
		return followPath(value, path):GetChildren()
	end)
end

-- Gets descendants of each entry
function macros:GetDescendants(path: string?)
	return self:map(function(value, key)
		return followPath(value, path):GetDescendants()
	end)
end

-- Filters collection to instances that are descendant of a given ancestor
function macros:whereDescendantOf(ancestor: Instance)
	lib.assertType(ancestor, "Instance")
	return self:filter(function(value, key)
		return value:IsDescendantOf(ancestor)
	end)
end

-- Filters collection to instances that are not descendant of a given ancestor
function macros:whereNotDescendantOf(ancestor: Instance)
	lib.assertType(ancestor, "Instance")
	return self:filter(function(value, key)
		return not value:IsDescendantOf(ancestor)
	end)
end

-- Filters collection to instances that are ancestor of a given ancestor
function macros:whereAncestorOf(ancestor: Instance)
	lib.assertType(ancestor, "Instance")
	return self:filter(function(value, key)
		return value:IsAncestorOf(ancestor)
	end)
end

-- Filters collection to instances that are not ancestor of a given ancestor
function macros:whereNotAncestorOf(ancestor: Instance)
	lib.assertType(ancestor, "Instance")
	return self:filter(function(value, key)
		return not value:IsAncestorOf(ancestor)
	end)
end

-- Filters collection to instances that have given CollectionServiceTag
function macros:whereHasTag(path: string?, tag: string)
	path, tag = lib.cleanArguments({path, tag}, {
		{"string", "string"},
		{false, "string"},
	})
	return self:filter(function(value, key)
		return CollectionService:HasTag(followPath(value, path), tag)
	end)
end

-- Filters collection to instances that have given CollectionServiceTag
function macros:whereNotHasTag(path: string?, tag: string)
	path, tag = lib.cleanArguments({path, tag}, {
		{"string", "string"},
		{false, "string"},
	})
	return self:filter(function(value, key)
		return not CollectionService:HasTag(followPath(value, path), tag)
	end)
end

-- Filters collection to instance of a given class
function macros:whereInstanceOf(path: string?, className: string)
	path, className = lib.cleanArguments({path, className}, {
		{"string", "string"},
		{false, "string"},
	})
	return self:filter(function(value, key)
		value = followPath(value, path)
		return typeof(value) == "Instance" and value:IsA(className)
	end)
end

-- Filters collection to values that are not an instance of a given class
function macros:whereNotInstanceOf(path: string?, className: string)
	path, className = lib.cleanArguments({path, className}, {
		{"string", "string"},
		{false, "string"},
	})
	return self:filter(function(value, key)
		value = followPath(value, path)
		return typeof(value) ~= "Instance" or not value:IsA(className)
	end)
end

--//
return macros