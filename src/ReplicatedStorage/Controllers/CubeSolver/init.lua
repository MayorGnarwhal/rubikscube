local CubeSolver = {}

--// Dependencies
local RunService = game:GetService("RunService")

local Services = game.ReplicatedStorage.Services
local ParallelScheduler = require(Services.ParallelScheduler)
local RelativeMoves = require(Services.RelativeMoves)
local Instructions = require(Services.Instructions)
local RubiksCube = require(Services.RubiksCube)
local Queue = require(Services.Queue)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)
local Heuristics = require(Configurations.Heuristics)
local Algorithms = require(Configurations.Algorithms)
local TargetMaps = require(Configurations.TargetMaps)
local Palettes = require(Configurations.Palettes)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)

--// Variables
local Scheduler = ParallelScheduler:LoadModule(script.VisitNode)
local DEBUG = RunService:IsStudio() and false

export type Instruction = Instructions.Instruction
export type InstructionList = {Instruction}

--CubeSolver.SolveOrder = {
--	"WhiteCross",
--	"FirstLayer",
--	"SecondLayer",
--	"YellowCross",
--	"OneAlgorithmOLL",
--	"SolveCorners",
--	"FinalEdges",
--}

CubeSolver.SolveOrder = {
	"Daisy",
	"DaisyToCross",
	"FirstLayer_new",
	
	"SecondLayer",
	"YellowCross",
	"OneAlgorithmOLL",
	"SolveCorners",
	"FinalEdges",
}

--// Helper functions
local function applyMoves(toCube, moves)
	for i, moveName in ipairs(moves) do
		toCube:Move(Moves[moveName])
	end
end

local function Search(cube: table, targetMap: table, threshold)
	local queue = Queue.new()
	queue:Append({
		Cube = cube,
		Depth = 0,
		Cost = 0,
		Path = {},
	})

	local nextThresh = math.huge
	local finalPath

	while not queue:IsEmpty() do
		local chunk = queue:PopMany(#queue)

		for i, node in ipairs(chunk) do
			Scheduler:ScheduleWork(queue:GetKey(), node, targetMap, threshold)
		end

		local results = Scheduler:Work()
		
		for i, result in ipairs(results) do
			if typeof(result) == "table" then
				-- goal found
				if finalPath then
					if #finalPath > #result then
						finalPath = result
					end
				else
					finalPath = result
				end
			else
				nextThresh = math.min(nextThresh, result)
			end
		end

		-- this process will take a long time
		-- wait so that program does not freeze/crash
		RunService.Heartbeat:Wait()
	end

	queue:Destroy()

	return finalPath or nextThresh
end

local function SearchPartial(cube: RubiksCube, targetMap: table): table
	local start = os.clock()

	local path = {}
	local iteration = 0
	local threshold = Heuristics.Distance(cube.Map, targetMap)

	if DEBUG then
		print(("Current distance: %.5f"):format(threshold))
	end

	while threshold ~= 0 do
		iteration += 1

		local result = Search(cube.Map, targetMap, threshold)
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
function CubeSolver.Daisy(cube: RubiksCube, instructions: InstructionList)
	if Heuristics.Distance(cube.Map, TargetMaps.WhiteCross) == 0 then return end
	
	local moves = SearchPartial(cube, TargetMaps.Daisy)
	applyMoves(cube, moves)

	instructions:Insert({
		Description = "Create a Daisy pattern by moving all White edge pieces to the Yellow center.",
		Stage = "Cross",
		FrontFace = "Back",
		TopFace = "Bottom",
		Algorithm = moves,
	})
end

function CubeSolver.DaisyToCross(cube: RubiksCube, instructions: InstructionList)
	if Heuristics.Distance(cube.Map, TargetMaps.WhiteCross) == 0 then return end
	
	local bottomIndex = table.find(TargetMaps.FaceOrder, "Bottom")
	
	for i, sideName in ipairs({"Back", "Left", "Front", "Right"}) do
		local targetMap = TargetMaps.CreateEmpty(3)
		
		local sideIndex = table.find(TargetMaps.FaceOrder, sideName)
		local coord = Algorithms.F2L.BottomEdgeCoordinates[sideName]
		
		targetMap[bottomIndex][coord.X][coord.Y] = "Top"
		targetMap[sideIndex][2][3] = sideName
		
		local moves = SearchPartial(cube, targetMap)
		table.insert(moves, RelativeMoves.TranslateMove("F2", sideName, "Bottom"))
		
		applyMoves(cube, moves)

		instructions:Insert({
			Description = ("Insert the White and %s edge piece into the white cross"):format(FaceColorMap[sideName]),
			Stage = "Cross",
			FrontFace = sideName,
			TopFace = "Bottom",
			Algorithm = moves,
		})
	end
end

local function InsertNextCorner(cube: RubiksCube, instructions: InstructionList)
	local faceName, cornerColors = Algorithms.FirstLayer.FindCornerInBottomLayer(cube.Map)
	if not faceName then return end
	
	local cornerCoordinates = Algorithms.FirstLayer.CornerCoordinates
	
	local color1 = cornerColors[1]
	local color2 = cornerColors[2]
	if not cornerCoordinates[color1] then
		color1, color2 = color2, color1
	end
	
	local topCoord = cornerCoordinates[color1][color2]
	
	local targetMap = Util.DeepCopy(TargetMaps.WhiteCross)
	
	local topIndex = table.find(TargetMaps.FaceOrder, "Top")
	local corner1Index = table.find(TargetMaps.FaceOrder, color1)
	local corner2Index = table.find(TargetMaps.FaceOrder, color2)
	
	local dir = topCoord.X == topCoord.Y and 1 or -1
	
	targetMap[topIndex][topCoord.X][topCoord.Y] = "Top"
	targetMap[corner1Index][2 + dir][1] = color1
	targetMap[corner2Index][2 - dir][1] = color2
	
	local moves = SearchPartial(cube, targetMap)
	applyMoves(cube, moves)
	
	instructions:Insert({
		Description = ("Insert the White, %s, and %s corner piece")
			:format(FaceColorMap[cornerColors[1]], FaceColorMap[cornerColors[2]]),
		Stage = "First Layer",
		FrontFace = faceName,
		TopFace = "Top",
		Algorithm = moves,
	})
	
	return true
end

local function MoveUnsolvedCornerFromTop(cube: RubiksCube, instructions: InstructionList)
	local faceName, cornerColors, algorithm = Algorithms.FirstLayer.FindCornerInTopLayer(cube.Map)
	if not faceName then return end
	
	local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, faceName, "Top")
	applyMoves(cube, relativeMoves)

	instructions:Insert({
		Description = ("The White, %s, and %s corner is in the top layer, but not solved. Move it to the bottom row")
			:format(FaceColorMap[cornerColors[1]], FaceColorMap[cornerColors[2]]),
		Stage = "First Layer",
		FrontFace = faceName,
		TopFace = "Top",
		Algorithm = relativeMoves,
	})
	
	return true
