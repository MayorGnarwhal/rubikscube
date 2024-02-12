local lib = {}

--// Dependencies
lib.operations = require(script.operations)
lib.followPath = require(script.followPath)
lib.macros = script:FindFirstChild("macros")

--// Variables
local _argumentPlaceholder = game:GetService("HttpService"):GenerateGUID()


--// Methods
--[[
	Custom unpack for arrays with nil entries
		ie {[1]=1, [3]=3}
	Clears given table. If table should be kept, pass a shallow copy
]]
function lib.unpack(tbl: array, i: number?, ...)
	i = i or 1
	if next(tbl) == nil then
		return ...
	else
		local item = tbl[i]
		tbl[i] = nil
		return item, lib.unpack(tbl, i+1)
	end
end

function lib.ofType(val, argType)
	if argType == "operator" then
		return lib.operations[val] ~= nil
	elseif typeof(val) == argType then
		return true
	elseif argType == true or argType == "any" then
		return true
	end
	
	return false
end

--[[
	Clean arguments to simulate overloaded functions
	Returns a tuple of arguments based on matching option
		If no option matches, then an error is thrown
		
	args is an array of the arguments as they were passed into the function
	options is an array of types, indicating where arguments are positioned
		true means any type can be placed there
		false means the argument is allowed to be nil
]]
function lib.cleanArguments(args: table, options: table)
	for i, option in ipairs(options) do
		local packed = {}
		local count = 1
		--print("option", i)
		local match = true
		for j, argType in ipairs(option) do
			--print("  ", argType, args[count], "//", count)
			if argType ~= false then
				if not lib.ofType(args[count], argType) then
					match = false
					break
				end
				--print("    pack")
				packed[j] = args[count]
				count += 1
			end
		end
		
		if match then
			return lib.unpack(packed)
		end
	end
	
	error("Invalid arguments given", 3)
end

function lib.evaluate(item, operator, target)
	assert(lib.operations[operator] ~= nil, "Attempting to compare with an invalid operator", operator)
	return lib.operations[operator](item, target)
end

function lib.isArray(tbl: table)
	local i = 0
	for _ in pairs(tbl) do
		i = i + 1
		if tbl[i] == nil then return false end
	end
	return true
end

function lib.iterate(tbl: table, isArray: boolean?, closure: Function)
	if closure == nil then
		closure = isArray
		isArray = tbl._isArray
		tbl = tbl._table
	end
	
	local iter = 1
	for key, value in (isArray and ipairs or pairs)(tbl) do
		local ret = closure(key, value, iter)
		if ret ~= nil then
			if typeof(ret) == "table" then
				return unpack(ret)
			end
			return ret
		end
		iter += 1
	end
end

function lib.deepCopy(orig)
	if type(orig) == 'table' then
		local copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[lib.deepCopy(orig_key)] = lib.deepCopy(orig_value)
		end
		setmetatable(copy, lib.deepCopy(getmetatable(orig)))
		return copy
	else
		return orig
	end
end

function lib.append(tbl: table, key: any, value: any, retainKeys: boolean)
	if retainKeys then
		tbl[key] = value
	else
		table.insert(tbl, value)
	end
end

function lib.pathOrClosure(value, key, pathOrClosure: string | Function)
	if typeof(pathOrClosure) == "function" then
		return pathOrClosure(value, key)
	else
		return lib.followPath(value, pathOrClosure)
	end
end

function lib.cleanRandom(random: Random? | number?)
	if typeof(random) == "Random" then
		return random
	elseif typeof(random) == "number" then
		return Random.new(random)
	else
		return Random.new()
	end
end

local ignoreFunctionNames = {"", "iterate", "filter"}
function lib.getFunctionName()
	local name
	local depth = 3
	
	while name == nil or table.find(ignoreFunctionNames, name) do
		name = debug.info(depth, "n")
		depth += 1
	end
	
	return name
end

function lib.assertType(value, typeName)
	if value ~= nil and typeof(value) ~= typeName then
		error("invalid argument (" .. typeName .. " expected, got " ..typeof(value) .. " .. '" .. tostring(value) .. "')", 2)
	end
end

function lib.warn(variant, ...)
	if variant then
		warn("[Collect]:", ...)
	end
end

--//
return lib