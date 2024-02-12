local CubeMap = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local MatrixUtil = require(Services.MatrixUtil)
local Collect = require(Services.Collect)

local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Interface = PlayerGui:WaitForChild("MainGui"):WaitForChild("CubeMap")

--// Variables
local FaceMap = {
	[Enum.NormalId.Top] = 1,
	[Enum.NormalId.Bottom] = 2,
	[Enum.NormalId.Left] = 3,
	[Enum.NormalId.Right] = 4,
	[Enum.NormalId.Front] = 5,
	[Enum.NormalId.Back] = 6,
}

local Map = Collect(Enum.NormalId:GetEnumItems()):mapWithKeys(function(normalId)
	--return normalId.Name, Collect.create(3, {normalId.Name, normalId.Name, normalId.Name}):get()
	return normalId.Name, Collect.create(3, Collect.create(3, FaceMap[normalId]):get()):get()
end):get()

print(Map)


local m = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}

MatrixUtil.Print(m)
MatrixUtil.Rotate(m, math.rad(90))
MatrixUtil.Print(m)

-- https://www.enjoyalgorithms.com/blog/rotate-a-matrix-by-90-degrees-in-an-anticlockwise-direction


--// Methods
function CubeMap.ApplyPalette()
	for side, matrix in pairs(Map) do
		local container = Interface:FindFirstChild(side).Content
		
		for y = 1, 3 do
			for x = 1, 3 do
				local num = 3 * (x - 1) + y
				local cell = container:FindFirstChild(num)
				
				local face = matrix[x][y]
				cell.BackgroundColor3 = Palette.Standard[face]
			end
		end
	end
end

CubeMap.ApplyPalette()

--//
return CubeMap