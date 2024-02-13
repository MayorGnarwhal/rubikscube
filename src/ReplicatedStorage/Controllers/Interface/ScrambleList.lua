local ScrambleList = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local Util = require(Services.Util)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Display = PlayerGui:WaitForChild("MainGui"):WaitForChild("Scramble")


--// Methods
function ScrambleList.Show(moves: table)
	local scramble = ""
	for i, moveName in ipairs(moves) do
		scramble ..= Util.FormatMoveName(moveName) .. "  "
	end
	
	Display.Moves.Text = scramble
	Display.Visible = true
end

function ScrambleList.Hide()
	Display.Visible = false
end


--// Setup
ScrambleList.Hide()

--//
return ScrambleList