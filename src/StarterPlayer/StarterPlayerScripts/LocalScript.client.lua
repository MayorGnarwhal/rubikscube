local MatrixUtil = require(game.ReplicatedStorage.Services.MatrixUtil)

function rotateFaceClockwiseInPlace(cube, face)
	-- Rotate a nxn face matrix clockwise in-place
	local n = #cube[face]

	for i = 1, n / 2 do
		for j = i, n - i do
			local temp = cube[face][i][j]
			cube[face][i][j] = cube[face][n - j + 1][i]
			cube[face][n - j + 1][i] = cube[face][n - i + 1][n - j + 1]
			cube[face][n - i + 1][n - j + 1] = cube[face][j][n - i + 1]
			cube[face][j][n - i + 1] = temp
		end
	end

	-- Update adjacent faces
	local tempRow = {}
	for i = 1, n do
		tempRow[i] = cube[clockwiseAdjacent(face)][i][1]
		cube[clockwiseAdjacent(face)][i][1] = cube[bottomAdjacent(face)][n - i + 1][1]
		cube[bottomAdjacent(face)][n - i + 1][1] = cube[counterclockwiseAdjacent(face)][i][n]
		cube[counterclockwiseAdjacent(face)][i][n] = cube[topAdjacent(face)][i][1]
		cube[topAdjacent(face)][i][1] = tempRow[i]
	end
end

function rotateFaceCounterClockwiseInPlace(cube, face)
	-- Rotate a nxn face matrix counter-clockwise in-place
	local n = #cube[face]

	for i = 1, n / 2 do
		for j = i, n - i do
			local temp = cube[face][i][j]
			cube[face][i][j] = cube[face][j][n - i + 1]
			cube[face][j][n - i + 1] = cube[face][n - i + 1][n - j + 1]
			cube[face][n - i + 1][n - j + 1] = cube[face][n - j + 1][i]
			cube[face][n - j + 1][i] = temp
		end
	end

	-- Update adjacent faces
	local tempRow = {}
	for i = 1, n do
		tempRow[i] = cube[clockwiseAdjacent(face)][i][1]
		cube[clockwiseAdjacent(face)][i][1] = cube[topAdjacent(face)][i][1]
		cube[topAdjacent(face)][i][1] = cube[counterclockwiseAdjacent(face)][i][n]
		cube[counterclockwiseAdjacent(face)][i][n] = cube[bottomAdjacent(face)][n - i + 1][1]
		cube[bottomAdjacent(face)][n - i + 1][1] = tempRow[i]
	end
end

function clockwiseAdjacent(face)
	local adjacent = {
		Front = "Right",
		Right = "Back",
		Back = "Left",
		Left = "Front",
		Top = "Right",
		Bottom = "Right"
	}
	return adjacent[face]
end

function counterclockwiseAdjacent(face)
	local adjacent = {
		Front = "Left",
		Right = "Front",
		Back = "Right",
		Left = "Back",
		Top = "Left",
		Bottom = "Left"
	}
	return adjacent[face]
end

function topAdjacent(face)
	local adjacent = {
		Front = "Top",
		Right = "Top",
		Back = "Top",
		Left = "Top",
		Top = "Back",
		Bottom = "Front"
	}
	return adjacent[face]
end

function bottomAdjacent(face)
	local adjacent = {
		Front = "Bottom",
		Right = "Bottom",
		Back = "Bottom",
		Left = "Bottom",
		Top = "Front",
		Bottom = "Back"
	}
	return adjacent[face]
end

function printRubiksCube(cube)
	for _, face in ipairs({"Top", "Front", "Bottom", "Back", "Left", "Right"}) do
		print(face .. " Face:")
		for i = 1, #cube[face] do
			local row = ""
			for j = 1, #cube[face][i] do
				row = row .. cube[face][i][j] .. " "
			end
			print(row)
		end
		print("---------------------")
	end
	print("////////////////////")
end

-- Example usage for a 3x3 Rubik's Cube:
local rubiksCube3x3 = {
	Front = {{1, 1, 1}, {1, 1, 1}, {1, 1, 1}},
	Back = {{2, 2, 2}, {2, 2, 2}, {2, 2, 2}},
	Left = {{3, 3, 3}, {3, 3, 3}, {3, 3, 3}},
	Right = {{4, 4, 4}, {4, 4, 4}, {4, 4, 4}},
	Top = {{5, 5, 5}, {5, 5, 5}, {5, 5, 5}},
	Bottom = {{6, 6, 6}, {6, 6, 6}, {6, 6, 6}}
}

--printRubiksCube(rubiksCube3x3)
--rotateFaceClockwiseInPlace(rubiksCube3x3, "Front")
--printRubiksCube(rubiksCube3x3)