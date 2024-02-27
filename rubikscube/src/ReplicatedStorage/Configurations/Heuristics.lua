local Heuristics = {}

--// Helper functions
local function getFace(cubeMap, faceName, m)
	--if cubeMap[faceName] then
	--	return cubeMap[faceName]
	--end
	
	for i, matrix in pairs(cubeMap) do
		if matrix[m][m] == faceName then
			return matrix
		end
	end
end

local function SharedTableToTable(St : SharedTable)
	local Table = {}
	for i, v in St do
		v = typeof(v) == "SharedTable" and SharedTableToTable(v) or v
		Table[i] = v
	end
	return Table
end


--// Methods
---- @public
--- calculates the distance of the current cubeMap to the targetMap
-- @return number	distance score within [0, 1). 0 means a perfect match
function Heuristics.Distance(cubeMap: table, targetMap: table): number
	if typeof(cubeMap) == "SharedTable" then
		cubeMap = SharedTableToTable(cubeMap)
	end
	
	if typeof(targetMap) == "SharedTable" then
		targetMap = SharedTableToTable(targetMap)
	end
	
	local n = #next(cubeMap)
	local m = math.ceil(n / 2)
	
	local matches = 0
	local compares = 0
	for i, face in pairs(targetMap) do
		local faceName = face[m][m]
		local matrix = getFace(cubeMap, faceName, m)
		
		for x = 1, n do
			for y = 1, n do
				local cell = face[x][y]
				if cell then
					compares += 1
					if cell == matrix[x][y] then
						matches += 1
					end
				end
			end
		end
	end
	
	local correctness = matches / compares
	local distance = 1 - correctness

	return distance
end

function Heuristics.Cost(cubeMap, moveName, targetMap, oldCubeMap)
	--local oldDistance = Heuristics.Distance(oldCubeMap, targetMap)
	--local newDistance = Heuristics.Distance(cubeMap, targetMap)
	
	--if oldDistance == 0 then
	--	return math.huge
	--else
	--	return newDistance / oldDistance
	--end
	
	return Heuristics.Distance(cubeMap, targetMap)
end

--//
return Heuristics