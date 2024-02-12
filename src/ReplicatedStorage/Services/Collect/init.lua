--[[
	Collect is a fluent, and convienient wrapper for tables
	Inspired by and modeled after Laravel Collections
		https://laravel.com/docs/10.x/collections
]]

local Collect = {}
Collect.__index = Collect

----------------------------------------------------------------------------------------------------
----// Dependencies \\------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local lib = require(script.lib)
local evaluate = lib.evaluate
local followPath = lib.followPath

----------------------------------------------------------------------------------------------------
----// Constructors \\------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Create a new Collection object
function Collect.new(tbl: table|Collect)
	tbl = tbl or {}
	lib.assertType(tbl, "table")

	if getmetatable(tbl) == Collect then
		tbl = tbl:get()
	end

	local isArray = lib.isArray(tbl)
	return setmetatable({
		_table = tbl;
		_isArray = isArray;
		_retainKeys = not isArray;
	}, Collect)
end

-- Create a new Collection object with a deep copy of a table
function Collect.clone(tbl: table|Collect)
	return Collect.new(lib.deepCopy(tbl))
end


function Collect.create(count: number, value: any|Function)
	local tbl = {}
	for i = 1, count do
		if typeof(value) == "function" then
			local nKey, nValue = value(i)
			if nValue == nil then
				tbl[i] = nKey
			else
				tbl[nKey] = nValue
			end
		else
			tbl[i] = typeof(value) == "table" and lib.deepCopy(value) or value
		end
	end
	return Collect(tbl)
end


----------------------------------------------------------------------------------------------------
----// Macros \\------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Add a custom method to the Collect module
function Collect:macro(macroName: string, closure: Function)
	lib.warn(Collect[macroName] ~= nil, "Overwriting method '" .. macroName .. "'")
	Collect[macroName] = closure
end

if lib.macros then
	for macroName, macroClosure in pairs(require(lib.macros)) do
		Collect:macro(macroName, macroClosure)
	end
end


----------------------------------------------------------------------------------------------------
----// Settings \\----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Tell collection to maintain its keys while being modified
-- Useful to prevent arrays from shifting while removing intermitent values
function Collect:retainKeys(shouldRetain: boolean?)
	self._retainKeys = (shouldRetain == nil and true) or shouldRetain
	return self
end

-- Tap into the collection at a given point
function Collect:tap(closure: Function)
	closure(self)
	return self
end


----------------------------------------------------------------------------------------------------
----// Filters \\-----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Filters collection using given closure, keeping only entries that evaluate truthy
function Collect:filter(closure: Function)
	local filtered = {}
	lib.iterate(self, function(key, value)
		if closure(value, key) then
			lib.append(filtered, key, value, self._retainKeys)
		end
	end)
	return Collect(filtered)
end

-- Filters collection using given closure, keeping only entries that do not return truthy
function Collect:reject(closure: Function)
	local filtered = {}
	lib.iterate(self, function(key, value)
		if not closure(value, key) then
			lib.append(filtered, key, value, self._retainKeys)
		end
	end)
	return Collect(filtered)
end

-- Filters collection using the given equation, keeping only entries that evaluate truthy
function Collect:where(path: string, operator: string?, compare: any)
	path, operator, compare = lib.cleanArguments({path, operator, compare}, {
		{"string", "operator", true}, -- :where(path, operator, compare)
		{false, "operator", true},    -- :where(operator, compare)
		{"string", false, true},      -- :where(path, compare)
		{false, false, true},         -- :where(compare)
	})

	operator = operator or "=="
	return self:filter(function(value, key)
		return lib.evaluate(followPath(value, path), operator, compare)
	end)
end

-- Filters numerical collection to entries that are within [min, max]
function Collect:whereBetween(path: string?, min: number, max: number)
	path, min, max = lib.cleanArguments({path, min, max}, {
		{"string", "number", "number"}, -- :whereBetween(path, min max)
		{false, "number", "number"},    -- :whereBetween(min, max)
	})
	lib.assertType(min, "number")
	lib.assertType(max, "number")
	assert(min < max, "Maximum value cannot be greater than Minimum")

	return self:filter(function(value, key)
		value = followPath(value, path)
		lib.assertType(value, "number")
		return min <= value and value <= max
	end)