end

local function MoveUnsolvedCornerFromBottom(cube: RubiksCube, instructions: InstructionList)
	local faceName, algorithm, orientMove, cornerColors = Algorithms.FirstLayer.FindCornerOnBottomFace(cube.Map)
	if not faceName then return end
	
	if orientMove then
		instructions:Insert({
			Description = ("Align a White corner under an unsolved corner to move to bottom layer"),
				--:format(FaceColorMap[cornerColors[1]], FaceColorMap[cornerColors[2]]),
			Stage = "First Layer",
			FrontFace = faceName,
			TopFace = "Top",
			Algorithm = {orientMove},
		})
		
		applyMoves(cube, {orientMove})
	end
	
	local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, faceName, "Top")
	applyMoves(cube, relativeMoves)
	
	instructions:Insert({
		Description = ("Move the White corner out of the bottom face"),
			--:format(cornerColors[1], cornerColors[2]),
		Stage = "First Layer",
		FrontFace = faceName,
		TopFace = "Top",
		Algorithm = relativeMoves,
	})

	return true
end

function CubeSolver.FirstLayer_new(cube: RubiksCube, instructions: InstructionList)
	local success = true
	while success do
		success = InsertNextCorner(cube, instructions) or MoveUnsolvedCornerFromTop(cube, instructions) or 
			MoveUnsolvedCornerFromBottom(cube, instructions)
	end
end



function CubeSolver.WhiteCross(cube: RubiksCube, instructions: InstructionList)
	local moves = SearchPartial(cube, TargetMaps.WhiteCross)
	applyMoves(cube, moves)
	
	instructions:Insert({
		Description = "Solve the white cross",
		Stage = "Cross",
		FrontFace = "Back",
		TopFace = "Top",
		Algorithm = moves,
	})
end

