local Util = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local Config = require(Configurations.Config)


--// Methods
function Util.RoundToNearest(number, increment)
	increment = increment or 1
	return math.round(number / increment) * increment
end

function Util.RoundVectorToNearest(vector: Vector3, increment): Vector3
	return Vector3.new(
		Util.RoundToNearest(vector.X, increment),
		Util.RoundToNearest(vector.Y, increment),
		Util.RoundToNearest(vector.Z, increment)
	)
end

function Util.GetNormalId(normal: Vector3): Enum.NormalId
	local minDistance = math.huge
	local closestNormalId

	for i, normalId in pairs(Enum.NormalId:GetEnumItems()) do
		local distance = normal.Unit:Dot(Vector3.FromNormalId(normalId))
		if distance < minDistance then
			minDistance = distance
			closestNormalId = normalId
		end
	end

	return closestNormalId
end

function Util.Midpoint(children: {BasePart|Model}): Vector3
	local mid = Vector3.zero
	for i, child in pairs(children) do
		mid += child:GetPivot().Position
	end

	return mid / (#children == 0 and 1 or #children)
end

function Util.FlipArray(tbl: table)
	local n, m = #tbl, #tbl/2
	for i = 1, m do
		tbl[i], tbl[n-i+1] = tbl[n-i+1], tbl[i]
	end
end

--- creates a deep copy of a given table
--- does not copy metatables for efficency
-- @param tbl		table to copy
-- @return table	deep copy of tbl
function Util.DeepCopy(tbl: table)
	if type(tbl) == "table" then
		local copy = {}
		for key, value in pairs(tbl) do
			copy[Util.DeepCopy(key)] = Util.DeepCopy(value)
		end
		return copy
	else
		return tbl
	end
end

function Util.Flatten(tbl2D: table)
	local array = {}
	for i, tbl in ipairs(tbl2D) do
		for j, v in ipairs(tbl) do
			table.insert(array, v)
		end
	end
	return array
end

--- generates a random sequence of cube moves
--- makes sure that no move undos the previous move
-- @param scrambleLength	number of moves to generate
-- @param seed?				seed for random generator
-- @return table	array of move names
function Util.GenerateScramble(scrambleLength: number, seed: number?): table
	local rng = seed and Random.new(seed) or Random.new()
	local scramble = {}

	local lastMove = ""
	while #scramble < scrambleLength do
		local move = Config.ScrambleMoves[rng:NextInteger(1, #Config.ScrambleMoves)]
		if string.sub(move, 1, 1) ~= string.sub(lastMove, 1, 1) then
			table.insert(scramble, move)
			lastMove = move
		end
	end

	return scramble
end

--- formats a move for display
-- @param moveName		raw move name from Moves table
-- @return string	formated move, replacing i counterclockwise indicator with '
function Util.FormatMoveName(moveName: string): string
	return moveName:gsub("i", "'")
end

function Util.FuzzyEq(val1, val2, epsilon)
	local diff = val1 - val2
	return -epsilon <= diff and diff <= epsilon
end

function Util.SplitArray(array, numGroups)
	local split = {}
	for i = 1, numGroups do
		split[i] = {}
	end
	
	for i = 1, #array do
		local group = ((i-1) % numGroups) + 1
		table.insert(split[group], array[i])
	end
	
	return split
end

function Util.ClockTime(s)
	local minutes = math.floor(s / 60)
	s -= (minutes * 60)
	local seconds = math.floor(s)
	s -= seconds
	local milliseconds = math.round(s * 1000)

	return ("%.02d:%.02d:%.03d"):format(minutes, seconds, milliseconds)
end

--//
return Util