local CubeSolver = {}

--// Dependencies
local RunService = game:GetService("RunService")

--local Search = require(script.Search)
--local Schedule = require(script.Search.Scheduler)

--local Heuristics = require(script.Heuristics)
local TargetMaps = require(script.TargetMaps)
local TreeQueue = require(script.TreeQueue)

local Services = game.ReplicatedStorage.Services
local ParallelScheduler = require(Services.ParallelScheduler)
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Heuristics = require(Configurations.Heuristics)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)


--// Variables
local Scheduler = ParallelScheduler:LoadModule(script.VisitNode)
local DEBUG = true


--// Helper functions
local function Search(cube: table, targetMap: table, threshold, iter)
	TreeQueue.Clear()
	TreeQueue.Append(cube, 0, 0, {})
	
	local nextThresh = math.huge
	local iter = 1
	
	local scheduleStatus = Scheduler:GetStatus()
	local chunkSize = scheduleStatus.MaxWorkers * 30 
	
	while not TreeQueue.IsEmpty() do
		local chunk = TreeQueue.PopMany(TreeQueue.Size())
		
		for i, node in ipairs(chunk) do
			Scheduler:ScheduleWork(node, targetMap, threshold)
		end
		
		local results = Scheduler:Work()
		for i, result in ipairs(results) do
			if typeof(result) == "table" then
				-- goal found
				return result
			else
				nextThresh = math.min(nextThresh, result)
			end
		end
		
		iter += 1
		-- this process will take a long time
		-- wait so that program does not freeze/crash
		if iter % 10 == 0 then
			RunService.Heartbeat:Wait()
		end
	end
	
	return nextThresh
end

local function SearchPartial(cube: RubiksCube, targetMep: table): table
	local start = os.clock()

	cube:Orient(Enum.NormalId.Top)

	local path = {}
	local iteration = 0

	local targetMap = TargetMaps.SmartWhiteCross
	local threshold = Heuristics.Distance(cube.Map, targetMap)
	
	if DEBUG then
		print(("Current distance: %.5f"):format(threshold))
	end

	while threshold ~= 0 do
		iteration += 1
		table.clear(path)
		RunService.Heartbeat:Wait()

		local result = Search(cube.Map, targetMap, threshold, iteration)
		if typeof(result) == "table" then
			path = result
			break
		else
			threshold = result
		end
		
		if DEBUG then
			print(("i: %s // d: %.5f // t: %.3f"):format(iteration, threshold, os.clock() - start))
		end
	end
	
	return path
end


--// Methods
function CubeSolver.WhiteCross(cube: RubiksCube): table
	return SearchPartial(cube, TargetMaps.WhiteCross)
end

function CubeSolver.Solve(cube: RubiksCube): table
	local start = os.clock()
	
	local solve = {}
	
	local whiteCrossMoves = CubeSolver.WhiteCross(cube)
	table.insert(solve, whiteCrossMoves)
	
	local path = Util.Flatten(solve)
	
	if DEBUG then
		warn("Solve:", unpack(path))
		warn(("Time to Solve: %.5f"):format(os.clock() - start))
	end

	for i, moveName in ipairs(path) do
		cube:Move(Moves[moveName])
	end
end

--//
return CubeSolver