--[[
	NOTE: All matricies are rotated 90* counterclockwise to visual representation
	
	TODO: each face should not be fixed, cube can be in any rotation
]]

local TargetMaps = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)

--// Variables
local WHITE = "Top"
local YELLOW = "Bottom"
local BLUE = "Front"
local GREEN = "Back"
local RED = "Left"
local ORANGE = "Right"


--// Maps
TargetMaps.Complete = RubiksCube.new(3).Map

TargetMaps.WhiteCross = {
	{
		{false, "Top", false},
		{"Top", "Top", "Top"},
		{false, "Top", false},
	},
	{
		{false, false, false},
		{"Left", "Left", false},
		{false, false, false},
	},
	{
		{false, false, false},
		{"Right", "Right", false},
		{false, false, false},
	},
	{
		{false, false, false},
		{"Front", "Front", false},
		{false, false, false},
	},
	{
		{false, false, false},
		{"Back", "Back", false},
		{false, false, false},
	},
	{
		{false, false, false},
		{false, "Bottom", false},
		{false, false, false},
	},
}

return TargetMaps