end

-- Filters numerical collection to entries that are not within [min, max]
function Collect:whereNotBetween(path: string?, min: number, max: number)
	path, min, max = lib.cleanArguments({path, min, max}, {
		{"string", "number", "number"}, -- :whereNotBetween(path, min max)
		{false, "number", "number"},    -- :whereNotBetween(min, max)
	})
	lib.assertType(min, "number")
	lib.assertType(max, "number")

	return self:filter(function(value, key)
		value = followPath(value, path)
		lib.assertType(value, "number")
		return value < min or value > max
	end)
end

-- Filters collection by values not found in given haystack
function Collect:whereIn(path: string?, haystack: table|Collect)
	path, haystack = lib.cleanArguments({path, haystack}, {
		{false, true},
	})
	lib.assertType(haystack, "table")
	if getmetatable(haystack) ~= Collect then
		haystack = Collect(haystack)
	end

	return self:filter(function(value, key)
		local needle = followPath(value, path)
		return haystack:find(needle) ~= nil
	end)
end

-- Filters collection by values found in given haystack
function Collect:whereNotIn(path: string?, haystack: table|Collect)
	path, haystack = lib.cleanArguments({path, haystack}, {
		{"string", "table"}, -- :whereIn(path, haystack)
		{false, "table"},    -- :whereIn(haystack)
	})
	lib.assertType(haystack, "table")
	if getmetatable(haystack) ~= Collect then
		haystack = Collect(haystack)
	end

	return self:filter(function(value, key)
		local needle = followPath(value, path)
		return haystack:find(needle) == nil
	end)
end

-- Filters collection to values that are nil at the given path
function Collect:whereNil(path: string)
	return self:filter(function(value, key)
		return followPath(value, path) == nil
	end)
end

-- Filters collection to values that are not nil at a given path
function Collect:whereNotNil(path: string)
	return self:filter(function(value, key)
		return followPath(value, path) ~= nil
	end)
end
Collect.whereHas = Collect.whereNotNil

-- Filters collection to values of a given type
function Collect:whereOfType(path: string?, class: string)
	path, class = lib.cleanArguments({path, class}, {
		{"string", "string"}, -- :whereOfType(path, class)
		{false, "string"},    -- :whereOfType(class)
	})
	return self:filter(function(value, key)
		return typeof(followPath(value, path)) == class
	end)
end

-- Filters collection to values not of a given type
function Collect:whereNotOfType(path: string?, class: string)
	path, class = lib.cleanArguments({path, class}, {
		{"string", "string"}, -- :whereNotOfType(path, class)
		{false, "string"},    -- :whereNotOfType(class)
	})
	return self:filter(function(value, key)
		return typeof(followPath(value, path)) ~= class
	end)
end


----------------------------------------------------------------------------------------------------
----// Mutators \\----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Creates Cartesian Product of collection
function Collect:cartesianProduct(tbl: table|Collect)
	if getmetatable(tbl) ~= Collect then
		tbl = Collect(tbl)
	end
	assert(self._isArray and tbl:isArray(), "Cannot perform Cartesian Product on a dictonary")
	-- TODO
end

-- Breaks collection into multiple smaller tables of a given size
function Collect:chunk(chunkSize: number)
	return self:chunkWhile(function(value, key, lastChunk)
		return #Collect(lastChunk) < chunkSize
	end)
end

-- Breaks collection into multiple smaller tables, seperated with given closure returns falsy
function Collect:chunkWhile(closure: Function)
	local chunked = Collect.create(1, {})
	local numChunks = 1
	lib.iterate(self, function(key, value, iter)
		if not closure(value, key, chunked[numChunks]) then
			if iter > 1 then
				numChunks += 1
			end
			chunked[numChunks] = {}
		end
		lib.append(chunked[numChunks], key, value, self._retainKeys)
	end)
	return chunked
end

-- Counts the occurences of values in the collection
function Collect:countBy(determineValue: string?|Function?)
	local counted = {}
	lib.iterate(self, function(key, value)
		local entryKey = determineValue == nil and value or lib.pathOrClosure(value, key, determineValue)
		counted[entryKey] = (counted[entryKey] or 0) + 1
	end)
	return Collect(counted)
