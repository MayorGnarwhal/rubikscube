--// Dependencies
local AppendToQueue = game.ReplicatedStorage.Controllers.CubeSolver.TreeQueue.Event

local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Heuristics = require(Configurations.Heuristics)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)


--//
return function(node, targetMap, threshold)
	local nextThresh = math.huge
	
	for i, moveName in ipairs(Config.ScrambleMoves) do
		local newCubeMap = Util.DeepCopy(node.Cube)
		local newCube = RubiksCube.fromMap(newCubeMap)
		newCube:Move(Moves[moveName])

		local cost = Heuristics.Cost(newCube.Map, moveName, targetMap, node.Cube)
		local newPathCost = node.Cost + cost
		local newNode

		if newPathCost <= threshold then
			local newPath = table.clone(node.Path)
			table.insert(newPath, moveName)
			
			AppendToQueue:Fire(newCube.Map, node.Depth + 1, newPathCost, newPath)
			
			local distance = Heuristics.Distance(newCube.Map, targetMap)
			if distance == 0 then
				return newPath
			end
		else
			nextThresh = math.min(newPathCost, nextThresh)
		end
	end
	
	return nextThresh
end