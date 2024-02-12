local RubiksCube = {}
RubiksCube.__index = RubiksCube

--// Dependencies
local Generator = require(script.Generator)
local FaceMaps = require(script.FaceMaps)

local Services = game.ReplicatedStorage.Services
local MatrixUtil = require(Services.MatrixUtil)
local Collect = require(Services.Collect)
local Tween = require(Services.Tween)

local Configurations = game.ReplicatedStorage.Configurations
local Palette = require(Configurations.Palette)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)

--// Variables
local AxisMap = FaceMaps.AxisMap
local RotationMap = FaceMaps.RotationMap


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

local function GetNormalId(normal: Vector3)
	local minDistance = math.huge
	local closestNormalId
	
	for i, normalId in pairs(Enum.NormalId:GetEnumItems()) do
		local distance = normal.Unit:Dot(Vector3.FromNormalId(normalId))
		if distance < minDistance then
			minDistance = distance
			closestNormalId = normalId
		end
	end
	
	return closestNormalId
end

local function FlipArray(tbl: table)
	local n, m = #tbl, #tbl/2
	for i = 1, m do
		tbl[i], tbl[n-i+1] = tbl[n-i+1], tbl[i]
	end
end


--// Constructor
-- @public
function RubiksCube.new(dimensions: number, size: number)
	local cube = Generator.Create(dimensions, size)
	
	local map = {}
	for i, faceId in pairs(Enum.NormalId:GetEnumItems()) do
		map[faceId.Name] = MatrixUtil.Create(Vector2.new(dimensions, dimensions), faceId.Name)
	end
	--local map = Collect(Enum.NormalId:GetEnumItems()):mapWithKeys(function(normalId)
	--	local column = Collect.create(dimensions, normalId.Name):get()
	--	local matrix = Collect.create(dimensions, column):get()
	--	return normalId.Name, matrix
	--end):get()
	
	local self = setmetatable({
		Dimensions = dimensions,
		Size = size,
		
		Cube = cube,
		CameraSubject = cube.PrimaryPart,
		Map = map,
		
		Speed = Config.DefaultRotateSpeed,
		
		Rotating = false,
		Shuffling = false,
		
		StateChanged = Instance.new("BindableEvent"),
	}, RubiksCube)
	
	self:ApplyPalette(Palette.Standard)
	
	return self
end


--// Methods
-- @private
function RubiksCube:_rotateCube(cell: Vector3, rotationId: Enum.NormalId)
	local rotationNormal = Vector3.fromNormalId(rotationId)
	local rotationAxis = AxisMap[rotationId]
	
	local cublets = {}
	for i, cublet in pairs(self.Cube:GetChildren()) do
		if cublet:IsA("Model") then
			if self:GetCell(cublet:GetPivot().Position)[rotationAxis.Name] == cell[rotationAxis.Name] then
				table.insert(cublets, cublet)
			end
		end
	end

	local rotation = -math.rad(90)
	local center = CFrame.new(Midpoint(cublets))

	local orientation = Vector3.new(rotation, rotation, rotation) * rotationNormal
	local targetCf = center * CFrame.fromEulerAnglesXYZ(orientation.X, orientation.Y, orientation.Z)

	local cfMap = {}
	for i, cublet in pairs(cublets) do
		cfMap[cublet] = center:ToObjectSpace(cublet:GetPivot())
	end

	-- animate rotation
	local tweenInfo = TweenInfo.new(self.Speed, Enum.EasingStyle.Sine)
	local tween = Tween:Connect(0, 1, tweenInfo, function(alpha)
		local pivot = center:Lerp(targetCf, alpha)
		for cublet, baseCf in pairs(cfMap) do
			cublet:PivotTo(pivot:ToWorldSpace(baseCf))
		end
	end):Play()

	tween.Completed:Wait()

	-- reset orientations of all core parts
	for cublet, baseCf in pairs(cfMap) do
		if cublet.PrimaryPart then
			cublet.PrimaryPart.CFrame = CFrame.new(cublet.PrimaryPart.Position)
		end
	end
end

