local CubeController = {}

--// Dependencies
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Controllers = game.ReplicatedStorage.Controllers
local ScrambleList = require(Controllers.Interface.ScrambleList)
local CubeMap = require(Controllers.Interface.CubeMap)
local Timer = require(Controllers.Interface.Timer)

local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)
local Config = require(Configurations.Config)

local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

--// Variables
local CurrentCube
local DragConnect
local StateConnect
local SolveConnect
local SolveBeganConnect


--// Methods
function CubeController.CreateCube(dimensions: number)
	if CurrentCube then
		CurrentCube:Destroy()
		StateConnect:Disconnect()
		SolveConnect:Disconnect()
		SolveBeganConnect:Disconnect()
		ScrambleList.Hide()
	end
	
	CurrentCube = RubiksCube.new(dimensions, 5)
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = CurrentCube.CameraSubject
	
	local size = CurrentCube.Cube:GetExtentsSize()
	local maxSize = math.max(size.X, size.Y, size.Z)
	LocalPlayer.CameraMinZoomDistance = 1.5 * maxSize
	LocalPlayer.CameraMaxZoomDistance = 2.5 * maxSize
	
	CubeMap.Populate(dimensions)
	CubeMap.ApplyPalette(CurrentCube.Map)
	
	StateConnect = CurrentCube:GetStateChangedSignal():Connect(CubeMap.ApplyPalette)
	SolveBeganConnect = CurrentCube:GetSolveBeganSignal():Connect(function()
		Timer.Start()
		ScrambleList.Hide()
	end)
	SolveConnect = CurrentCube:GetSolvedSignal():Connect(function(solved: boolean, timeToSolve: number, numTurns: number)
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

--- get which which face is the "Front" (facing the camera)
function CubeController.FrontFace(): Enum.NormalId
	return Util.GetNormalId(Camera.CFrame.LookVector)
end


--// Drag inputs
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local targetPart = Mouse.Target
		if CurrentCube and targetPart and targetPart:IsDescendantOf(CurrentCube.Cube) and targetPart:HasTag("Core") then
			local cublet = targetPart:FindFirstAncestorWhichIsA("Model")
			
			local GrabStart = Mouse.Hit.Position
			local cell = CurrentCube:GetCell(targetPart.Position)
			local faceId = Mouse.TargetSurface
			
			--print(cell, faceId.Name)
			
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
					
					CurrentCube:Rotate(cell, faceId, directionId)
				end
			end)
		end
	elseif input.KeyCode == Enum.KeyCode.R then
		CubeController.CreateCube(CurrentCube.Dimensions)
	elseif input.KeyCode == Enum.KeyCode.S then
		if CurrentCube then
			local moves = CurrentCube:Scramble()
			if moves then
				ScrambleList.Show(moves)
			end
		end
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