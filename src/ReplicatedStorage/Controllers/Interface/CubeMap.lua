local CubeMap = {}

--// Dependencies
local Controllers = game.ReplicatedStorage.Controllers
local InterfaceUtil = require(Controllers.Interface.InterfaceUtil)

local Services = game.ReplicatedStorage.Services
local Audio = require(Services.Audio)

local Configurations = game.ReplicatedStorage.Configurations
local Palettes = require(Configurations.Palettes)
local Config = require(Configurations.Config)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Menu = PlayerGui:WaitForChild("MainGui"):WaitForChild("CubeMap")
local Content = Menu:WaitForChild("Content")
local Toggle = Menu:WaitForChild("Toggle")


--// Methods
function CubeMap.Populate(dimensions: number)
	for i, face in pairs(Content:GetChildren()) do
		if not face:IsA("Frame") then continue end
		
		local templateCell = face.Content:FindFirstChildOfClass("Frame"):Clone()
		for j, cell in pairs(face.Content:GetChildren()) do
			if cell:IsA("Frame") then
				cell:Destroy()
			end
		end
		
		for x = 1, dimensions do
			for y = 1, dimensions do
				local cell = templateCell:Clone()
				cell.Name = x .. "_" .. y
				cell.LayoutOrder = 3 * (y - 1) + x
				cell.Parent = face.Content
			end
		end
		
		face.Content.UIGridLayout.CellSize = UDim2.new(1/dimensions, -2, 1/dimensions, -2)
		
		templateCell:Destroy()
	end
end

function CubeMap.ApplyPalette(cubeMap: table, palette: Palettes.Palette?)
	palette = palette or Palettes.Standard
	
	local n = #next(cubeMap)
	
	for side, matrix in pairs(cubeMap) do
		local container = Content:FindFirstChild(side).Content

		for y = 1, n do
			for x = 1, n do
				local cell = container:FindFirstChild(x .. "_" .. y)
				local face = matrix[x][y]
				
				cell.BackgroundColor3 = palette[face] or Config.UnpaintedColor
			end
		end
	end
end


--// Setup
InterfaceUtil.HoverUnderline(Toggle)

Toggle.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	if Content.Visible then
		Content.Visible = false
		Toggle.Title.Text = "Show"
	else
		Content.Visible = true
		Toggle.Title.Text = "Hide"
	end
end)

--//
return CubeMap