local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

local Controllers = game.ReplicatedStorage.Controllers
require(Controllers.CubeController)
require(Controllers.Interface)