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

Moves.M = {{Vector3.new(2, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.Mi = {{Vector3.new(2, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
Moves.M2 = CombineMoves(Moves.M, Moves.M)

Moves.R = {{Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.Ri = {{Vector3.new(3, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
Moves.R2 = CombineMoves(Moves.R, Moves.R)
Moves.Rr = CombineMoves(Moves.R, Moves.M)
Moves.Rri = CombineMoves(Moves.Ri, Moves.Mi)

Moves.L = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Top}}
Moves.Li = {{Vector3.new(1, 3, 3), Enum.NormalId.Back, Enum.NormalId.Bottom}}
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

return Moves