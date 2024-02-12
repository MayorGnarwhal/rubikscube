local RubiksCube = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local Tween = require(Services.Tween)

local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)

--// Variables
local Config = {
	FaceThickness = 0.6,
	FaceBorderSize = 0.4,
	RotateSpeed = 0.2,
}

local AxisMap = {
	[Enum.NormalId.Top] = "Y",
	[Enum.NormalId.Bottom] = "Y",
	[Enum.NormalId.Left] = "X",
	[Enum.NormalId.Right] = "X",
	[Enum.NormalId.Front] = "Z",
	[Enum.NormalId.Back] = "Z",
}

local RotationMap = {
	[Enum.NormalId.Top] = {
		[Enum.NormalId.Top] = Enum.NormalId.Top,
		[Enum.NormalId.Bottom] = Enum.NormalId.Bottom,
		[Enum.NormalId.Left] = Enum.NormalId.Back,
		[Enum.NormalId.Right] = Enum.NormalId.Front,
		[Enum.NormalId.Front] = Enum.NormalId.Left,
		[Enum.NormalId.Back] = Enum.NormalId.Right,
	},
	[Enum.NormalId.Bottom] = {
		[Enum.NormalId.Top] = Enum.NormalId.Top,
		[Enum.NormalId.Bottom] = Enum.NormalId.Bottom,
		[Enum.NormalId.Left] = Enum.NormalId.Front,
		[Enum.NormalId.Right] = Enum.NormalId.Back,
		[Enum.NormalId.Front] = Enum.NormalId.Right,
		[Enum.NormalId.Back] = Enum.NormalId.Left,
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Top] = Enum.NormalId.Front,
		[Enum.NormalId.Bottom] = Enum.NormalId.Back,
		[Enum.NormalId.Left] = Enum.NormalId.Right,
		[Enum.NormalId.Right] = Enum.NormalId.Left,
		[Enum.NormalId.Front] = Enum.NormalId.Bottom,
		[Enum.NormalId.Back] = Enum.NormalId.Top,
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Top] = Enum.NormalId.Back,
		[Enum.NormalId.Bottom] = Enum.NormalId.Front,
		[Enum.NormalId.Left] = Enum.NormalId.Right,
		[Enum.NormalId.Right] = Enum.NormalId.Left,
		[Enum.NormalId.Front] = Enum.NormalId.Top,
		[Enum.NormalId.Back] = Enum.NormalId.Bottom,
	},
	[Enum.NormalId.Front] = {
		[Enum.NormalId.Top] = Enum.NormalId.Right,
		[Enum.NormalId.Bottom] = Enum.NormalId.Left,
		[Enum.NormalId.Left] = Enum.NormalId.Top,
		[Enum.NormalId.Right] = Enum.NormalId.Bottom,
		[Enum.NormalId.Front] = Enum.NormalId.Back,
		[Enum.NormalId.Back] = Enum.NormalId.Front,
	},
	[Enum.NormalId.Back] = {
		[Enum.NormalId.Top] = Enum.NormalId.Left,
		[Enum.NormalId.Bottom] = Enum.NormalId.Right,
		[Enum.NormalId.Left] = Enum.NormalId.Bottom,
		[Enum.NormalId.Right] = Enum.NormalId.Top,
		[Enum.NormalId.Front] = Enum.NormalId.Back,
		[Enum.NormalId.Back] = Enum.NormalId.Front,
	},
}


--// Helper functions
local function RoundToNearest(number, increment)
	return math.round(number / increment) * increment
end

local function RoundVectorToNearest(vector: Vector3, increment): Vector3
	return Vector3.new(
		RoundToNearest(vector.X, increment),
		RoundToNearest(vector.Y, increment),
		RoundToNearest(vector.Z, increment)
	)
end