end

-- Compares another table's key, value pairs
-- Returns dictonary collection of key, value pairs of key, value pairs not in given table
function Collect:diffAssoc(tbl: table|Collect)
	local diff = {}
	lib.iterate(self, function(key, value)
		if tbl[key] ~= value then
			diff[key] = value
		end
	end)
	return Collect(diff)
end

-- Compares another table's key, value pairs
-- Returns dictonary collection of key, value pairs whos keys are not in the given table
function Collect:diffKeys(tbl: table|Collect)
	local diff = {}
	lib.iterate(self, function(key, value)
		if tbl[key] == nil then
			diff[key] = value
		end
	end)
	return Collect(diff)
end

-- Count duplicate occurences of values in the collection
function Collect:duplicates(determineKey: string?|Function?)
	return self:retainKeys():countBy(determineKey):where(">", 1)
end

-- Flatten a multi-dimensional array to a single dimension, or until a specified depth is reached
function Collect:flatten(depth: number?)
	local flat = {}
	local function doFlatten(tbl, dep)
		if getmetatable(tbl) == Collect then
			tbl = tbl:get()
		end
		for key, value in pairs(tbl) do
			if dep == depth or typeof(value) ~= "table" then
				lib.append(flat, key, value, false)
			else
				doFlatten(value, dep + 1)
			end
		end
	end
	doFlatten(self._table, 1)
	return Collect(flat)
end

-- Group collection by a given key or closure
function Collect:groupBy(determineGroup: string|Function)
	local grouped = {}
	lib.iterate(self, function(key, value)
		local groupKey = lib.pathOrClosure(value, key, determineGroup)
		if not grouped[groupKey] then
			grouped[groupKey] = {}
		end
		lib.append(grouped[groupKey], key, value, self._retainKeys)
	end)
	return Collect(grouped)
end

-- Keys collection by a value at a given path
function Collect:keyBy(determineKey: string|Function)
	return self:mapWithKeys(function(value, key)
		return lib.pathOrClosure(value, key, determineKey), value
	end)
end

-- Returns an array collection of the collection's keys
function Collect:keys()
	local keys = {}
	lib.iterate(self, function(key, value)
		table.insert(keys, key)
	end)
	return Collect(keys)
end

-- Remap values of the collection by a given closure
function Collect:map(closure: Function)
	local mapped = {}
	lib.iterate(self, function(key, value)
		mapped[key] = closure(value, key)
	end)
	return Collect(mapped)
end

-- Remap key, value pairs of the collection by a given closure
function Collect:mapWithKeys(closure: Function)
	local mapped = {}
	lib.iterate(self, function(key, value)
		local nKey, nValue = closure(value, key)
		assert(key ~= nil, "Cannot set nil key")
		mapped[nKey] = nValue
	end)
	return Collect(mapped)
end

-- Get every n-th entry of the collection, starting at an optional offset
function Collect:nth(frequency: number, offset: number?)
	local taken = {}
	local count = (offset or 0) - 1
	lib.iterate(self, function(key, value)
		count += 1
		if count % frequency ~= 0 then return end
		lib.append(taken, key, key, self._retainKeys)
	end)
	return Collect(taken)
end

-- Remaps collection to values at path
-- Optionally can specify how remapped collection should be keyed
function Collect:pluck(path: string, keyPath: string?)
	return self:mapWithKeys(function(value, key)
		return (keyPath == nil and key or followPath(value, keyPath)), followPath(value, path)
	end)
end

-- Remove the first few entries of collection
-- If count < 1, then a percentage of the length is skipped
function Collect:skip(count: number)
	if count < 1 then -- skip by a percentage
		count = math.floor(self:count() * count)
	end
	local taken = {}
	lib.iterate(self, function(key, value)
		count -= 1
		if count >= 0 then return end
		lib.append(taken, key, value, self._retainKeys)
	end)
	return Collect(taken)
end

-- Remove the starting entries a given closure returns truthy
function Collect:skipUntil(closure: Function|any)
	if typeof(closure) ~= "function" then
		local val = closure
		closure = function(value) return value == val end
	end

	local taken = {}
	local doneSkip = false
	lib.iterate(self, function(key, value)
		doneSkip = doneSkip or closure(value, key)
		if not doneSkip then return end
		lib.append(taken, key, value, self._retainKeys)
	end)
	return Collect(taken)
