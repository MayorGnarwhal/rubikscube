local Util = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local Config = require(Configurations.Config)


--// Methods
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

--//
return Util