function CubeSolver.FirstLayer(cube: RubiksCube, instructions: InstructionList)
	local cumulativeMap = TargetMaps.WhiteCorners[1]

	for i, cornerMap in ipairs(TargetMaps.WhiteCorners) do
		cumulativeMap = TargetMaps.Merge(cumulativeMap, cornerMap)

		local moves = SearchPartial(cube, cumulativeMap)
		if #moves > 0 then
			applyMoves(cube, moves)

			instructions:Insert({
				Description = ("Solve corner %s"):format(i),
				Stage = "First Layer",
				FrontFace = "Back",
				TopFace = "Top",
				Algorithm = moves,
			})
		end
	end
end

local function InsertNextEdge(cube: RubiksCube, instructions: InstructionList)
	local faceName, frontCellName, bottomCellName = Algorithms.F2L.FindEdgeInBottomLayer(cube.Map)
	if not faceName then
		-- no edge piece in bottom layer to solve
		-- edge piece is unsolved in second layer
		return nil
	end
	
	local targetMap = Util.DeepCopy(TargetMaps.FirstLayer)
	
	local coords = Algorithms.F2L.BottomEdgeCoordinates[frontCellName]
	local face = targetMap[table.find(TargetMaps.FaceOrder, frontCellName)]
	local bottomFace = targetMap[table.find(TargetMaps.FaceOrder, "Bottom")]

	face[2][3] = frontCellName
	bottomFace[coords.X][coords.Y] = bottomCellName

	-- orientation will take at most 1 move
	local orientMove = SearchPartial(cube, targetMap)[1]
	if orientMove then
		applyMoves(cube, {orientMove})
		
		instructions:Insert({
			Description = ("Orient the %s and %s edge piece over the %s center for insertion.")
				:format(FaceColorMap[frontCellName], FaceColorMap[bottomCellName], FaceColorMap[frontCellName]),
			Stage = "F2L",
			FrontFace = frontCellName,
			TopFace = "Bottom",
			Algorithm = {orientMove},
		})
	end

	local frontIndex = table.find(Algorithms.F2L.LayerSideOrder, frontCellName)
	local indexLeft = (frontIndex - 2) % 4 + 1

	local insertLeft = (Algorithms.F2L.LayerSideOrder[indexLeft] == bottomCellName)
	local algorithm = insertLeft and Algorithms.F2L.Algorithms.EdgeInsertLeft or Algorithms.F2L.Algorithms.EdgeInsertRight

	local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, frontCellName, "Bottom")
	applyMoves(cube, relativeMoves)

	instructions:Insert({
		Description = ("Insert the %s and %s edge piece %s.")
			:format(FaceColorMap[frontCellName], FaceColorMap[bottomCellName], insertLeft and "left" or "right"),
		Stage = "F2L",
		FrontFace = frontCellName,
		TopFace = "Bottom",
		Algorithm = relativeMoves,
	})
	
	return true
end

local function MoveUnsolvedEdgeToBottom(cube: RubiksCube, instructions: InstructionList)
	local faceName, frontCellName, rightCellName = Algorithms.F2L.FindUnsolvedEdgeInSecondLayer(cube.Map)

	if faceName then
		local relativeMoves = RelativeMoves.TranslateAlgorithm(Algorithms.F2L.Algorithms.EdgeInsertRight, faceName, "Bottom")
		applyMoves(cube, relativeMoves)
		
		local description = ("There is no non-yellow edge in the top layer. Move the %s and %s edge to the top layer")
			:format(FaceColorMap[frontCellName], FaceColorMap[rightCellName])
		
		instructions:Insert({
			Description = description,
			Stage = "F2L",
			FrontFace = faceName,
			TopFace = "Bottom",
			Algorithm = relativeMoves,
		})
	end
	
	return true
end

function CubeSolver.SecondLayer(cube: RubiksCube, instructions: InstructionList)
	while Heuristics.Distance(cube.Map, TargetMaps.FirstTwoLayers) > 0 do
		local success = InsertNextEdge(cube, instructions) or MoveUnsolvedEdgeToBottom(cube, instructions)
	end
end

function CubeSolver.YellowCross(cube: RubiksCube, instructions: InstructionList)
	while Heuristics.Distance(cube.Map, TargetMaps.YellowCross) > 0 do
		local currentFrontFace = instructions:CurrentFrontFace()
		local algorithm, frontFace, description = Algorithms.OLL.YellowCross(cube.Map)
		
		local useFrontFace = frontFace or currentFrontFace
		local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, useFrontFace, "Bottom")
		
		applyMoves(cube, relativeMoves)
		
		instructions:Insert({
			Description = description,
			Stage = "OLL",
			FrontFace = useFrontFace,
			TopFace = "Bottom",
			Algorithm = relativeMoves,
		})
	end
end