end

-- Remove the starting entries while a given closure returns truthy
function Collect:skipWhile(closure: Function|any)
	if typeof(closure) ~= "function" then
		local val = closure
		closure = function(value) return value == val end
	end

	return self:skipUntil(function(value, key)
		return not closure(value, key)
	end)
end

-- Returns a slice of the array collection from [startIndex, endIndex]
function Collect:slice(startIndex: number, endIndex: number?)
	assert(self._isArray, "Cannot slice a dictonary")
	return Collect({unpack(self._table, startIndex, endIndex)})
end

-- Split collection in a given number of groups
function Collect:split(numGroups: number)
	local groupSize = self:count() / numGroups
	return self:chunkWhile(function(value, key, chunk)
		return #chunk < groupSize
	end)
end

-- Take the first few entries of the collection
-- If count < 1, then a percentage of the length is taken
function Collect:take(count: number?)
	if count < 1 then -- take by a percentage
		count = math.floor(self:count() * count)
	end
	local taken = {}
	lib.iterate(self, function(key, value)
		lib.append(taken, key, value, self._retainKeys)
		count -= 1
		if count <= 0 then return false end
	end)
	return Collect(taken)
end

-- Take elements until a given closure returns truthy
function Collect:takeUntil(closure: Function|any)
	if typeof(closure) ~= "function" then
		local val = closure
		closure = function(value) return value == val end
	end

	local taken = {}
	lib.iterate(self, function(key, value)
		if closure(value, key) then return false end
		lib.append(taken, key, value, self._retainKeys)
	end)
	return Collect(taken)
end

-- Take elements while a given closure returns truthy
function Collect:takeWhile(closure: Function)
	return self:takeUntil(function(value, key)
		return not closure(value, key)
	end)
end

-- Turns a dictonary into an array of key, value pairs
function Collect:toArray()
	local array = {}
	lib.iterate(self, function(key, value)
		table.insert(array, {key = key; value = value})
	end)
	return Collect(array)
end

-- Remove all duplicate values from collection
function Collect:unique(path: string?)
	local taken = {}
	lib.iterate(self, function(key, value)
		if taken:where(path, "==", followPath(value, path)):isEmpty() then
			lib.append(taken, key, value, self._retainKeys)
		end
	end)
	return Collect(taken)
end

-- Returns an array of the collection's values
function Collect:values()
	local values = {}
	lib.iterate(self, function(key, value)
		table.insert(values, value)
	end)
	return Collect(values)
end


----------------------------------------------------------------------------------------------------
----// Sorts \\-------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Reverses order of collection. Has no effect on dictonaries
--	Derived from https://programming-idioms.org/idiom/19/reverse-a-list/1314/lua
function Collect:flip()
	local n, m = self:count(), self:count()/2
	for i = 1, m do
		self._table[i], self._table[n-i+1] = self._table[n-i+1], self._table[i]
	end
	return self
end

-- Sort collection by a given sort function or in ascending order
function Collect:sort(sortFunction: Function?)
	assert(self._isArray, "Cannot sort a dictonary")
	table.sort(self._table, sortFunction)
	return self
end

-- Sort collection in descending order
function Collect:sortDesc()
	return self:sort(function(left, right)
		return left > right
	end)
end

-- Sort collection by values at a given path in ascending order
function Collect:sortBy(path: string|Function)
	return self:sort(function(left, right)
		return lib.pathOrClosure(left, nil, path) < lib.pathOrClosure(right, nil, path)
	end)
end

-- Sort collection by values at a given path in descending order
function Collect:sortByDesc(path: string)
	return self:sort(function(left, right)
		return lib.pathOrClosure(left, nil, path) > lib.pathOrClosure(right, nil, path)
	end)
end

-- Randomly shuffles collection with Fisher-Yates shuffle
function Collect:shuffle(random: Random?|number?)
	assert(self._isArray, "Cannot shuffle a dictonary")
	local random = lib.cleanRandom(random)
	for i = self:count(), 2, -1 do
		local j = random:NextInteger(1, i)
		self._table[i], self._table[j] = self._table[j], self._table[i]
	end
	return self
