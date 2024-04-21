local Heuristics = {}

--// Helper functions
local function getFace(cubeMap, faceName, m)
	for globalFaceName, matrix in pairs(cubeMap) do
		if matrix[m][m] == faceName then
			return matrix, globalFaceName
		end
	end
end


--// Methods
---- @public
--- calculates the distance of the current cubeMap to the targetMap
-- @return number	distance score within [0, 1). 0 means a perfect match
function Heuristics.Distance(cubeMap: table, targetMap: table): number
	local n = #next(cubeMap)
	local m = math.ceil(n / 2)
	
	local matches = 0
	local compares = 0
	for i, face in pairs(targetMap) do
		local faceName = face[m][m]
		local matrix, globalFace = getFace(cubeMap, faceName, m)
		
		for x = 1, n do
			for y = 1, n do
				local cell = face[x][y]
				if cell then
					compares += 1
					if cell == matrix[x][y] then
						matches += 1
					else
						--print("fail to match:", faceName, x, y, "//", globalFace)
					end
				end
			end
		end
	end
	
	local correctness = matches / compares
	local distance = 1 - correctness

	return distance
end

function Heuristics.Cost(node, moveName, cubeMap, targetMap)
	local lastMove = node.Path[#node.Path]
	if lastMove and string.sub(lastMove, 1, 1) == string.sub(moveName, 1, 1) then
		return math.huge
	end
	
	return Heuristics.Distance(cubeMap, targetMap)
end

--//
return Heuristics