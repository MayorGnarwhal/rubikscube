local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local Controllers = game.ReplicatedStorage.Controllers
require(Controllers.CubeController)
--require(Controllers.CubeMap)



-- testing
local MatrixUtil = require(game.ReplicatedStorage.Services.MatrixUtil)

local matrix = {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}}
--MatrixUtil.Print(matrix)
--local row = MatrixUtil.GetRow(matrix, 1)
--MatrixUtil.ReplaceColumn(matrix, 3, row)
--MatrixUtil.Print(matrix)
--print(MatrixUtil.GetRow(matrix, 2))
--print(MatrixUtil.GetColumn(matrix, 2))

--MatrixUtil.Print(matrix)
--MatrixUtil.RotateCounterClockwise(matrix)
--MatrixUtil.Print(matrix)