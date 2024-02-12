local CubeController = {}

--// Dependencies
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)

local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)
local Config = require(Configurations.Config)

local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Interface = PlayerGui:WaitForChild("MainGui"):WaitForChild("CubeMap")

--// Variables
local CurrentCube
local DragConnect
local StateConnect


--// Methods
function CubeController.CreateCube(dimensions: number)
	if CurrentCube then
		CurrentCube:Destroy()
		StateConnect:Disconnect()
	end
	
	CurrentCube = RubiksCube.new(dimensions, 5)
	
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = CurrentCube.CameraSubject
	
	local size = CurrentCube.Cube:GetExtentsSize()
	local maxSize = math.max(size.X, size.Y, size.Z)
	LocalPlayer.CameraMinZoomDistance = 1.5 * maxSize
	LocalPlayer.CameraMaxZoomDistance = 2.5 * maxSize
	
	CubeController.ApplyPalette()
	StateConnect = CurrentCube:GetStateChangedSignal():Connect(CubeController.ApplyPalette)
end

function CubeController.ApplyPalette()
	for side, matrix in pairs(CurrentCube.Map) do
		local container = Interface:FindFirstChild(side).Content

		for y = 1, 3 do
			for x = 1, 3 do
				local num = 3 * (y - 1) + x
				local cell = container:FindFirstChild(num)

				local face = matrix[x][y]
				cell.BackgroundColor3 = Palette.Standard[face]
			end
		end
	end
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
		CubeController.CreateCube(3)
	elseif input.KeyCode == Enum.KeyCode.T then
		if CurrentCube then
			CurrentCube:Shuffle()
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