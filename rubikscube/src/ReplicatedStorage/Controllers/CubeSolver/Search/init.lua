--// Dependencies
local Scheduler = script.Scheduler

local Services = game.ReplicatedStorage.Services
local ParallelScheduler = require(Services.ParallelScheduler)
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Heuristics = require(Configurations.Heuristics)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)


--// Search function
local function Search(cubeMap: table, g, threshold, targetMap, path)
	local distance = Heuristics.Distance(cubeMap, targetMap)
	if distance == 0 then
		-- goal was found
		return 0
	end
	
	print("node", g)

	local f = g + distance
	if f > threshold then
		return f
	end

	local min = math.huge
	local bestMove
	local goalReached

	--[[
	for i, moveName in pairs(Config.SolveMoves) do
		cube:Move(Moves[moveName])

		local cost = Heuristics.Cost(cube.Map, moveName, targetMap)
		local dist, reached = Search(cube, g + cost, threshold, targetMap, path)

		if dist == 0 then
			-- goal was found
			table.insert(path, moveName)
			return dist
		elseif dist < min then
			min = dist
			bestMove = moveName
		end

		local inverse = Moves.Inverse(moveName)
		cube:Move(Moves[inverse])
	end
	--]]

	----[[
	local scheduler = Scheduler.Create:Invoke() -- FR*CK
	--local scheduler = ParallelScheduler:LoadModule(script)
	
	for i, moveName in ipairs(Config.SolveMoves) do
		local newCubeMap = Util.DeepCopy(cubeMap)
		local newCube = RubiksCube.fromMap(newCubeMap)
		newCube:Move(Moves[moveName])
		
		local cost = Heuristics.Cost(newCube.Map, moveName, targetMap)
		
		--Scheduler.ScheduleWork:Fire(newCube, g + cost, threshold, targetMap, path)
		scheduler:ScheduleWork(newCube.Map, g + cost, threshold, targetMap, path)
	end
	
	print("do work", scheduler:GetStatus())
	local distances = scheduler:Work()
	print(distances)
	
	local min = math.huge
	local bestMove
	for i, distance in ipairs(distances) do
		local moveName = Config.SolveMoves[i]
		if distance == 0 then
			-- goal was found
			table.insert(path, moveName)
			return distance
		elseif distance < min then
			min = distance
			bestMove = moveName
		end
	end
	
	scheduler:Destroy()
	
	--if true then return 0 end
	--]]

	-- this will take a long time, so we need to tell the game
	-- that the script is still awake and dont crash us
	task.wait()

	return min
end

return Search