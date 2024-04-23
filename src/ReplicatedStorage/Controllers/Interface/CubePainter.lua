local CubePainter = {}

--// Dependencies
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local Controllers = game.ReplicatedStorage.Controllers
local CubeController = require(Controllers.CubeController)
local Scenes = require(Controllers.Interface.Scenes)

local Services = game.ReplicatedStorage.Services
local RichTextColor = require(Services.RichTextColor)
local MouseTarget = require(Services.MouseTarget)
local Audio = require(Services.Audio)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local Pallets = require(Configurations.Palettes)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ColorPicker = PlayerGui:WaitForChild("Menus"):WaitForChild("ColorPicker")
local FailMessage = PlayerGui:WaitForChild("Menus"):WaitForChild("PaintFailMessage")
local Toggle = PlayerGui:WaitForChild("MainGui"):WaitForChild("TopBar"):WaitForChild("Paint")

--// Variables
local Painting = false

local Toggles = {}
local CurrentToggle = nil
local ColorKey = nil


--// Helper functions
local function SetToggle(layoutOrder)
	if CurrentToggle then
		Toggles[CurrentToggle].Transparency = 1
	end
	
	local toggle = Toggles[layoutOrder]
	toggle.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
	toggle.Transparency = 0
	
	CurrentToggle = layoutOrder
	ColorKey = toggle.Name
end

local function OnClick()
	if not Painting then return end
	
	local cube = CubeController.CurrentCube()
	if not cube then return end
	
	local cubeFaces = CollectionService:GetTagged("Face")
	local target = MouseTarget.GetFromWhitelist(cubeFaces)
	local hitbox = MouseTarget.GetFromWhitelist({cube.Cube.Hitbox})
	if not (target and hitbox) then return end
	
	local face = target.Instance
	local cell = cube:GetCell(hitbox.Position)
	local faceId = Util.GetNormalId(-hitbox.Normal)
	
	cube:Paint(cell, faceId, faceId, Enum.NormalId[ColorKey])
end

local function PromptPaintFail(reason: string)
	FailMessage.Title.Text = "Failed to paint cube: " .. reason
	FailMessage.Visible = true
end

local function ClosePaintFail()
	FailMessage.Visible = false
end


--// Methods
function CubePainter.OpenPainter()
	Painting = true
	
	Toggle.Title.Text = "Apply Paint"
	
	CubeController.Reset()
	CubeController.SetMovementLock(true)
	CubeController.CurrentCube():StripPaint()
	
	Scenes.ColorPicker()
end

-- apply current paint settings
function CubePainter.Paint()
	local success, err = CubeController.CurrentCube():IsValidPaint()
	if not success then
		local message = RichTextColor.Apply(err)
		PromptPaintFail(message)
		return false
	end
	
	Painting = false
	
	CubeController.SetMovementLock(false)

	Scenes.Default()
	ClosePaintFail()
	Toggle.Title.Text = "Paint Cube"
	
	return true
end

function CubePainter.Cancel()
	Painting = false
	
	CubeController.SetMovementLock(false)
	CubeController.Reset()
	
	Scenes.Default()
	ClosePaintFail()
	Toggle.Title.Text = "Paint Cube"
end

function CubePainter.IsPainting()
	return Painting
end


--// Setup
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		OnClick()
	end
end)

for i, toggle in pairs(ColorPicker:GetChildren()) do
	if toggle:IsA("Frame") then
		local layoutOrder = toggle.LayoutOrder
		
		toggle.Input.MouseButton1Click:Connect(function()
			Audio.Play(Audio.Sounds.GuiClick)
			SetToggle(layoutOrder)
		end)
		
		table.insert(Toggles, layoutOrder, toggle)
	end
end

FailMessage.Repaint.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	ClosePaintFail()
end)

FailMessage.Cancel.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubePainter.Cancel()
end)

SetToggle(1)

--//
return CubePainter