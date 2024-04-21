--[[
	NOTES:
		- Front and Back faces are swapped with their map names
		- All matricies appear rotated 90* counterclockwise and flipped horizontally
]]

local TargetMaps = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local RubiksCube = require(Services.RubiksCube)

--// Variables
TargetMaps.FaceOrder = {"Top", "Left", "Right", "Front", "Back", "Bottom"}


--// Methods
function TargetMaps.Merge(map1, map2)
	local _, face = next(map1)
	local n = #face
	
	local newMap = {}
	
	for i, face in ipairs(map1) do
		local newFace = {}
		table.insert(newMap, newFace)
		
		for x = 1, n do
			local newCol = {}
			table.insert(newFace, newCol)
			
			for y = 1, n do
				local element = map1[i][x][y] or map2[i][x][y] or false
				table.insert(newCol, element)
			end
		end
	end
	
	return newMap
end

function TargetMaps.CreateEmpty(n)
	local m = math.ceil(n / 2)
	
	local map = {}
	for i, faceName in ipairs(TargetMaps.FaceOrder) do
		local face = {}
		table.insert(map, face)
		
		for x = 1, n do
			local col = {}
			table.insert(face, col)
			
			for y = 1, n do
				local element = (x == m and y == m and faceName) or false
				table.insert(col, element)
			end
		end
	end
	
	return map
end


--// Hard Coded maps
TargetMaps.Complete = RubiksCube.new(3).Map

TargetMaps.WhiteCross = {
	{
		{false, "Top", false},
		{"Top", "Top", "Top"},
		{false, "Top", false},
	}, {
		{false, false, false},
		{"Left", "Left", false},
		{false, false, false},
	}, {
		{false, false, false},
		{"Right", "Right", false},
		{false, false, false},
	}, {
		{false, false, false},
		{"Front", "Front", false},
		{false, false, false},
	}, {
		{false, false, false},
		{"Back", "Back", false},
		{false, false, false},
	}, {
		{false, false, false},
		{false, "Bottom", false},
		{false, false, false},
	},
}

TargetMaps.Daisy = {
	{
		{false, false, false},
		{false, "Top", false},
		{false, false, false},
	}, {
		{false, false, false},
		{false, "Left", false},
		{false, false, false},
	}, {
		{false, false, false},
		{false, "Right", false},
		{false, false, false},
	}, {
		{false, false, false},
		{false, "Front", false},
		{false, false, false},
	}, {
		{false, false, false},
		{false, "Back", false},
		{false, false, false},
	}, {
		{false, "Top", false},
		{"Top", "Bottom", "Top"},
		{false, "Top", false},
	},
}

