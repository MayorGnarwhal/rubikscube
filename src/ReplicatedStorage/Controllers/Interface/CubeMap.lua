local CubeMap = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Display = PlayerGui:WaitForChild("MainGui"):WaitForChild("CubeMap")


--// Methods
function CubeMap.Populate(dimensions: number)
	for i, face in pairs(Display:GetChildren()) do
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

function CubeMap.ApplyPalette(cubeMap: table)
	for side, matrix in pairs(cubeMap) do
		local container = Display:FindFirstChild(side).Content

		for y = 1, 3 do
			for x = 1, 3 do
				local cell = container:FindFirstChild(x .. "_" .. y)
				local face = matrix[x][y]
				
				cell.BackgroundColor3 = Palette.Standard[face]
			end
		end
	end
end

--//
return CubeMap