local MatrixUtil = {}

--// Methods
-- rotates the give matrix clockwise in place
-- matrix must be an nxn matrix
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

-- rotates the give matrix counterclockwise in place
-- matrix must be an nxn matrix
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

function MatrixUtil.Rotate(matrix: table, clockwise: boolean?)
	if clockwise == nil then clockwise = true end
	if clockwise then
		MatrixUtil.RotateClockwise(matrix)
	else
		MatrixUtil.RotateCounterClockwise(matrix)
	end
end

-- gets the elements in the nth row of the matrix
function MatrixUtil.GetRow(matrix: table, row: number): table
	local elements = {}
	for column = 1, #matrix do
		table.insert(elements, matrix[column][row])
	end
	
	return elements
end

-- gets the elements in the nth column of the matrix
function MatrixUtil.GetColumn(matrix: table, column: number): table
	local elements = {}
	for row = 1, #matrix[1] do
		table.insert(elements, matrix[column][row])
	end

	return elements
end

function MatrixUtil.GetSlice(matrix: table, slice: "Row"|"Col", index: number)
	if slice == "Row" then
		return MatrixUtil.GetRow(matrix, index)
	else
		return MatrixUtil.GetColumn(matrix, index)
	end
end

-- replaces the elements in the nth row
function MatrixUtil.ReplaceRow(matrix: table, row: number, elements: table)
	assert(
		#matrix == #elements, 
		("Number of elements must match width of matrix (got %s, expected %s"):format(#elements, #matrix)
	)
	for column = 1, #matrix do
		matrix[column][row] = elements[column]
	end
end

-- replaces the elements in the nth column
function MatrixUtil.ReplaceColumn(matrix: table, column: number, elements: table)
	assert(
		#matrix[1] == #elements, 
		("Number of elements must match height of matrix (got %s, expected %s"):format(#elements, #matrix[1])
	)
	for row = 1, #matrix[1] do
		matrix[column][row] = elements[row]
	end
end

function MatrixUtil.ReplaceSlice(matrix: table, slice: "Row"|"Col", index: number, elements: table)
	if slice == "Row" then
		return MatrixUtil.ReplaceRow(matrix, index, elements)
	else
		return MatrixUtil.ReplaceColumn(matrix, index, elements)
	end
end

-- creates an nxm matrix with the value in every position
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

-- @debug
-- format prints a matrix
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