end

-- Randomly shuffle collection with weighted elements
--	Derived from http://utopia.duth.gr/%7Epefraimi/research/data/2007EncOfAlg.pdf (Algorithm A)
function Collect:weightedShuffle(path: string?, random: Random?|number?)
	random = lib.cleanRandom(random)
	return self:sortBy(function(value)
		return random:NextNumber() ^ (1 / followPath(value, path))
	end)
end


----------------------------------------------------------------------------------------------------
----// Getters \\-----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Returns underlying table represented by the collection
function Collect:get()
	return self._table
end

-- Returns average of elements in a collection
function Collect:average(path: string?)
	return self:sum(path) / self:count()
end

-- Returns a deep copy of the current collection
function Collect:collect()
	return Collect(lib.deepCopy(self._table))
end

-- Joins collection into a string, combined by the glue
function Collect:concat(glue: string?, startIndex: number?, endIndex: number?)
	if endIndex and endIndex < 0 then
		endIndex += self:count()
	end
	return table.concat(self._table, glue, startIndex, endIndex)
end

-- Returns boolean indicating if collection contains an entry statisfying a given closure
function Collect:contains(closure: Function)
	lib.assertType(closure, "function")
	return self:firstWhere(closure) ~= nil
end

-- Returns number of elements in collection
function Collect:count()
	if self._isArray then
		return #self._table
	else
		return self:reduce(function(carry)
			return carry + 1
		end, 0)
	end
end
Collect.length = Collect.count

-- Returns boolean indicating if no entries satisfy a given closure
function Collect:doesntContain(closure: Function)
	lib.assertType(closure, "function")
	return not self:contains(closure)
end

-- Returns boolean indicating if every key, value pair is shared by both tables
function Collect:equals(tbl: table|Collect)
	if getmetatable(tbl) == Collect then
		tbl = tbl:get()
	end
	lib.assertType(tbl, "table")

	for key, value in pairs(self._table) do
		if tbl[key] ~= value then
			return false
		end
	end
	for key, value in pairs(tbl) do
		if self._table[key] ~= value then
			return false
		end
	end
	return true
end

-- Returns boolean indicating if every entry of collection satisfies a given closure
function Collect:every(closure: Function)
	lib.assertType(closure, "function")
	for key, value in pairs(self._table) do
		if not closure(value, key) then
			return false
		end
	end
	return true
end

-- Returns the first element of the collection
function Collect:first()
	if self._isArray then
		return self._table[1], #self > 0 and 1 or nil
	else
		local key, value = next(self._table)
		return value, key
	end
end

-- Returns the first value, key pair that satisfies a given closure
function Collect:firstWhere(path: string?|Function?, operator: string, compare: any)
	path, operator, compare = lib.cleanArguments({path, operator, compare}, {
		{"string", "operator", true}, -- :firstWhere(path, operator, compare)
		{false, "operator", true},    -- :firstWhere(operator, compare)
		{"string", false, true},      -- :firstWhere(path, compare)
		{"function", false, false},   -- :firstWhere(closure)
		{false, false, true},         -- :firstWhere(compare)
	})

	local closure = path
	if typeof(path) ~= "function" then
		closure = function(value, key)
			return lib.evaluate(followPath(value, path), operator, compare)
		end
	end 

	operator = operator or "=="
	return lib.iterate(self, function(key, value)
		if closure(value, key) then
			return {value, key}
		end
	end)
end

-- Returns key of given value in collection, or nil if value is not found
function Collect:find(needle: any, init: number?)
	if self._isArray then
		return table.find(self._table, needle, init)
	else
		for key, value in pairs(self._table) do
			if value == needle then
				return key
			end
		end
	end
end

-- Returns boolean indicating if collection is an array
function Collect:isArray()
	return self._isArray
end

-- Returns boolean indicating if collection is empty
function Collect:isEmpty()
	return next(self._table) == nil
end

-- Returns boolean indicating if collection is not empty
function Collect:isNotEmpty()
	return next(self._table) ~= nil
end

