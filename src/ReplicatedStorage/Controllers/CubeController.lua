local CubeController = {}

--// Dependencies
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Controllers = game.ReplicatedStorage.Controllers
local ScrambleList = require(Controllers.Interface.ScrambleList)
local CubeSolver = require(Controllers.CubeSolver)
local CubeMap = require(Controllers.Interface.CubeMap)
local Timer = require(Controllers.Interface.TopBar.Timer)

local Services = game.ReplicatedStorage.Services
local MouseTarget = require(Services.MouseTarget)
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Algorithms = require(Configurations.Algorithms)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)

local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Variables
local MovementLocked = false
local Dimensions = 3

local MobileDevice = false

local Cube

local DragConnect
local StateConnect
local LockCameraConnect
local SolveBeganConnect
local SolveEndedConnect


--// Helper function
local function FrontFace(): Enum.NormalId
	return Util.GetNormalId(Camera.CFrame.LookVector)
end


--// Methods
function CubeController.CurrentCube()
	return Cube
end

function CubeController.Reset()
	if MovementLocked then return end
	CubeController.CreateCube(Dimensions)
end

function CubeController.CreateCube(dimensions: number)
	Dimensions = dimensions
	
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
	CubeMap.ApplyPalette(Cube.Map, Cube.Palette)
	
	StateConnect = Cube:GetStateChangedSignal():Connect(function()
		CubeMap.ApplyPalette(Cube.Map, Cube.Palette)
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
	if MovementLocked then return end
	
	local moves = Cube:Scramble()
	if moves then
		ScrambleList.Show(moves)
	end
end

function CubeController.SetMovementLock(locked: boolean)
	MovementLocked = locked
end

function CubeController.Move(moveName: string, animLength: number?)
	Cube:Move(Moves[moveName], animLength)
end

function CubeController.LockCamera()
	local lockedCameraCF = Camera.CFrame
	LockCameraConnect = RunService.RenderStepped:Connect(function()
		Camera.CFrame = lockedCameraCF
	end)
end

function CubeController.FreeCamera()
	if LockCameraConnect then
		LockCameraConnect:Disconnect()
		LockCameraConnect = nil
	end
end

function CubeController.ResetCamera()
	local cubeCenter = Cube.Cube.PrimaryPart.Position
	local camDistance = (Camera.CFrame.Position - cubeCenter).Magnitude
	
	TweenService:Create(
		Camera,
		TweenInfo.new(1, Enum.EasingStyle.Sine),
		{CFrame = CFrame.new(cubeCenter + Vector3.new(0, 0, camDistance))}
	):Play()
end


--// Drag inputs
local function dragBegan(onMobile)
	if MovementLocked then return end
	
	local target = MouseTarget.GetFromWhitelist({Cube.Cube.Hitbox})
	if not target then return end
	
	local targetPart = target.Instance
	
	local cublet = targetPart:FindFirstAncestorWhichIsA("Model")
	
	local GrabStart = target.Position
	local cell = Cube:GetCell(GrabStart)
	local faceId = Util.GetNormalId(-target.Normal)
	
	local cameraCF = Camera.CFrame

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
			
			if not MovementLocked then
				Cube:Rotate(cell, faceId, directionId)
			end
		end
	end)
	
	return true
end

local function dragEnded()
	if DragConnect then
		DragConnect:Disconnect()
		DragConnect = nil
	end
end

local function mobileDragBegan()
	local success = dragBegan()
	if success then
		CubeController.LockCamera()
	end
end

local function mobileDragEnded()
	dragEnded()
	CubeController.FreeCamera()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragBegan()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		mobileDragBegan()
	elseif input.KeyCode == Enum.KeyCode.R then
		CubeController.Reset()
	elseif input.KeyCode == Enum.KeyCode.S then
		CubeController.Scramble()
	elseif input.KeyCode == Enum.KeyCode.C then
		CubeController.ResetCamera()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	--if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragEnded()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		mobileDragEnded()
	end
end)


--// Setup
CubeController.CreateCube(3)

--//
return CubeController