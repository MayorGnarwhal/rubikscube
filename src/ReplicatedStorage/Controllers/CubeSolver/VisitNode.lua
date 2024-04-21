--// Dependencies
local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Heuristics = require(Configurations.Heuristics)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)

local AppendToQueue = Services.Queue.Append


--// VisitNode functions
-- a node is a state of the rubiks cube
-- visit all children (created by applying each permitted move)
-- if a child matches the targetMap, then return the path of moves to reach that child
-- otherwise, return the minimum depth of a child -- used for iterative deepening
return function(queueKey, node, targetMap, threshold)
	local nextThresh = math.huge
	
	for i, moveName in ipairs(Config.ScrambleMoves) do
		local newCubeMap = Util.DeepCopy(node.Cube)
		local newCube = RubiksCube.fromMap(newCubeMap)
		newCube:Move(Moves[moveName])

		local cost = Heuristics.Cost(node, moveName, newCube.Map, targetMap)
		
		local newPathCost = node.Cost + cost
		local newNode

		if newPathCost <= threshold then
			local newPath = table.clone(node.Path)
			table.insert(newPath, moveName)
			
			local distance = Heuristics.Distance(newCube.Map, targetMap)
			if distance == 0 then
				return newPath
			end
			
			-- use a bindable event instead of requiring the queue module
			-- because parallel processes have different module pointers
			AppendToQueue:Fire(queueKey, {
				Cube = newCube.Map,
				Depth = node.Depth + 1,
				Cost = newPathCost,
				Path = newPath,
			})
		else
			nextThresh = math.min(newPathCost, nextThresh)
		end
	end
	
	return nextThresh
end