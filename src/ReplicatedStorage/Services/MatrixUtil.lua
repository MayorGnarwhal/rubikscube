local MatrixUtil = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local Collect = require(Services.Collect)


--// Methods
function MatrixUtil.RotateClockwise(matrix: table)
	local n = #matrix

	for i = 1, n / 2 do
		for j = i, n - i do
			local temp = matrix[i][j]
			matrix[i][j] = matrix[j][n - i + 1]
			matrix[j][n - i + 1] = matrix[n - i + 1][n - j + 1]
			matrix[n - i + 1][n - j + 1] = matrix[n - j + 1][i]
			matrix[n - j + 1][i] = temp
		end
	end
end

function MatrixUtil.RotateCounterClockwise(matrix: table)
	local n = #matrix

	for i = 1, n / 2 do
		for j = i, n - i do
			local temp = matrix[i][j]
			matrix[i][j] = matrix[n - j + 1][i]
			matrix[n - j + 1][i] = matrix[n - i + 1][n - j + 1]
			matrix[n - i + 1][n - j + 1] = matrix[j][n - i + 1]
			matrix[j][n - i + 1] = temp
		end
	end
end

function MatrixUtil.GetRow(matrix: table, row: number): table
	local elements = {}
	for column = 1, #matrix do
		table.insert(elements, matrix[column][row])
	end
	
	return elements
end

function MatrixUtil.GetColumn(matrix: table, column: number): table
	local elements = {}
	for row = 1, #matrix[1] do
		table.insert(elements, matrix[column][row])
	end

	return elements
end

function MatrixUtil.ReplaceRow(matrix: table, row: number, elements: table)
	assert(
		#matrix == #elements, 
		("Number of elements must match width of matrix (got %s, expected %s"):format(#elements, #matrix)
	)
	for column = 1, #matrix do
		matrix[column][row] = elements[column]
	end
end

function MatrixUtil.ReplaceColumn(matrix: table, column: number, elements: table)
	assert(
		#matrix[1] == #elements, 
		("Number of elements must match height of matrix (got %s, expected %s"):format(#elements, #matrix[1])
	)
	for row = 1, #matrix[1] do
		matrix[column][row] = elements[row]
	end
end

function MatrixUtil.Copy(tbl: table)
	if type(tbl) == "table" then
		local copy = {}
		for key, value in pairs(tbl) do
			copy[MatrixUtil.Copy(key)] = MatrixUtil.Copy(value)
		end
		return copy
	else
		return tbl
	end
end

function MatrixUtil.Create(size: Vector2, value: any)
	local matrix = {}
	for x = 1, size.X do
		local column = {}
		for y = 1, size.Y do
			table.insert(column, value)
		end
		table.insert(matrix, column)
	end
	
	return matrix
end

function MatrixUtil.Print(matrix: table)
	local n = #matrix
	local m = #matrix[1]
	
	print(string.rep("--", n))
	for y = 1, m do
		local str = ""
		for x = 1, n do
			str ..= matrix[x][y] .. " "
		end
		print(str)
	end
	print(string.rep("--", n))
end

--//
return MatrixUtil