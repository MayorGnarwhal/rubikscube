local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local Controllers = game.ReplicatedStorage.Controllers
require(Controllers.CubeController)
require(Controllers.Interface)


--local Benchmark = require(Controllers.Benchmark)
--Benchmark.Run(1000)