TargetMaps.WhiteCorners = {
	[1] = {
		{
			{false, "Top", "Top"},
			{"Top", "Top", "Top"},
			{false, "Top", false},
		}, {
			{false, false, false},
			{"Left", "Left", false},
			{"Left", false, false},
		}, {
			{false, false, false},
			{"Right", "Right", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Front", "Front", false},
			{false, false, false},
		}, {
			{"Back", false, false},
			{"Back", "Back", false},
			{false, false, false},
		}, {
			{false, false, false},
			{false, "Bottom", false},
			{false, false, false},
		},
	},
	[2] = {
		{
			{false, "Top", false},
			{"Top", "Top", "Top"},
			{false, "Top", "Top"},
		}, {
			{false, false, false},
			{"Left", "Left", false},
			{false, false, false},
		}, {
			{"Right", false, false},
			{"Right", "Right", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Front", "Front", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Back", "Back", false},
			{"Back", false, false},
		}, {
			{false, false, false},
			{false, "Bottom", false},
			{false, false, false},
		},
	},
	[3] = {
		{
			{false, "Top", false},
			{"Top", "Top", "Top"},
			{"Top", "Top", false},
		}, {
			{false, false, false},
			{"Left", "Left", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Right", "Right", false},
			{"Right", false, false},
		}, {
			{"Front", false, false},
			{"Front", "Front", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Back", "Back", false},
			{false, false, false},
		}, {
			{false, false, false},
			{false, "Bottom", false},
			{false, false, false},
		},
	},
	[4] = {
		{
			{"Top", "Top", false},
			{"Top", "Top", "Top"},
			{false, "Top", false},
		}, {
			{"Left", false, false},
			{"Left", "Left", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Right", "Right", false},
			{false, false, false},
		}, {
			{false, false, false},
			{"Front", "Front", false},
			{"Front", false, false},
		}, {
			{false, false, false},
			{"Back", "Back", false},
			{false, false, false},
		}, {
			{false, false, false},
			{false, "Bottom", false},
			{false, false, false},
		},
	},
}

TargetMaps.FirstLayer = {
	{
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
	}, {
		{"Left", false, false},
		{"Left", "Left", false},
		{"Left", false, false},
	}, {
		{"Right", false, false},
		{"Right", "Right", false},
		{"Right", false, false},
	}, {
		{"Front", false, false},
		{"Front", "Front", false},
		{"Front", false, false},
	}, {
		{"Back", false, false},
		{"Back", "Back", false},
		{"Back", false, false},
	}, {
		{false, false, false},
		{false, "Bottom", false},
		{false, false, false},
	},
}

TargetMaps.FirstTwoLayers = {
	{
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
	}, {
		{"Left", "Left", false},
		{"Left", "Left", false},
		{"Left", "Left", false},
	}, {
		{"Right", "Right", false},
		{"Right", "Right", false},
		{"Right", "Right", false},
	}, {
		{"Front", "Front", false},
		{"Front", "Front", false},
		{"Front", "Front", false},
	}, {
		{"Back", "Back", false},
		{"Back", "Back", false},
		{"Back", "Back", false},
	}, {
		{false, false, false},
		{false, "Bottom", false},
		{false, false, false},
	},
}

TargetMaps.YellowCross = {
	{
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
	}, {
		{"Left", "Left", false},
		{"Left", "Left", false},
		{"Left", "Left", false},
	}, {
		{"Right", "Right", false},
		{"Right", "Right", false},
		{"Right", "Right", false},
	}, {
		{"Front", "Front", false},
		{"Front", "Front", false},
		{"Front", "Front", false},
	}, {
		{"Back", "Back", false},
		{"Back", "Back", false},
		{"Back", "Back", false},
	}, {
		{false, "Bottom", false},
		{"Bottom", "Bottom", "Bottom"},
		{false, "Bottom", false},
	},
}

TargetMaps.OrientedLastLayer = {
	{
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
	}, {
		{"Left", "Left", false},
		{"Left", "Left", false},
		{"Left", "Left", false},
	}, {
		{"Right", "Right", false},
		{"Right", "Right", false},
		{"Right", "Right", false},
	}, {
		{"Front", "Front", false},
		{"Front", "Front", false},
		{"Front", "Front", false},
	}, {
		{"Back", "Back", false},
		{"Back", "Back", false},
		{"Back", "Back", false},
	}, {
		{"Bottom", "Bottom", "Bottom"},
		{"Bottom", "Bottom", "Bottom"},
		{"Bottom", "Bottom", "Bottom"},
	},
}

TargetMaps.SolvedCorners = {
	{
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
		{"Top", "Top", "Top"},
	}, {
		{"Left", "Left", "Left"},
		{"Left", "Left", false},
		{"Left", "Left", "Left"},
	}, {
		{"Right", "Right", "Right"},
		{"Right", "Right", false},
		{"Right", "Right", "Right"},
	}, {
		{"Front", "Front", "Front"},
		{"Front", "Front", false},
		{"Front", "Front", "Front"},
	}, {
		{"Back", "Back", "Back"},
		{"Back", "Back", false},
		{"Back", "Back", "Back"},
	}, {
		{"Bottom", "Bottom", "Bottom"},
		{"Bottom", "Bottom", "Bottom"},
		{"Bottom", "Bottom", "Bottom"},
	},
}

--//
return TargetMaps