-- Returns the last value, key pair in the collection
function Collect:last()
	if self._isArray then
		return self._table[#self._table], #self._table
	else
		local key, value = next(self._table)
		return value, key
	end
end

-- Returns a tuple (max, key, value) of the largest element
function Collect:max(path: string|Function)
	local max, index = -math.huge, nil
	for key, value in pairs(self._table) do
		local value = lib.pathOrClosure(value, key, path)
		if value > max then
			max, index = value, key
		end
	end
	return max, index, self._table[index]
end

-- Returns the median of the collection
-- If length if odd, then return average of middle two values
function Collect:median(path: string?)
	assert(self._isArray, "Cannot find median of dictonary")
	local collect = Collect.clone(self):sortBy(path)
	local mid = (collect:count() + 1) / 2
	if mid % 1 == 0 then
		return collect[mid]
	else
		return (collect[math.floor(mid)] + collect[math.ceil(mid)]) / 2
	end
end

-- Returns a tuple (min, key, value) of the smallest element
function Collect:min(path: string|Function)
	local min, index = math.huge, nil
	for key, value in pairs(self._table) do
		local value = lib.pathOrClosure(value, key, path)
		if value < min then
			min, index = value, key
		end
	end
	return min, index, self._table[index]
end

-- Returns a collection of the most commonly occuring values
function Collect:mode(path: string?)
	local counts = self:countBy(path):toArray()
	local maxReps = counts:max("value")
	return maxReps and counts:where("value", maxReps.value):pluck("key") or self
end

-- Seperates collection into two collections based on if they satisfy a given closure or not
function Collect:partition(closure: Function)
	local passes, fails = Collect(), Collect()
	lib.iterate(self, function(key, value)
		local success = closure(value, key)
		lib.append(success and passes._table or fails._table, key, value, self._retainKeys)
	end)
	return passes, fails
end

-- Returns a random value, key pair
function Collect:random(random: Random?|number?)
	random = lib.cleanRandom(random)
	if self._isArray then
		local index = random:NextInteger(1, self:count())
		return self._table[index], index
	else
		local key, value = next(table)
		return value, key
	end
end

-- Reduces collection to a single value, passing the result of each interaction into the
-- subsequent interaction
function Collect:reduce(closure: Function, carry: any?)
	carry = carry or Collect()
	lib.iterate(self, function(key, value)
		carry = closure(carry, value, key)
	end)
	return carry
end

-- Returns sum of all elements in the collection
function Collect:sum(path: string|Function?)
	return self:reduce(function(sum, value, key)
		value = lib.pathOrClosure(value, key, path)
		lib.assertType(value, "number")
		return sum + value
	end, 0)
end

-- Returns a value, key pair of an entry iff it is the only entry that satisfies a given closure
function Collect:sole(closure: Function)
	local soleValue, soleKey = nil, nil
	for key, value in pairs(self._table) do
		if closure(value, key) then
			if soleValue then return end
			soleValue, soleKey = value, key
		end
	end
	return soleValue, soleKey
end

-- Unpacks the collection, returning the values as a tuple
function Collect:unpack()
	if self._isArray then
		return table.unpack(self._table)
	else
		return self:values():unpack()
	end
end

-- Returns a random value, key pair based on weighted odds
function Collect:weightedRandom(path: string?, random: Random?|number?)
	path, random = lib.cleanArguments({path, random}, {
		{"string", true},
		{"string", false},
		{false, false},
	})
	random = lib.cleanRandom(random)

	local totalWeight = self:sum(path)
	local rand = random:NextInteger(1, totalWeight)
	for key, value in pairs(self._table) do
		local weight = followPath(value, path)
		if rand <= weight then
			return value, key
		end
		rand -= weight
	end
end


----------------------------------------------------------------------------------------------------
----// Iterators \\---------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Collect:forEach(closure: Function, ...)
	local args = {...}
	return lib.iterate(self, function(key, value)
		if #args == 0 then
			closure(value, key)
		else
			closure(value, unpack(args))
		end
	end)
end

function Collect:forEachAsync(closure: Function, ...)
	task.spawn(function(...)
		self:forEach(closure, ...)
	end)
end


----------------------------------------------------------------------------------------------------
----// Updates \\-----------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Insert a value into an array collection
function Collect:insert(position: number?, value: any)
	assert(self._isArray, "Cannot insert into a dictonary. For dictonaries, use the __newindex metamethod")
	if value == nil then
		value = position
		position = self:count() + 1
	end
	lib.assertType(position, "number")

	table.insert(self._table, position, value)
	return self
end

-- Merge given table into this collection
-- Called internally for the __add metamethod
function Collect:merge(tbl: table|Collect)
	if getmetatable(tbl) == Collect then
		tbl = tbl:get()
	end
	self._isArray = self._isArray and lib.isArray(tbl)
	self._retainKeys = self._retainKeys or not self._isArray
	lib.iterate(tbl, self._isArray, function(key, value)
		lib.append(self._table, key, value, self._retainKeys)
	end)
	return self
end

-- Removes and returns the last item from the (array) collection
function Collect:pop()
	assert(self._isArray, "Cannot pop from dictonary table")
	local value = self._table[#self._table]
	table.remove(self._table, #self._table)
	return value
end

-- Removes and returns the first few entries from the array collection
-- If an amount is given, then a Collection is returned. Otherwise, the first value is returned
function Collect:shift(amount: number?)
	assert(self._isArray, "Cannot shift a dictonary")
	local taken = {}
	for i = 1, (amount or 1) do
		table.insert(taken, self._table[1])
		table.remove(self._table, 1)
	end
	return amount == nil and taken[1] or Collect(taken)
end

function Collect:update(updates: table, value: any?)
	if typeof(updates) ~= "table" then
		updates = {[updates] = value}
	end

	for path, newValue in pairs(updates) do
		local parentPath = string.split(path, ".")
		local property = parentPath[#parentPath]
		parentPath = table.concat(parentPath, ".", 1, #parentPath - 1)

		lib.iterate(self, function(key, element)
			local parent = followPath(element, parentPath)
			local value = followPath(parent, property)
			if parent == nil or value == nil then return end

			local parentIsInstance = (typeof(parent) == "Instance")
			local setValue = newValue
			if typeof(setValue) == "table" then
				setValue = lib.deepCopy(setValue)
			elseif typeof(setValue) == "function" then
				setValue = setValue(value, element, key)
			end
			
			if property == "" then
				self._table[key] = setValue
			elseif parentIsInstance and parent:FindFirstChild(property) then
				lib.assertType(setValue, "Instance")
				value:Destroy()
				setValue:Clone().Parent = parent
			elseif parentIsInstance and parent:GetAttribute(property) ~= nil then
				parent:SetAttribute(property, setValue)
			else
				parent[property] = setValue
			end
		end)
	end

	return self
end

----------------------------------------------------------------------------------------------------
----// Metamethods \\-------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function Collect:__index(key)
	local value = self._table[key]
	if value == nil and self._isArray and typeof(key) == "number" and key < 0 then
		value = self._table[self:count() + key + 1] -- negative array indexing
	end
	return value == nil and Collect[key] or value
end

function Collect:__newindex(key, value)
	if self._table[key] == nil and self._isArray and typeof(key) == "number" and key < 0 then
		key = self:count() + key + 1 -- negative array indexing
	end
	self._table[key] = value
	self._isArray = typeof(key) == "number" and lib.isArray(self._table)
	self._retainKeys = self._retainKeys or not self._isArray
end

function Collect:__len()
	return self:count()
end

function Collect.__add(left, right)
	assert(typeof(left) == "table" and typeof(right) == "table", "Cannot add a non-table to a Collect object")
	if getmetatable(left) == Collect then
		return left:merge(right)
	else
		return Collect(left):merge(right):get()
	end
end

function Collect.__sub(left, right)
	assert(typeof(left) == "table" and typeof(right) == "table", "Cannot subtract a non-table to a Collect object")
	if getmetatable(left) == Collect then
		return left:whereNotIn(right)
	else
		return Collect(left):whereNotIn(right):get()
	end
end

function Collect.__mul(left, right)
	assert(typeof(left) == "table" and typeof(right) == "table", "Cannot multiply a non-table to a Collect object")
	if getmetatable(left) == Collect then
		return left:cartesianProduct(right)
	else
		return Collect(left):cartesianProduct(right):get()
	end
end

function Collect.__eq(left, right)
	return Collect(left):equals(right)
end

--//
return setmetatable(Collect, {
	__call = function(self, ...)
		return Collect.new(...)
	end,
})