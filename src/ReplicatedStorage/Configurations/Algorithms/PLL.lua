local PLL = {}

--// Variables
PLL.Algorithms = {
	Headlights = {"Ri", "F", "Ri", "B2", "R", "Fi", "Ri", "B2", "R2"},
	
	EdgesClockwise = {"F2", "U", "L", "Ri", "F2", "Li", "R", "U", "F2"},
	EdgesCounterClockwise = {"F2", "Ui", "L", "Ri", "F2", "Li", "R", "Ui", "F2"},
}

PLL.LayerSideOrder = {"Back", "Left", "Front", "Right"}


--// Methods
function PLL.FindHeadlights(cube: table, ignoreFace: string?)
	for i, faceName in ipairs(PLL.LayerSideOrder) do
		local face = cube[faceName]
		if face[1][3] == face[3][3] then
			local oppositeFaceIndex = (i + 1) % 4 + 1
			local oppositeFaceName = PLL.LayerSideOrder[oppositeFaceIndex] 
			
			if ignoreFace ~= oppositeFaceName then
				return oppositeFaceName, face[1][3]
			end
		end
	end
end

-- if two faces have headlights, then the face is solved
function PLL.CornersSolved(cube: table)
	local faceName = PLL.FindHeadlights(cube)
	local secondFace = faceName and PLL.FindHeadlights(cube, faceName)
	
	return secondFace and true or false
end

function PLL.FindSolvedSide(cube: table)
	for i, faceName in ipairs(PLL.LayerSideOrder) do
		local face = cube[faceName]
		if face[1][3] == face[2][3] and face[2][3] == face[3][3] then
			return faceName
		end
	end
end

function PLL.SolveFinalEdges(cube: table)
	local solvedSide = PLL.FindSolvedSide(cube)
	if not solvedSide then 
		return PLL.Algorithms.EdgesClockwise, nil, "clockwise" -- all sides are unsolved
	end
	
	local solvedFaceIndex = table.find(PLL.LayerSideOrder, solvedSide)
	
	local frontFaceIndex = (solvedFaceIndex + 1) % 4 + 1 -- opposite of solved face
	local leftFaceIndex = (frontFaceIndex - 2) % 4 + 1
	
	local frontFaceName = PLL.LayerSideOrder[frontFaceIndex]
	local leftFaceName = PLL.LayerSideOrder[leftFaceIndex]
	
	local frontCell = cube[frontFaceName][2][3]
	local leftCell = cube[leftFaceName][2][3]
	
	local frontCellIndex = table.find(PLL.LayerSideOrder, frontCell)
	local leftCellIndex = table.find(PLL.LayerSideOrder, leftCell)
	
	local expectedLeftIndex = (frontCellIndex - 2) % 4 + 1
	
	if leftCellIndex == expectedLeftIndex then
		return PLL.Algorithms.EdgesCounterClockwise, frontFaceName, "counter-clockwise"
	else
		return PLL.Algorithms.EdgesClockwise, frontFaceName, "clockwise"
	end
end

--//
return PLL