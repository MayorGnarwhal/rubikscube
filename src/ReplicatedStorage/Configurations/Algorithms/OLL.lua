local OLL = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local MatrixUtil = require(Services.MatrixUtil)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)


--// Variables
OLL.Algorithms = {
	YellowCross = {
		IShape = {
			Name = "I-Shape",
			State = {
				{false, "Bottom", false},
				{false, "Bottom", false},
				{false, "Bottom", false},
			},
			Moves = {"F", "R", "U", "Ri", "Ui", "Fi"},
		},
		LShape = {
			Name = " Backwards L-Shape",
			State = {
				{false, "Bottom", false},
				{"Bottom", "Bottom", false},
				{false, false, false},
			},
			Moves = {"F", "U", "R", "Ui", "Ri", "Fi"},
		},
	},
	YellowSide = {
		OneAlgorithm = {
			State = {
				{false, "Bottom", "Bottom"},
				{"Bottom", "Bottom", "Bottom"},
				{false, "Bottom", false},
			},
			Moves = {"R", "U", "Ri", "U", "R", "U2", "Ri"},
		},
		
		--Cross1 = {
		--	State = {
		--		Face = {
		--			{false, "Bottom", false},
		--			{"Bottom", "Bottom", "Bottom"},
		--			{false, "Bottom", false},
		--		},
		--		Sides = {
		--			{"Bottom", false, false},
		--			{false, false, "Bottom"},
		--			{false, false, false},
		--			{"Bottom", false, "Bottom"},
		--		}
		--	},
		--	Moves = {"R", "U2", "R2", "U", "R2", "Ui", "R2", "U2", "R"},
		--},
		--Cross2 = {
		--	State = {
		--		Face = {
		--			{false, "Bottom", false},
		--			{"Bottom", "Bottom", "Bottom"},
		--			{false, "Bottom", false},
		--		},
		--		Sides = {
		--			{"Bottom", false, "Bottom"},
		--			{false, false, false},
		--			{"Bottom", false, "Bottom"},
		--			{false, false, false},
		--		}
		--	},
		--	Moves = {"R", "U2", "Ri", "Ui", "R", "U", "Ri", "Ui", "R", "Ui", "Ri"},
		--},
	},
}

--OLL.LayerSideOrder = {"Back", "Left", "Front", "Right"}
OLL.LayerSideOrder = {"Front", "Left", "Back", "Right"}


--// Helper functions
local function StateMatchHelper(cube: table, targetState: table, strict: boolean)
	local bottomFace = cube.Bottom
	
	for x = 1, #targetState do
		for y = 1, #targetState[x] do
			local cell = targetState[x][y]
			if cell and cell ~= bottomFace[x][y] then
				return false
			elseif strict and not cell and bottomFace[x][y] == "Bottom" then
				-- this is ugly but should work for now
				return false
			end
		end
	end
	
	return true
end

local function StateMatches(cube: table, targetState: table, strict: boolean)
	targetState = Util.DeepCopy(targetState)
	
	for i, frontFace in ipairs(OLL.LayerSideOrder) do
		if StateMatchHelper(cube, targetState, strict) then
			return frontFace
		end
		
		MatrixUtil.Rotate(targetState)
	end
end

local function MatchRightCorner(cube: table)
	for i, faceName in ipairs(OLL.LayerSideOrder) do
		if cube[faceName][3][3] == "Bottom" then
			return faceName
		end
	end
end


--// Methods
function OLL.YellowCross(cube: table)
	for key, algorithm in pairs(OLL.Algorithms.YellowCross) do
		local frontFace = StateMatches(cube, algorithm.State)
		if frontFace then
			local description = ("There is the %s shape on the top face. Put the %s face in front, and solve the white cross.")
				:format(algorithm.Name, FaceColorMap[frontFace])
			return algorithm.Moves, frontFace, description
		end
	end
	
	local description = "There is no I or L shape on the top face. Apply the L-shape algorithm to create an I-Shape."
	return OLL.Algorithms.YellowCross.LShape.Moves, nil, description
end

function OLL.OneAlgorithmOrientation(cube: table)
	local algorithm = OLL.Algorithms.YellowSide.OneAlgorithm
	
	local frontFace = StateMatches(cube, algorithm.State, true)
	if frontFace then
		local description = "There is one Yellow corner on the top face. Put Yellow corner in the bottom left."
		return algorithm.Moves, frontFace, description
	end
	
	frontFace = MatchRightCorner(cube)
	
	local description = ("There is not exactly one Yellow corner on the top face. However, the %s face has a Yellow in the top left corner.")
		:format(FaceColorMap[frontFace])
	return algorithm.Moves, frontFace, description
end

--//
return OLL