local Controllers = game.ReplicatedStorage.Controllers
local CubeSolver = require(Controllers.CubeSolver)

game.Players.PlayerAdded:Connect(function(player)
	-- manually copy StarterGui because CharacterAutoLoads is disabled
	local playerGui = player:WaitForChild("PlayerGui")
	for i, item in pairs(game.StarterGui:GetChildren()) do
		item:Clone().Parent = playerGui
	end
end)