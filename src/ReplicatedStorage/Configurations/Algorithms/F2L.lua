local F2L = {}

--// Variables
F2L.Algorithms = {
	EdgeInsertRight = {"U", "R", "Ui", "Ri", "Ui", "Fi", "U", "F"},
	EdgeInsertLeft = {"Ui", "Li", "U", "L", "U", "F", "Ui", "Fi"},
}

F2L.BottomEdgeCoordinates = {
	Front = Vector2.new(2, 3),
	Back = Vector2.new(2, 1),
	Left = Vector2.new(1, 2),
	Right = Vector2.new(3, 2),
}

F2L.LayerSideOrder = {"Back", "Left", "Front", "Right"}


--// Methods
function F2L.FindEdgeInBottomLayer(cube: table)
	local bottomFace = cube.Bottom
	
	for faceName, coords in pairs(F2L.BottomEdgeCoordinates) do
		local face = cube[faceName]
		
		if face[2][3] ~= "Bottom" and bottomFace[coords.X][coords.Y] ~= "Bottom" then
			return faceName, face[2][3], bottomFace[coords.X][coords.Y]
		end
	end
end

function F2L.FindUnsolvedEdgeInSecondLayer(cube: table)
	for i, faceName in ipairs(F2L.LayerSideOrder) do
		local rightIndex = i % 4 + 1
		local rightFaceName = F2L.LayerSideOrder[rightIndex]
		
		local frontCenter = cube[faceName][2][2]
		local frontCell = cube[faceName][1][2]
		
		local rightCenter = cube[rightFaceName][2][2]
		local rightCell = cube[rightFaceName][3][2]
		
		if frontCell ~= "Bottom" and rightCell ~= "Bottom" and (frontCenter ~= frontCell or rightCenter ~= rightCell) then
			return faceName, frontCell, rightCell
		end
	end
end

--//
return F2L