function CubeSolver.OneAlgorithmOLL(cube: RubiksCube, instructions: InstructionList)
	while Heuristics.Distance(cube.Map, TargetMaps.OrientedLastLayer) > 0 do
		local algorithm, frontFace, description = Algorithms.OLL.OneAlgorithmOrientation(cube.Map)

		local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, frontFace, "Bottom")
		applyMoves(cube, relativeMoves)
		
		instructions:Insert({
			Description = description,
			Stage = "OLL",
			FrontFace = frontFace,
			TopFace = "Bottom",
			Algorithm = relativeMoves,
		})
	end
end

function CubeSolver.SolveCorners(cube: RubiksCube, instructions: InstructionList)
	while not Algorithms.PLL.CornersSolved(cube.Map) do
		local frontFace, headlightCellName = Algorithms.PLL.FindHeadlights(cube.Map)
		local useFrontFace = frontFace or instructions:CurrentFrontFace()

		local algorithm = Algorithms.PLL.Algorithms.Headlights
		local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, useFrontFace, "Bottom")
		
		local description
		if frontFace then
			description = ("Put the %s headlights to the back face."):format(FaceColorMap[headlightCellName])
		else
			description = "There are no headlights. Apply the algorithm to create headlights."
		end
		
		instructions:Insert({
			Description = "Solve the corners. " .. description,
			Stage = "PLL",
			FrontFace = useFrontFace,
			TopFace = "Bottom",
			Algorithm = relativeMoves,
		})
		
		applyMoves(cube, relativeMoves)
	end

	local orientMove = SearchPartial(cube, TargetMaps.SolvedCorners)[1]
	if orientMove then
		applyMoves(cube, {orientMove})
		instructions:Insert({
			Description = "Rotate the top face so the corners are in the correct positions.",
			Stage = "PLL",
			FrontFace = instructions:CurrentFrontFace(),
			TopFace = "Bottom",
			Algorithm = {orientMove},
		})
	end
end

function CubeSolver.FinalEdges(cube: RubiksCube, instructions: InstructionList)
	while Heuristics.Distance(cube.Map, TargetMaps.Complete) > 0 do
		local algorithm, frontFace, rotationType = Algorithms.PLL.SolveFinalEdges(cube.Map)
		local useFrontFace = frontFace or instructions:CurrentFrontFace()

		local relativeMoves = RelativeMoves.TranslateAlgorithm(algorithm, useFrontFace, "Bottom")
		applyMoves(cube, relativeMoves)
		
		local description
		if frontFace then
			description = ("There is a %s 3-cycle. Put the solved side on the back and apply the %s algorithm"):format(rotationType, rotationType)
		else
			description = ("There is no cycle. Apply the %s algorithm to create a cycle"):format(rotationType)
		end
		
		instructions:Insert({
			Description = description,
			Stage = "PLL",
			FrontFace = useFrontFace,
			TopFace = "Bottom",
			Algorithm = relativeMoves,
		})
	end
end


function CubeSolver.Solve(cube: RubiksCube): InstructionList
	cube:Orient(Enum.NormalId.Top)
	
	--local copyCubeMap = Util.DeepCopy(cube.Map)
	--local dummyCube = RubiksCube.fromMap(copyCubeMap)
	local dummyCube = cube
	
	local start = os.clock()
	local instructions = Instructions.new()
	
	for i, solveStage in ipairs(CubeSolver.SolveOrder) do
		local handler = CubeSolver[solveStage]
		handler(cube, instructions)
	end
	
	if DEBUG then
		warn(("Time to Solve: %.5f"):format(os.clock() - start))
		print(instructions)
	end
	
	return instructions
end

function CubeSolver.SolveStage(cube: RubiksCube, stageName: string, instructions: InstructionList): InstructionList
	assert(table.find(CubeSolver.SolveOrder, stageName), "Invalid solve stage: " .. stageName)
	
	if RunService:IsClient() then
		local instructions = script.SolveStage:InvokeServer(cube, stageName, instructions)
		return Instructions.fromList(instructions)
	end
	
	if getmetatable(instructions) ~= Instructions then
		instructions = Instructions.fromList(instructions)
	end
	
	local handler = CubeSolver[stageName]
	handler(cube, instructions)
	
	return instructions:Get()
end

if RunService:IsServer() then
	script.SolveStage.OnServerInvoke = function(player, cube: table, stageName: string, instructions: {})
		cube = RubiksCube.fromMap(cube)
		return CubeSolver.SolveStage(cube, stageName, instructions)
	end
end

--//
return CubeSolver