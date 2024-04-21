local TopBar = {}

--// Dependencies
require(script.Timer)

local TweenService = game:GetService("TweenService")

local Controllers = game.ReplicatedStorage.Controllers
local CubeController = require(Controllers.CubeController)
local InterfaceUtil = require(Controllers.Interface.InterfaceUtil)
local CubePainter = require(Controllers.Interface.CubePainter)

local Services = game.ReplicatedStorage.Services
local Audio = require(Services.Audio)

local Configurations = game.ReplicatedStorage.Configurations
local Pallets = require(Configurations.Palettes)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Content = PlayerGui:WaitForChild("MainGui"):WaitForChild("TopBar")


--// Setup
for i, toggle in ipairs(Content:GetChildren()) do
	if toggle:IsA("TextButton") then
		InterfaceUtil.HoverUnderline(toggle)
	end
end

Content.Scramble.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubeController.Scramble()
end)

Content.Reset.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubeController.CreateCube(3)
end)

Content.Paint.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	
	if CubePainter.IsPainting() then
		CubePainter.Paint()
	else
		CubePainter.OpenPainter()
	end
end)

Content.Camera.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubeController.ResetCamera()
end)


--//
return TopBar