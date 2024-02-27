local CubeController = {}

--// Dependencies
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Controllers = game.ReplicatedStorage.Controllers
local ScrambleList = require(Controllers.Interface.ScrambleList)
local CubeSolver = require(Controllers.CubeSolver)
local CubeMap = require(Controllers.Interface.CubeMap)
local Timer = require(Controllers.Interface.Timer)

local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Config = require(Configurations.Config)

local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Variables
local Cube

local DragConnect
local StateConnect
local SolveBeganConnect
local SolveEndedConnect


--// Helper function
local function FrontFace(): Enum.NormalId
	return Util.GetNormalId(Camera.CFrame.LookVector)
end


--// Methods
function CubeController.CreateCube(dimensions: number)
	if Cube then
		Cube:Destroy()
		StateConnect:Disconnect()
		SolveBeganConnect:Disconnect()
		SolveEndedConnect:Disconnect()
	end
	
	Cube = RubiksCube.new(dimensions)
	local cubeModel = Cube:GenerateCube3D(5)
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = cubeModel.PrimaryPart
	
	local size = cubeModel:GetExtentsSize()
	local maxSize = math.max(size.X, size.Y, size.Z)
	LocalPlayer.CameraMinZoomDistance = 1.5 * maxSize
	LocalPlayer.CameraMaxZoomDistance = 2.5 * maxSize
	
	CubeMap.Populate(dimensions)
	CubeMap.ApplyPalette(Cube.Map)
	
	StateConnect = Cube:GetStateChangedSignal():Connect(function()
		CubeMap.ApplyPalette(Cube.Map)
	end)
	
	SolveBeganConnect = Cube:GetSolveBeganSignal():Connect(function()
		Timer.Start()
		ScrambleList.Hide()
	end)
	
	SolveEndedConnect = Cube:GetSolveEndedSignal():Connect(function(solved: boolean, timeToSolve, numTurns)
		Timer.Stop()
		if solved then
			Timer.Blink()
			Timer.SetTime(timeToSolve)
		else
			Timer.StopBlinking()
			Timer.SetTime(0)
		end
	end)
end

function CubeController.Scramble()
	local moves = Cube:Scramble()
	if moves then
		print("Scramble:", unpack(moves))
		ScrambleList.Show(moves)
	end
end


--// Drag inputs
local function dragBegan()
	local targetPart = Mouse.Target
	if not (Cube and targetPart and targetPart:HasTag("RubiksHitbox")) then return end
	
	local cublet = targetPart:FindFirstAncestorWhichIsA("Model")
	
	local GrabStart = Mouse.Hit.Position
	local cell = Cube:GetCell(Mouse.Hit.Position)
	local faceId = Mouse.TargetSurface

	--print(cell)

	DragConnect = RunService.Heartbeat:Connect(function()
		local currentPos = Mouse.Hit.Position
		if (GrabStart - currentPos).Magnitude >= Config.DragThreshold then
			DragConnect:Disconnect()

			local directionId
			local minDistance = math.huge
			local ray = Ray.new(Vector3.zero, (currentPos - GrabStart).Unit)

			for i, normalId in pairs(Enum.NormalId:GetEnumItems()) do
				local distance = ray:Distance(Vector3.fromNormalId(normalId)) 
				if distance < minDistance then
					minDistance = distance
					directionId = normalId
				end
			end
			
			Cube:Rotate(cell, faceId, directionId)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragBegan()
	elseif input.KeyCode == Enum.KeyCode.R then
		CubeController.CreateCube(Cube.Dimensions)
	elseif input.KeyCode == Enum.KeyCode.T then
		local normal = Enum.NormalId:GetEnumItems()[math.random(#Enum.NormalId:GetEnumItems())]
		--normal = Enum.NormalId.Left
		print(normal)
		Cube:Orient(normal)
		--Cube:Orient(Enum.NormalId.Back, Enum.NormalId.Front)
	elseif input.KeyCode == Enum.KeyCode.Y then
		Cube:Orient(Enum.NormalId.Top)
	elseif input.KeyCode == Enum.KeyCode.S then
		CubeController.Scramble()
	elseif input.KeyCode == Enum.KeyCode.Q then
		CubeSolver.Solve(Cube)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if DragConnect then
			DragConnect:Disconnect()
		end
	end
end)



--// Setup
CubeController.CreateCube(3)

--//
return CubeController