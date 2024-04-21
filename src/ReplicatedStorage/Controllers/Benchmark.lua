local Benchmark = {}

--// Dependencies
local Controllers = game.ReplicatedStorage.Controllers
local CubeController = require(Controllers.CubeController)
local CubeSolver = require(Controllers.CubeSolver)

local Services = game.ReplicatedStorage.Services
local Util = require(Services.Util)


--// Methods
function Benchmark.Run(numIterations: number)
	CubeController.SetMovementLock(true)
	
	local cube = CubeController.CurrentCube()
	cube.RotationSpeed = 0
	
	local stat = {
		Duration = {
			Sum = 0,
			Results = {},
			Min = math.huge,
			Max = -1,
		},
		Moves = {
			Sum = 0,
			Results = {},
			Min = math.huge,
			Max = -1,
		},
	}
	
	local results = {
		["Cross"] = Util.DeepCopy(stat),
		["First Layer"] = Util.DeepCopy(stat),
		["F2L"] = Util.DeepCopy(stat),
		["OLL"] = Util.DeepCopy(stat),
		["PLL"] = Util.DeepCopy(stat),
		
		["Total"] = Util.DeepCopy(stat),
	}
	
	for iter = 1, numIterations do
		cube:Scramble()
		repeat task.wait() until not cube.Scrambling

		local start = os.clock()
		local instructions = CubeSolver.Solve(cube)
		
		local duration = os.clock() - start
		local numMoves = 0
		
		local stageMoves = 0
		local lastStage = "Cross"
		local lastStageTick = start
		for i = 1, #instructions do
			local instruction = instructions:GetStep(i)
			numMoves += #instruction.Algorithm
			stageMoves += #instruction.Algorithm

			if instruction.Stage ~= lastStage or i == #instructions then
				local stageDuration = instruction.Timestamp - lastStageTick
				
				print(lastStage)
				local stageResults = results[lastStage]
				
				stageResults.Duration.Sum += stageDuration
				table.insert(stageResults.Duration.Results, stageDuration)
				stageResults.Duration.Min = math.min(stageResults.Duration.Min, stageDuration)
				stageResults.Duration.Max = math.max(stageResults.Duration.Max, stageDuration)
				
				stageResults.Moves.Sum += stageMoves
				table.insert(stageResults.Moves.Results, stageMoves)
				stageResults.Moves.Min = math.min(stageResults.Moves.Min, stageMoves)
				stageResults.Moves.Max = math.max(stageResults.Moves.Max, stageMoves)

				stageMoves = 0
				lastStage = instruction.Stage
				lastStageTick = instruction.Timestamp
			end
		end
		
		local totalResults = results.Total

		totalResults.Duration.Sum += duration
		table.insert(totalResults.Duration.Results, duration)
		totalResults.Duration.Min = math.min(totalResults.Duration.Min, duration)
		totalResults.Duration.Max = math.max(totalResults.Duration.Max, duration)

		totalResults.Moves.Sum += numMoves
		table.insert(totalResults.Moves.Results, numMoves)
		totalResults.Moves.Min = math.min(totalResults.Moves.Min, numMoves)
		totalResults.Moves.Max = math.max(totalResults.Moves.Max, numMoves)

		local m = math.ceil(iter / 2)

		print(("%s: %.5f"):format(iter, duration))
		for stageName, results in pairs(results) do
			warn(("   Stage: %s // %.5f"):format(stageName, results.Duration.Results[#results.Duration.Results]))
			print(("      Avg. Time: %.5f // Med. Time: %.5f // Min Time: %.5f // Max Time: %.5f")
				:format(results.Duration.Sum / iter, results.Duration.Results[m], results.Duration.Min, results.Duration.Max))
			print(("      Avg. Moves: %.2f // Med. Moves: %.2f // Min Moves: %.2f // Max Moves: %.2f")
				:format(results.Moves.Sum / iter, results.Moves.Results[m], results.Moves.Min, results.Moves.Max))
		end
	end
	
	CubeController.SetMovementLock(false)
end

--//
return Benchmark