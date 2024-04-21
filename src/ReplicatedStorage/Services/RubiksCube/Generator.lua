--[[
	Create 3D model of Rubik's Cube
]]

local Generator = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local Config = require(Configurations.Config)

local TemplateFace = Instance.new("Part")
TemplateFace:AddTag("Face")
TemplateFace.Anchored = true
TemplateFace.CastShadow	= false
TemplateFace.CanCollide = false
--TemplateFace.CanQuery = false
TemplateFace.TopSurface = Enum.SurfaceType.Smooth
TemplateFace.BottomSurface = Enum.SurfaceType.Smooth

local TemplateCore = Instance.new("Part")
TemplateCore:AddTag("Core")
TemplateCore.Name = "Core"
TemplateCore.Anchored = true
TemplateCore.CastShadow = false
TemplateCore.CanCollide = false
TemplateCore.CanQuery = false
TemplateCore.TopSurface = Enum.SurfaceType.Smooth
TemplateCore.BottomSurface = Enum.SurfaceType.Smooth

local TemplateCenter = Instance.new("Part")
TemplateCenter.Name = "Center"
TemplateCenter.Anchored = true
TemplateCenter.CastShadow = false
TemplateCenter.CanCollide = false
TemplateCenter.CanQuery = false
TemplateCenter.Transparency = 1
TemplateCenter.Size = Vector3.new(1, 1, 1)

local TemplateHitbox = TemplateCenter:Clone()
TemplateHitbox:AddTag("RubiksHitbox")
TemplateHitbox.Name = "Hitbox"
TemplateHitbox.CanQuery = true


--// Helper functions
local function GetFaceNormal(axis: Enum.Axis, index: number): Enum.NormalId
	if axis == Enum.Axis.X then
		return index == 1 and Enum.NormalId.Left or Enum.NormalId.Right
	elseif axis == Enum.Axis.Y then
		return index == 1 and Enum.NormalId.Bottom or Enum.NormalId.Top
	elseif axis == Enum.Axis.Z then
		return index == 1 and Enum.NormalId.Front or Enum.NormalId.Back
	end
end

local function CreateCubletFace(cublet: Model, axis: Enum.Axis, index: number)
	local normalId = GetFaceNormal(axis, index)
	local normal = Vector3.fromNormalId(normalId)

	local face = TemplateFace:Clone()
	face:AddTag("Face")
	face:SetAttribute("Face", normalId.Name)
	face.Name = "Face" .. axis.Name

	face.Size = Vector3.new(
		cublet.PrimaryPart.Size.X - Config.FaceBorderSize,
		cublet.PrimaryPart.Size.Y - Config.FaceBorderSize,
		Config.FaceThickness
	)
	
	local offset = cublet.PrimaryPart.Size * (normal/2)
	local rotation = Vector3.new(math.rad(normal.X), math.rad(normal.Y), math.rad(normal.Z))
	
	face.CFrame = cublet.PrimaryPart.CFrame * CFrame.new(offset, rotation)
	face.Parent = cublet
end

local function GetCubletType(cublet: Model)
	local numFaces = 0
	for i, child in pairs(cublet:GetChildren()) do
		if child:HasTag("Face") then
			numFaces += 1
		end
	end
	
	if numFaces == 0 then
		return "Core"
	elseif numFaces == 1 then
		return "Center"
	elseif numFaces == 2 then
		return "Edge"
	elseif numFaces == 3 then
		return "Corner"
	end
end


--// Methods
function Generator.Create(dimensions: number, size: number): Model
	local cube = Instance.new("Model")
	cube.Name = ("%sx%sRubiksCube"):format(dimensions, dimensions)
	
	for x = 1, dimensions do
		for y = 1, dimensions do
			for z = 1, dimensions do
				-- only create cells on edge or corner pieces
				if (x == 1 or x == dimensions) or (y == 1 or y == dimensions) or (z == 1 or z == dimensions) then
					local cublet = Instance.new("Model")
					cublet.Name = ("CubletX%sY%sZ%s"):format(x, y, z)

					local core = TemplateCore:Clone()
					core.Size = Vector3.new(size, size, size)
					core.CFrame = CFrame.new(x*size, y*size, z*size)
					core.Parent = cublet
					cublet.PrimaryPart = core
					cublet.Parent = cube

					if x == 1 or x == dimensions then
						CreateCubletFace(cublet, Enum.Axis.X, x)
					end
					if y == 1 or y == dimensions then
						CreateCubletFace(cublet, Enum.Axis.Y, y)
					end
					if z == 1 or z == dimensions then
						CreateCubletFace(cublet, Enum.Axis.Z, z)
					end
					
					local cubletType = GetCubletType(cublet)
					cublet:SetAttribute("CubletType", cubletType)
				end
			end
		end
	end
	
	local cframe, size = cube:GetBoundingBox()
	
	local center = TemplateCenter:Clone()
	center.CFrame = cframe
	center.Parent = cube
	
	local hitbox = TemplateHitbox:Clone()
	hitbox.CFrame = cframe
	hitbox.Size = size - Vector3.one * Config.FaceThickness * 2
	hitbox.Parent = cube

	cube.PrimaryPart = hitbox -- center
	cube.Parent = workspace

	return cube
end

--//
return Generator