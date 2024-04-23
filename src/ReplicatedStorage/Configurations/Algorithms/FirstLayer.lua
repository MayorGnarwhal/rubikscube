local FirstLayer = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)

--// Variables
FirstLayer.LayerSideOrder = {"Back", "Right", "Front", "Left"}

FirstLayer.CornerCoordinates = {
	Back = {
		Left = Vector2.new(1, 3),
		Right = Vector2.new(3, 3),
	},
	Front = {
		Left = Vector2.new(1, 1),
		Right = Vector2.new(3, 1),
	}
}

local BottomCorners = {
	Back = {
		[1] = {
			Left = Vector2.new(3, 3),
			Bottom = Vector2.new(1, 1),
		},
		[3] = {
			Right = Vector2.new(1, 3),
			Bottom = Vector2.new(3, 1),
		},
	},
	Right = {
		[1] = {
			Back = Vector2.new(3, 3),
			Bottom = Vector2.new(3, 1),
		},
		[3] = {
			Front = Vector2.new(1, 3),
			Bottom = Vector2.new(3, 3),
		},
	},
	Front = {
		[1] = {
			Right = Vector2.new(3, 3),
			Bottom = Vector2.new(3, 3),
		},
		[3] = {
			Left = Vector2.new(1, 3),
			Bottom = Vector2.new(1, 3),
		},
	},
	Left = {
		[1] = {
			Front = Vector2.new(3, 3),
			Bottom = Vector2.new(1, 3),
		},
		[3] = {
			Back = Vector2.new(1, 3),
			Bottom = Vector2.new(1, 1),
		},
	},
}

function FirstLayer.TopCornerCoordinates(faceName, index)
	local bottomCoords = BottomCorners[faceName]

	local coords = {}
	for faceName, coord in pairs(bottomCoords[index]) do
		if faceName == "Bottom" then
			coords.Top = Vector2.new(coord.X, 3 - coord.Y + 1)
		else
			coords[faceName] = Vector2.new(coord.X, 3 - coord.Y + 1)
		end
	end

	return coords
end

function FirstLayer.GetCornerByColors(color1, color2)
	for faceName, indexes in pairs(BottomCorners) do
		
		for index, map in pairs(indexes) do
			if map[color1] and map[color2] then
				return faceName, index
			end
		end
	end
end


--// Methods
function FirstLayer.FindCornerInTopLayer(cube: table)
	for i, faceName in ipairs(FirstLayer.LayerSideOrder) do
		local face = cube[faceName]

		for j, index in ipairs({1, 3}) do
			local coords = FirstLayer.TopCornerCoordinates(faceName, index)
			
			local topCoords = coords.Top
			local topColor = cube.Top[topCoords.X][topCoords.Y]
			local topIsWhite = topColor == "Top"
			
			if topIsWhite or face[index][1] == "Top" then
				
				local cornerColors = {}
				if topIsWhite then
					local faceColor = face[3 - j + 1][3]
					table.insert(cornerColors, faceColor)
				else
					table.insert(cornerColors, topColor)
				end
				
				local isSolved = topIsWhite
				for sideFace, coord in pairs(coords) do
					local faceColor = cube[sideFace][coord.X][coord.Y]
					
					if faceColor ~= "Top" then
						table.insert(cornerColors, faceColor)
					end
					
					if faceColor ~= cube[sideFace][2][coord.Y] then
						isSolved = false
					end
				end
				
				if not isSolved then
					local algorithm = index == 1 and {"Fi", "Di", "F"} or {"F", "D", "Fi"}

					return faceName, cornerColors, algorithm
				end
			end
		end
	end
end

function FirstLayer.FindCornerInBottomLayer(cube: table)
	for i, faceName in ipairs(FirstLayer.LayerSideOrder) do
		local face = cube[faceName]
		
		for j, index in ipairs({1, 3}) do
			if face[index][3] == "Top" then
				local coords = BottomCorners[faceName][index]
				
				local cornerColors = {}
				for sideFace, coord in pairs(coords) do
					table.insert(cornerColors, cube[sideFace][coord.X][coord.Y])
				end
				
				local bottomColor = cube.Bottom[coords.Bottom.X][coords.Bottom.Y]
				
				return bottomColor, cornerColors
			end
		end
	end
end

function FirstLayer.FindCornerOnBottomFace(cube: table)
	local coordMap = {
		Back = Vector2.new(3, 1),
		Right = Vector2.new(3, 3),
		Front = Vector2.new(1, 3),
		Left = Vector2.new(1, 1),
	}
	
	for faceName, coord in pairs(coordMap) do
		if cube.Bottom[coord.X][coord.Y] == "Top" then
			
			local index = table.find(FirstLayer.LayerSideOrder, faceName)
			
			local numRotations
			local frontFaceName
			local cornerColors = {}
			
			for rot = 0, 4 do
				local wrappedIndex = (index - 1 + rot) % 4 + 1
				local sideName = FirstLayer.LayerSideOrder[wrappedIndex]
				
				local coords = FirstLayer.TopCornerCoordinates(sideName, 3)
				if cube.Top[coords.Top.X][coords.Top.Y] ~= "Top" then
					numRotations = rot
					frontFaceName = sideName
					
					-- these corners are wrong
					for sideFace, coord in pairs(coords) do
						table.insert(cornerColors, cube[sideFace][coord.X][coord.Y])
					end
					
					break
				end
			end
			
			local orientMove = (numRotations == 1 and "D") or (numRotations == 2 and "D2") or (numRotations == 3 and "Di")
			local algorithm = {"Ri", "D", "R"}
			
			return frontFaceName, algorithm, orientMove, cornerColors
		end
	end
end

--//
return FirstLayer