-- @private
function RubiksCube:_rotateCubeMap(cell: Vector3, faceId: Enum.NormalId, rotationId: Enum.NormalId, directionId: Enum.NormalId)
	local cube = self.Map
	
	--print(string.rep("-", 20))
	local n = 3

	local axis = AxisMap[rotationId]
	local faceNormal = Vector3.fromNormalId(faceId)
	local rotationNormal = Vector3.fromNormalId(rotationId)
	local directionNormal = Vector3.fromNormalId(directionId)
	local axisNormal = Vector3.fromAxis(AxisMap[rotationId])

	local index = cell[axis.Name]

	if index == 1 or index == n then -- a face is being rotated
		local angle = faceNormal:Angle(directionNormal, axisNormal)
		if cell[axis.Name] == n then
			angle *= -1
			axisNormal *= -1
		end

		local clockwise = angle > 0
		local rotationFace = GetNormalId(axisNormal)
		if clockwise then
			MatrixUtil.RotateClockwise(cube[rotationFace.Name])
		else
			MatrixUtil.RotateCounterClockwise(cube[rotationFace.Name])
		end
	end

	local faces = {faceId}
	for i = 2, 4 do
		local normal = Vector3.fromNormalId(faces[i - 1]):Cross(rotationNormal)
		table.insert(faces, GetNormalId(normal))
	end

	local temp = MatrixUtil.Copy(cube[faces[1].Name])
	for i = 1, #faces do
		local face1 = faces[i + 1] or faces[1]
		local face2 = faces[i]

		local axis1 = AxisMap[face1]
		local axis2 = AxisMap[face2]

		local type1 = RotationMap[axis][axis1]
		local type2 = RotationMap[axis][axis2]

		local index1, index2 = index, index
		if FaceMaps.FlipedFaces[type1][face1] then
			index1 = n - index + 1 
		end
		if FaceMaps.FlipedFaces[type2][face2] then
			index2 = n - index + 1
		end
		
		local faceMatrix = i == #faces and temp or cube[face1.Name]
		local elements
		if type1 == "Row" then
			elements = MatrixUtil.GetRow(faceMatrix, index1)
		else
			elements = MatrixUtil.GetColumn(faceMatrix, index1)
		end
		
		local reverseElements = FaceMaps.Reverse[face1][face2] or false
		if reverseElements then
			FlipArray(elements)
		end
		
		--print(("  %s (%s, %s / %s) --> %s (%s, %s / %s)"):format(
		--	face1.Name, index1, type1, Vector3.fromNormalId(face1)[axis1.Name],
		--	face2.Name, index2, type2, Vector3.fromNormalId(face2)[axis2.Name]),
		--	"//", reverseElements
		--)

		if type2 == "Row" then
			MatrixUtil.ReplaceRow(cube[face2.Name], index2, elements)
		else
			MatrixUtil.ReplaceColumn(cube[face2.Name], index2, elements)
		end
	end
	
	--print(self:IsSolved())
	--print(string.rep("-", 20))
end

-- @public
function RubiksCube:Rotate(cell: Vector3, faceId: Enum.NormalId, directionId: Enum.NormalId)
	if self.Rotating then return end
	self.Rotating = true
	
	--print(cell, "//", faceId.Name, "//", directionId.Name)

	local rotationNormal = Vector3.fromNormalId(faceId):Cross(Vector3.fromNormalId(directionId))
	if rotationNormal:FuzzyEq(Vector3.zero, 0.1) then
		warn("Invalid rotation")
		self.Rotating = false
		return
	end
	
	local rotationId = GetNormalId(rotationNormal)
	
	self:_rotateCube(cell, rotationId)
	self:_rotateCubeMap(cell, faceId, rotationId, directionId)
	
	self.StateChanged:Fire()

	self.Rotating = false
end

-- @public
function RubiksCube:Move(moveArgs: table)
	self:Rotate(unpack(moveArgs))
end

--- applies random moves to the cube
-- @param turns?	number of moves to apply				
-- @returns table	array of the moves applied
-- @public
function RubiksCube:Shuffle(turns: number?): table
	if self.Shuffling then return end
	self.Shuffling = true
	
	local speed = self.Speed
	self.Speed = Config.ShuffleRotateSpeed
	
	local options = Collect(Moves):keys()
	local shuffle = {}
	
	turns = turns or Config.ShuffleLength
	for i = 1, turns do
		local moveName = options:random()
		local move = Moves[moveName]
		table.insert(shuffle, moveName)
		
		for j, args in ipairs(move) do
			self:Move(args)
		end
	end
	
	self.Speed = speed
	self.Shuffling = false
	
	return shuffle
end

-- @public
function RubiksCube:GetCell(position: Vector3): Vector3
	return RoundVectorToNearest(position, self.Size) / self.Size
end

-- @public
function RubiksCube:ApplyPalette(palette: table)
	for i, face in pairs(self.Cube:GetDescendants()) do
		if face:HasTag("Face") then
			face.Color = palette[face:GetAttribute("Face")]
		elseif face:HasTag("Core") then
			face.Color = palette.Core
		end
	end
end

-- @public
function RubiksCube:IsSolved(): boolean
	for faceName, matrix in pairs(self.Map) do
		for y = 1, self.Dimensions do
			for x = 1, self.Dimensions do
				if matrix[x][y] ~= faceName then
					return false
				end
			end
		end
	end
	
	return true
end

function RubiksCube:GetStateChangedSignal(): RBXScriptSignal
	return self.StateChanged.Event
end


--// Destructor
-- @public
function RubiksCube:Destroy()
	self.Cube:Destroy()
	self.StateChanged:Destroy()
	table.clear(self.Map)
end

--//
return RubiksCube