local function Midpoint(children: {BasePart}): Vector3
	local mid = Vector3.zero
	for i, child in pairs(children) do
		mid += child:GetPivot().Position
	end
	
	return mid / (#children == 0 and 1 or #children)
end

local function GetFaceNormal(axis: string, index: number): Enum.NormalId
	if axis == "X" then
		return index == 1 and Enum.NormalId.Left or Enum.NormalId.Right
	elseif axis == "Y" then
		return index == 1 and Enum.NormalId.Bottom or Enum.NormalId.Top
	elseif axis == "Z" then
		return index == 1 and Enum.NormalId.Front or Enum.NormalId.Back
	end
end

local function CreateCubletFace(cublet: Model, axis: string, index: number)
	local normalId = GetFaceNormal(axis, index)
	local normal = Vector3.fromNormalId(normalId)
	
	local face = Instance.new("Part")
	face:AddTag("Face")
	face:SetAttribute("Face", normalId.Name)
	face.Name = "Face" .. axis
	face.Anchored = true
	face.CastShadow	= false
	face.CanCollide = false
	face.CanQuery = false
	face.TopSurface = Enum.SurfaceType.Smooth
	face.BottomSurface = Enum.SurfaceType.Smooth
	
	local offset = cublet.PrimaryPart.Size * (normal/2)
	local rotation = Vector3.new(math.rad(normal.X), math.rad(normal.Y), math.rad(normal.Z))
	
	face.Size = Vector3.new(
		cublet.PrimaryPart.Size.X - Config.FaceBorderSize,
		cublet.PrimaryPart.Size.Y - Config.FaceBorderSize,
		Config.FaceThickness
	)
	face.CFrame = cublet.PrimaryPart.CFrame * CFrame.new(offset, rotation)
	face.Parent = cublet
end

function RubiksCube.GetCell(cube: Model, position: Vector3): Vector3
	local size = cube:GetAttribute("Size")
	return RoundVectorToNearest(position, size) / size
end


--// Methods
function RubiksCube.Generate(dimensions: number, size: number): Model
	local cube = Instance.new("Model")
	cube.Name = ("%sx%sRubiksCube"):format(size, size)
	cube:SetAttribute("Dimensions", dimensions)
	cube:SetAttribute("Size", size)
	
	for x = 1, dimensions do
		for y = 1, dimensions do
			for z = 1, dimensions do
				-- only create cells on edge or corner pieces
				if (x == 1 or x == dimensions) or (y == 1 or y == dimensions) or (z == 1 or z == dimensions) then
					local cublet = Instance.new("Model")
					cublet.Name = ("CubletX%sY%sZ%s"):format(x, y, z)
					
					local core = Instance.new("Part")
					core:AddTag("Core")
					core.Name = "Core"
					core.Anchored = true
					core.CastShadow = false
					core.CanCollide = false
					core.TopSurface = Enum.SurfaceType.Smooth
					core.BottomSurface = Enum.SurfaceType.Smooth
					
					core.Size = Vector3.new(size, size, size)
					core.CFrame = CFrame.new(x*size, y*size, z*size)
					core.Parent = cublet
					cublet.PrimaryPart = core
					cublet.Parent = cube
					
					if x == 1 or x == dimensions then
						CreateCubletFace(cublet, "X", x)
					end
					if y == 1 or y == dimensions then
						CreateCubletFace(cublet, "Y", y)
					end
					if z == 1 or z == dimensions then
						CreateCubletFace(cublet, "Z", z)
					end
				end
			end
		end
	end
	
	local center = Instance.new("Part")
	center.Name = "Center"
	center.Anchored = true
	center.CastShadow = false
	center.CanCollide = false
	center.Size = Vector3.new(1, 1, 1)
	center.CFrame = cube:GetBoundingBox()
	center.Parent = cube
	
	cube.PrimaryPart = center
	cube.Parent = workspace
	
	RubiksCube.ApplyPalette(cube, Palette.Standard)
	
	return cube
end

function RubiksCube.ApplyPalette(cube: Model, palette: {[string]: Color3})
	for i, face in pairs(cube:GetDescendants()) do
		if face:HasTag("Face") then
			face.Color = palette[face:GetAttribute("Face")]
		elseif face:HasTag("Core") then
			face.Color = palette.Core
		end
	end
end


--// Cube Rotations
function RubiksCube.Rotate(cube: Model, cell: Vector3, faceId: Enum.NormalId, directionId: Enum.NormalId)
	if cube:GetAttribute("Rotating") then return end
	cube:SetAttribute("Rotating", true)
	
	local normalId = RotationMap[faceId][directionId]
	local normal = Vector3.fromNormalId(normalId)
	local axis = AxisMap[normalId]
	
	print(cell, "//", faceId, "//", directionId, "//", normalId)

	local size = cube:GetAttribute("Size")
	local cublets = {}

	for i, cublet in pairs(cube:GetChildren()) do
		if cublet:IsA("Model") then
			local pos = cublet:GetPivot().Position
			if RoundToNearest(pos[axis], size) / size == cell[axis] then
				table.insert(cublets, cublet)
			end
		end
	end

	local rotation = math.rad(90)
	local orientation = Vector3.new(rotation, rotation, rotation) * normal

	local center = CFrame.new(Midpoint(cublets))

	local cfMap = {}
	for i, cublet in pairs(cublets) do
		cfMap[cublet] = center:ToObjectSpace(cublet:GetPivot())
	end

	-- animate rotation
	local tweenInfo = TweenInfo.new(Config.RotateSpeed, Enum.EasingStyle.Sine)
	Tween:Connect(0, 1, tweenInfo, function(alpha)
		local rot = orientation * alpha
		local pivot = center * CFrame.fromEulerAnglesXYZ(rot.X, rot.Y, rot.Z)
		for cublet, baseCf in pairs(cfMap) do
			cublet:PivotTo(pivot:ToWorldSpace(baseCf))
		end
	end):Play():Yield()
	
	-- snap to final state to fix any tween inaccuracies
	local pivot = center * CFrame.fromEulerAnglesXYZ(orientation.X, orientation.Y, orientation.Z)
	for cublet, baseCf in pairs(cfMap) do
		cublet:PivotTo(pivot:ToWorldSpace(baseCf))
		
		-- reset core orientation
		cublet.PrimaryPart.CFrame = CFrame.new(cublet.PrimaryPart.Position)
	end
	
	cube:SetAttribute("Rotating", false)
end


RubiksCube.Rotations = {}

function RubiksCube.Rotations.R(cube: Model)
	RubiksCube.Rotate(cube, Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top)
end

function RubiksCube.Rotations.Ri(cube: Model)
	RubiksCube.Rotate(cube, Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom)
end

--//
return RubiksCube