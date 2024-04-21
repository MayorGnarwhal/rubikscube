local RubiksCube = {}
RubiksCube.__index = RubiksCube

--// Dependencies
local Generator = require(script.Generator)
local FaceMaps = require(script.FaceMaps)

local Services = game.ReplicatedStorage.Services
local MatrixUtil = require(Services.MatrixUtil)
local Tween = require(Services.Tween)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)
local Palettes = require(Configurations.Palettes)
local Config = require(Configurations.Config)
local Moves = require(Configurations.Moves)

--// Variables
local RotationSliceMap = FaceMaps.RotationSliceMap
local ReverseSliceMap = FaceMaps.ReverseSliceMap
local NormalFaceMap = FaceMaps.NormalFaceMap
local AxisMap = FaceMaps.AxisMap


--// Methods
-- @constructor
-- creates a new RubiksCube object
-- @param dimensions	width and height of each face in cublets
-- @return RubiksCube
function RubiksCube.new(dimensions: number)
	local map = {}
	for i, faceId in pairs(Enum.NormalId:GetEnumItems()) do
		map[faceId.Name] = MatrixUtil.Create(Vector2.new(dimensions, dimensions), faceId.Name)
	end
	
	return RubiksCube.fromMap(map, true)
end

-- @constructor
-- creates a RubiksCube object from a prefilled matrix cube representation
-- @param cubeMap	matrix cube representation of cube
--					{[NormalId.Name] = nxn matrix}
-- @param skipValidation	flag to skip simple validation of cubeMap. used internally for efficiency
-- @return RubiksCube
function RubiksCube.fromMap(cubeMap: table, skipValidation: boolean?)
	local n = #next(cubeMap)
	
	if not skipValidation then
		for i, normalId in pairs(Enum.NormalId:GetEnumItems()) do
			local matrix = cubeMap[normalId.Name]
			assert(matrix, ("Cube map missing %s face matrix"):format(normalId.Name))
			assert(#matrix == n, ("%s matrix has invalid width (got %s, expected %s)"):format(normalId.Name, #matrix, n))
			for j, col in pairs(matrix) do
				assert(#matrix[j] == n, ("%s column %s has invalid height (got %s, expected %s"):format(normalId.Name, j, #matrix[j], n))
			end
		end
	end
	
	return setmetatable({
		Dimensions = n,
		Map = cubeMap,
		
		-- state
		Rotating = false,
		Scrambling = false,
		CurrentSolve = nil,
		
		Scrambled = false,
		
		-- config
		RotationSpeed = 0.2,
		
		-- connections
		-- only creates connections if physical cube is made
		MapChangedBindable = nil,
		SolveBeganBindable = nil,
		SolveEndedBindable = nil,
		
		-- 3D cube variables
		Size = nil,
		Cube = nil,
		Palette = nil,
	}, RubiksCube)
end


-- @public
-- creates a physical Model representation of the cube and adds it to workspace
-- does NOT sync with state of cube map. should be called immediately after RubiksCube construction
-- @param size	 nxnxn size of each cublet in studs
-- @return Model
function RubiksCube:GenerateCube3D(size: number, palette: Palettes.Palette?): Model
	self.MapChangedBindable = self.MapChangedBindable or Instance.new("BindableEvent")
	self.SolveBeganBindable = self.SolveBeganBindable or Instance.new("BindableEvent")
	self.SolveEndedBindable = self.SolveEndedBindable or Instance.new("BindableEvent")
	
	if self.Cube then
		self:DestroyCube3D()
	end
	
	self.Size = size
	self.Cube = Generator.Create(self.Dimensions, self.Size)
	self.Palette = palette or Palettes.Standard
	
	self:ApplyPalette()
	
	return self.Cube
end

-- @public
-- low level cube rotation function. 
-- does nothing is cube is currently rotating
-- yields until rotation is finished
-- @param cell			3D cell of the cube clicked. can be retrieved from :GetCell()
-- @param frontFaceId	front face of cube for rotation
-- @param directionId	direction of rotation, in 3D space
function RubiksCube:Rotate(cell: Vector3, frontFaceId: Enum.NormalId, directionId: Enum.NormalId, animLength: number?)
	if self.Rotating then return end
	
	local rotationNormal = Vector3.fromNormalId(frontFaceId):Cross(Vector3.fromNormalId(directionId))
	if rotationNormal:FuzzyEq(Vector3.zero, 0.1) then
		warn("Invalid rotation")
		return
	end
	
	self.Rotating = true
	
	local rotationId = Util.GetNormalId(rotationNormal)
	
	self:_doMapRotation(cell, frontFaceId, rotationId, directionId)
	if self.Cube then
		self:_doCubeRotation(cell, rotationId, nil, animLength)
	end
	
	if self.Scrambled and not self.CurrentSolve then
		local now = os.clock()
		self.CurrentSolve = {
			StartTimestamp = now,
			Turns = 0,
		}
		self.SolveBeganBindable:Fire(now)
	end
	
	if self.CurrentSolve then
		self.CurrentSolve.Turns += 1
		
		if self:IsSolved() then
			local timeToSolve = os.clock() - self.CurrentSolve.StartTimestamp
			self.SolveEndedBindable:Fire(true, timeToSolve, self.CurrentSolve.Turns)
			
			self.CurrentSolve = nil
			self.Scrambled = false
		end
	end
	
	self.Rotating = false
end

-- @public
-- orient cube such that a given face is oriented at a specific vector
-- does nothing if cube is currently rotationg
-- yields until rotation is finished
-- @param topNormalId		normal of face to orient (Front/Back) are swapped
-- @param targetNormalId?	normal to orient face towards. Default: Enum.NormalId.Top
function RubiksCube:Orient(topNormalId: Enum.NormalId, targetNormalId: Enum.NormalId?, animLength: number?)
	if not self.Cube then
		warn("Cannot orient cube without a physical representation for reference")
		return
	end
	
	if self.Rotating then return end
	self.Rotating = true

	targetNormalId = targetNormalId or Enum.NormalId.Top
	animLength = animLength or math.min(self.RotationSpeed, 0.2)

	local cublets = self.Cube:GetChildren()
	table.remove(cublets, table.find(cublets, self.Cube.Hitbox))

	local cublet = self:_getCublet("Center", topNormalId)

	local targetVector = Vector3.fromNormalId(targetNormalId)
	local lookVector = (cublet.PrimaryPart.Position - self.Cube.PrimaryPart.Position).Unit

	if lookVector:FuzzyEq(targetVector, 0.2) then
		self.Rotating = false
		return -- already in proper orientation
	end

	local rotationNormal = lookVector:Cross(targetVector)
	local rotationId = Util.GetNormalId(rotationNormal)

	local angle = -math.rad(90)
	local numTurns = 1
	if rotationNormal:FuzzyEq(Vector3.zero, 0.1) then
		-- 180 degree rotation, need to apply rotation in 2 steps
		local axis = AxisMap[topNormalId]
		local otherAxis = (axis == Enum.Axis.X and Enum.Axis.X) or 
			(axis == Enum.Axis.Y and Enum.Axis.Z) or (axis == Enum.Axis.Z and Enum.Axis.X)
		
		local axisNormalId = Util.GetNormalId(Vector3.fromAxis(otherAxis))
		
		self.Rotating = false
		self:Orient(topNormalId, axisNormalId)
		self:Orient(topNormalId, targetNormalId)

		return
	end

	local frontFaceId = Util.GetNormalId(-lookVector)
	local directionId = Util.GetNormalId(-targetVector)
	
	for j = 1, numTurns do
		local completed = 0
		for i = 1, 3 do
			task.spawn(function()
				local cell = Vector3.new(i, i, i)
				self:_doMapRotation(cell, frontFaceId, rotationId, directionId)
				if self.Cube then
					self:_doCubeRotation(cell, rotationId, angle, animLength)
				end
				completed += 1
			end)
		end
		
		repeat task.wait() until completed == 3
	end

	self.Rotating = false
end

-- @public
-- implements a move from the Moves table
-- @param move			a list of the arguments for :Rotate() from the Moves table
function RubiksCube:Move(move: table, animLength: number?)
	for i, args in ipairs(move) do
		if animLength then
			args = table.clone(args)
			table.insert(args, animLength)
		end
		self:Rotate(unpack(args))
	end
end

-- @public
-- randomly applies moves from the Moves table
-- @param turns?	number of turns to apply. Default: Config.ScrambleLength
-- @return 		array of the moves applied
function RubiksCube:Scramble(turns: number?): table
	if self.Scrambling then return end
	self.Scrambling = true
	
	if self.CurrentSolve then
		self.SolveEndedBindable:Fire(false)
		self.CurrentSolve = nil
	end

	local scramble = Util.GenerateScramble(turns or Config.ScrambleLength)
	task.spawn(function() -- run async to return scramble immediately
		self.Scrambled = false
		
		for i, moveName in ipairs(scramble) do
			self:Move(Moves[moveName])
		end
		
		self.Scrambled = true
		self.Scrambling = false
	end)

	return scramble
end

-- @public
-- recolors the "stickers" of the cube
-- @param palette	map of face to color
function RubiksCube:ApplyPalette(palette: Palettes.Palette?)
	if not self.Cube then return end

	palette = palette or self.Palette
	self.Palette = palette
	
	for i, face in pairs(self.Cube:GetDescendants()) do
		if face:HasTag("Face") then
			face.Color = palette[face:GetAttribute("Face")]
		elseif face:HasTag("Core") then
			face.Color = palette.Core
		end
	end
	
	self.MapChangedBindable:Fire()
end

-- @public
-- gets the cube cell from a position in WorldSpace
-- @param position
-- @return 		cell of cube in 3D space
function RubiksCube:GetCell(position: Vector3): Vector3
	return Util.RoundVectorToNearest(position, self.Size) / self.Size
end

-- @public
-- @return boolean		true iff cube is solved
function RubiksCube:IsSolved(): boolean
	for faceName, matrix in pairs(self.Map) do
		local compare = matrix[1][1]
		for y = 1, self.Dimensions do
			for x = 1, self.Dimensions do
				if matrix[x][y] ~= compare then
					return false
				end
			end
		end
	end

	return true
end

function RubiksCube:StripPaint()
	local n = self.Dimensions
	local m = math.ceil(n / 2)
	
	for faceName, matrix in pairs(self.Map) do
		for x = 1, n do
			for y = 1, n do
				if not (x == m and y == m) then
					matrix[x][y] = false
				end
			end
		end
	end
	
	for i, cublet in pairs(self.Cube:GetChildren()) do
		if cublet:GetAttribute("CubletType") == "Center" then continue end
		
		for i, face in pairs(self:_getCubletFaces(cublet)) do
			face.Color = Config.UnpaintedColor
		end
	end
	
	self.MapChangedBindable:Fire()
end

function RubiksCube:Paint(cell: Vector3, sideId: Enum.NormalId, faceId: Enum.NormalId, colorId: Enum.NormalId)
	local n = self.Dimensions
	local m = math.ceil(n / 2)
	
	local axis = AxisMap[sideId]
	local coordAxes
	if axis == Enum.Axis.Z then
		coordAxes = {Enum.Axis.X, Enum.Axis.Y}
	elseif axis == Enum.Axis.Y then
		coordAxes = {Enum.Axis.X, Enum.Axis.Z}
	elseif axis == Enum.Axis.X then
		coordAxes = {Enum.Axis.Z, Enum.Axis.Y}
	end
	
	local coord = Vector2.new(cell[coordAxes[1].Name], cell[coordAxes[2].Name])
	if FaceMaps.FlipedFaces.Col[sideId] then
		coord = Vector2.new(n - coord.X + 1, coord.Y)
	end
	
	if FaceMaps.FlipedFaces.Row[sideId] then
		coord = Vector2.new(coord.X, n - coord.Y + 1)
	end
	
	if coord.X == m and coord.Y == m then
		return -- cannot paint a center piece
	end
	
	self.Map[sideId.Name][coord.X][coord.Y] = colorId.Name
	
	local face = self:_getFace(cell, faceId)
	if face then
		face.Color = self.Palette[colorId.Name]
	end
	
	self.MapChangedBindable:Fire()
end

-- @public
function RubiksCube:IsValidPaint()
	local stickerCount = {}
	for i, normalId in pairs(Enum.NormalId:GetEnumItems()) do
		stickerCount[normalId.Name] = 0
	end
	
	for faceName, matrix in pairs(self.Map) do
		for x = 1, self.Dimensions do
			for y = 1, self.Dimensions do
				local cellName = matrix[x][y]
				if not cellName then
					return false, "There is still an unpainted face."
				end
				stickerCount[cellName] += 1
			end
		end
	end
	
	for faceName, count in pairs(stickerCount) do
		if count ~= self.Dimensions^2 then
			return false, "There are too many " .. FaceColorMap[faceName] .. " stickers."
		end
	end
	
	return true
end


-- @private
-- applies a rotation to the matrix representation of the cube
function RubiksCube:_doMapRotation(cell: Vector3, frontFaceId: Enum.NormalId, rotationId: Enum.NormalId, directionId: Enum.NormalId)
	local cube = self.Map
	local n = self.Dimensions
	local rotationNormal = Vector3.fromNormalId(rotationId)
	local rotationAxis = AxisMap[rotationId]
	local index = cell[rotationAxis.Name]
	
	if index == 1 or index == n then -- face was rotated
		local rotationAxisNormal = Vector3.fromAxis(rotationAxis)
		local angle = Vector3.fromNormalId(frontFaceId):Angle(Vector3.fromNormalId(directionId), rotationAxisNormal)
		if index == n then
			angle *= -1
			rotationAxisNormal *= -1
		end

		local clockwise = angle > 0
		local rotationFace = Util.GetNormalId(rotationAxisNormal)
		MatrixUtil.Rotate(cube[rotationFace.Name], clockwise)
	end
	
	local faces = {frontFaceId}
	for i = 2, 4 do
		local normal = Vector3.fromNormalId(faces[i - 1]):Cross(rotationNormal)
		table.insert(faces, Util.GetNormalId(normal))
	end
	
	local function getParts(face: Enum.NormalId)
		local axis = AxisMap[face]
		local slice = RotationSliceMap[rotationAxis][axis]
		
		local rIndex = index
		if FaceMaps.FlipedFaces[slice][face] then
			rIndex = n - index + 1
		end
		
		return axis, slice, rIndex
	end
	
	local temp = Util.DeepCopy(cube[faces[1].Name])
	for i = 1, #faces do
		local face1 = faces[i+1] or faces[1]
		local face2 = faces[i]
		
		local matrix1 = (i == #faces and temp or cube[face1.Name])
		local matrix2 = cube[face2.Name]
		
		local axis1, slice1, index1 = getParts(face1)
		local axis2, slice2, index2 = getParts(face2)
		
		local elements = MatrixUtil.GetSlice(matrix1, slice1, index1)
		if ReverseSliceMap[face1][face2] then
			Util.FlipArray(elements)
		end
		
		MatrixUtil.ReplaceSlice(matrix2, slice2, index2, elements)
	end
	
	if self.MapChangedBindable then
		self.MapChangedBindable:Fire(self.Map)
	end
end

-- @private
-- applies a rotation to the physical representation of the cube
function RubiksCube:_doCubeRotation(cell: Vector3, rotationId: Enum.NormalId, angle: number?, animLength: number?)
	local rotationAxis = AxisMap[rotationId]

	local cublets = {}
	for i, cublet in pairs(self.Cube:GetChildren()) do
		if cublet:IsA("Model") then
			if self:GetCell(cublet:GetPivot().Position)[rotationAxis.Name] == cell[rotationAxis.Name] then
				table.insert(cublets, cublet)
			end
		end
	end
	
	local angle = angle or -math.rad(90)
	self:_doCubletRotation(cublets, angle, rotationId, animLength)
end

-- @private
-- animates a rotation
-- @param cublets		table of Models to rotate
-- @param angle			angle of rotation
-- @param rotationId	axis of rotation
-- @param animLength?	duration in seconds of animation. Default: 0.2
function RubiksCube:_doCubletRotation(cublets: {Model}, angle: number, rotationId: Enum.NormalId, animLength: number?)
	animLength = animLength or self.RotationSpeed
	
	local center = CFrame.new(Util.Midpoint(cublets))
	
	local theta = Vector3.new(angle, angle, angle) * Vector3.fromNormalId(rotationId)
	local targetCf = center * CFrame.fromEulerAnglesXYZ(theta.X, theta.Y, theta.Z)
	
	local cfMap = {}
	for i, cublet in pairs(cublets) do
		cfMap[cublet] = center:ToObjectSpace(cublet:GetPivot())
	end

	-- animate rotation
	local tweenInfo = TweenInfo.new(animLength, Enum.EasingStyle.Sine)
	local tween = Tween:Connect(0, 1, tweenInfo, function(alpha)
		local pivot = center:Lerp(targetCf, alpha)
		for cublet, baseCf in pairs(cfMap) do
			cublet:PivotTo(pivot:ToWorldSpace(baseCf))
		end
	end):Play()

	tween.Completed:Wait()
end

-- @private
function RubiksCube:_getCubletFaces(cublet: Model): table
	local faces = {}
	for i, child in pairs(cublet:GetChildren()) do
		if child:HasTag("Face") then
			table.insert(faces, child)
		end
	end
	return faces
end

-- @private
function RubiksCube:_getCublet(cubletType: "Center"|"Edge"|"Corner", ...): Model?
	local faceIds = {...}
	for i, cublet in pairs(self.Cube:GetChildren()) do
		if cublet:GetAttribute("CubletType") ~= cubletType then continue end
		
		local faces = self:_getCubletFaces(cublet)
		if #faces ~= #faceIds then continue end
		
		local success = true
		for i, face in pairs(faces) do
			local faceId = Enum.NormalId[face:GetAttribute("Face")]
			if not table.find(faceIds, faceId) then
				success = false
				break
			end
		end

		if success then
			return cublet
		end
	end
end

-- @private
function RubiksCube:_getFace(cell: Vector3, faceId: Enum.NormalId)
	for i, cublet in pairs(self.Cube:GetChildren()) do
		local cubletCell = self:GetCell(cublet:GetPivot().Position)
		if cubletCell == cell then
			local faces = self:_getCubletFaces(cublet)
			for j, face in pairs(faces) do
				if face:GetAttribute("Face") == faceId.Name then
					return face
				end
			end
		end
	end
end


-- @connection
function RubiksCube:GetStateChangedSignal(): RBXScriptSignal
	return self.MapChangedBindable.Event
end

function RubiksCube:GetSolveBeganSignal(): RBXScriptSignal
	return self.SolveBeganBindable.Event
end

-- @connection
function RubiksCube:GetSolveEndedSignal(): RBXScriptSignal
	return self.SolveEndedBindable.Event
end


-- @destructor
function RubiksCube:DestroyCube3D()
	if self.Cube then
		self.Cube:Destroy()
	end
end

-- @destructor
function RubiksCube:Destroy()
	self:DestroyCube3D()
	self.MapChangedBindable:Destroy()
	self.SolveBeganBindable:Destroy()
	self.SolveEndedBindable:Destroy()
	table.clear(self.Map)
end

--//
return RubiksCube