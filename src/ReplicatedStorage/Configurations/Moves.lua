--[[
	A map of all possible moves and their arguments to perform that rotation
]]

local Moves = {}

local function CombineMoves(...): table
	local newMove = {}
	for i, move in pairs({...}) do
		for j, args in ipairs(move) do
			table.insert(newMove, args)
		end
	end
	return newMove
end

function Moves.Inverse(moveName)
	local lastChar = string.sub(moveName, -1)
	if lastChar == "i" then
		return string.sub(moveName, 1, -2)
	elseif lastChar == "2" then
		return moveName
	else
		return moveName .. "i"
	end
end

Moves.FaceName = {
	Top = "U",
	Bottom = "D",
	Back = "F",
	Front = "B",
	Left = "L",
	Right = "R",
}

-- slice rotations
Moves.M = {{Vector3.new(2, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.Mi = {{Vector3.new(2, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
Moves.M2 = CombineMoves(Moves.M, Moves.M)

Moves.E = {{Vector3.new(1, 2, 3), Enum.NormalId.Back, Enum.NormalId.Right}}
Moves.Ei = {{Vector3.new(1, 2, 3), Enum.NormalId.Back, Enum.NormalId.Left}}
Moves.E2 = CombineMoves(Moves.E, Moves.E)

Moves.S = {{Vector3.new(1, 3, 2), Enum.NormalId.Top, Enum.NormalId.Right}}
Moves.Si = {{Vector3.new(1, 3, 2), Enum.NormalId.Top, Enum.NormalId.Left}}
Moves.S2 = CombineMoves(Moves.S, Moves.S)

-- face rotations
Moves.R = {{Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.Ri = {{Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
Moves.R2 = CombineMoves(Moves.R, Moves.R)
Moves.Rr = CombineMoves(Moves.R, Moves.M)
Moves.Rri = CombineMoves(Moves.Ri, Moves.Mi)

Moves.L = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
Moves.Li = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.L2 = CombineMoves(Moves.L, Moves.L)
Moves.Ll = CombineMoves(Moves.L, Moves.M)
Moves.Lli = CombineMoves(Moves.Li, Moves.Mi)

Moves.U = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Left}}
Moves.Ui = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Right}}
Moves.U2 = CombineMoves(Moves.U, Moves.U)

Moves.D = {{Vector3.new(3, 1, 3), Enum.NormalId.Back, Enum.NormalId.Right}}
Moves.Di = {{Vector3.new(3, 1, 3), Enum.NormalId.Back, Enum.NormalId.Left}}
Moves.D2 = CombineMoves(Moves.D, Moves.D)

Moves.F = {{Vector3.new(1, 3, 3), Enum.NormalId.Top, Enum.NormalId.Right}}
Moves.Fi = {{Vector3.new(1, 3, 3), Enum.NormalId.Top, Enum.NormalId.Left}}
Moves.F2 = CombineMoves(Moves.F, Moves.F)

Moves.B = {{Vector3.new(3, 3, 1), Enum.NormalId.Top, Enum.NormalId.Left}}
Moves.Bi = {{Vector3.new(3, 3, 1), Enum.NormalId.Top, Enum.NormalId.Right}}
Moves.B2 = CombineMoves(Moves.B, Moves.B)

-- whole cube rotations
Moves.x = CombineMoves(Moves.Li, Moves.M, Moves.R)
Moves.xi = CombineMoves(Moves.L, Moves.Mi, Moves.Ri)
Moves.x2 = CombineMoves(Moves.x, Moves.x)

Moves.y = CombineMoves(Moves.U, Moves.Ei, Moves.Di)
Moves.yi = CombineMoves(Moves.Ui, Moves.E, Moves.D)
Moves.y2 = CombineMoves(Moves.y, Moves.y)

Moves.z = CombineMoves(Moves.F, Moves.S, Moves.Bi)
Moves.zi = CombineMoves(Moves.Fi, Moves.Si, Moves.B)
Moves.z2 = CombineMoves(Moves.z, Moves.z)

return Moves