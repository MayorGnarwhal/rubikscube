local RelativeMoves = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local Util = require(Services.Util)

--// Variables
local FaceNormalMap = {
	Top = Enum.NormalId.Top,
	Bottom = Enum.NormalId.Bottom,
	Left = Enum.NormalId.Left,
	Right = Enum.NormalId.Right,
	Back = Enum.NormalId.Front,
	Front = Enum.NormalId.Back,
}

local MoveNormalMap = {
	U = Enum.NormalId.Top,
	D = Enum.NormalId.Bottom,
	L = Enum.NormalId.Left,
	R = Enum.NormalId.Right,
	B = Enum.NormalId.Front,
	F = Enum.NormalId.Back,
}

local NormalMoveMap = {
	[Enum.NormalId.Top] = "U",
	[Enum.NormalId.Bottom] = "D",
	[Enum.NormalId.Left] = "L",
	[Enum.NormalId.Right] = "R",
	[Enum.NormalId.Front] = "F",
	[Enum.NormalId.Back] = "B",
}



--// Helper functions
local function GetMoveNormalId(moveName): Enum.NormalId
	local face = string.sub(moveName, 1, 1)
	local faceNormal = MoveNormalMap[face]

	return faceNormal
end

local function GetRelativeFace(faceNormalId: Enum.NormalId, orientation: CFrame): Enum.NormalId
	if faceNormalId == Enum.NormalId.Front then
		return Util.GetNormalId(-orientation.LookVector)

	elseif faceNormalId == Enum.NormalId.Back then
		return Util.GetNormalId(orientation.LookVector)

	elseif faceNormalId == Enum.NormalId.Right then
		return Util.GetNormalId(orientation.RightVector)

	elseif faceNormalId == Enum.NormalId.Left then
		return Util.GetNormalId(-orientation.RightVector)

	elseif faceNormalId == Enum.NormalId.Top then
		return Util.GetNormalId(orientation.LookVector:Cross(orientation.RightVector))

	elseif faceNormalId == Enum.NormalId.Bottom then
		return Util.GetNormalId(-orientation.LookVector:Cross(orientation.RightVector))

	end
end


--// Methods
-- TODO: this will only work in topFaceName is "Top" or "Bottom". Since this is the only
--       orientations we will have, thats alright
function RelativeMoves.TranslateMove(moveName, frontFaceName, topFaceName)
	local topNormalId = FaceNormalMap[topFaceName]
	local frontNormalId = FaceNormalMap[frontFaceName]

	local faceNormalId = GetMoveNormalId(moveName)
	local relativeOrientation = CFrame.lookAlong(Vector3.zero, -Vector3.fromNormalId(frontNormalId), Vector3.fromNormalId(topNormalId))

	local relativeFaceNormalId = GetRelativeFace(faceNormalId, relativeOrientation)
	local relativeMoveName = NormalMoveMap[relativeFaceNormalId]

	return relativeMoveName .. string.sub(moveName, 2)
end

-- i wish i could tell you why this needs a slight variation
function RelativeMoves.TranslateMove2(moveName, frontFaceName, topFaceName)
	local topNormalId = FaceNormalMap[topFaceName]
	local frontNormalId = FaceNormalMap[frontFaceName]

	-- its a mess
	local lookVector = -Vector3.fromNormalId(frontNormalId)
	if topFaceName == "Top" and (frontFaceName == "Right" or frontFaceName == "Left") then
		lookVector *= -1
	end

	local faceNormalId = GetMoveNormalId(moveName)
	local relativeOrientation = CFrame.lookAlong(Vector3.zero, lookVector, Vector3.fromNormalId(topNormalId))

	local relativeFaceNormalId = GetRelativeFace(faceNormalId, relativeOrientation)
	local relativeMoveName = NormalMoveMap[relativeFaceNormalId]

	return relativeMoveName .. string.sub(moveName, 2)
end

function RelativeMoves.TranslateAlgorithm(algorithm: table, frontFaceName, topFaceName)
	local relativeMoves = {}
	
	for i, moveName in ipairs(algorithm) do
		local relativeMoveName = RelativeMoves.TranslateMove(moveName, frontFaceName, topFaceName)
		table.insert(relativeMoves, relativeMoveName)
	end
	
	return relativeMoves
end

function RelativeMoves.TranslateAlgorithm2(algorithm: table, frontFaceName, topFaceName)
	local relativeMoves = {}

	for i, moveName in ipairs(algorithm) do
		local relativeMoveName = RelativeMoves.TranslateMove2(moveName, frontFaceName, topFaceName)
		table.insert(relativeMoves, relativeMoveName)
	end

	return relativeMoves
end


function RelativeMoves.Inverse(moveName: string)
	if string.sub(moveName, -1) == "2" then
		return moveName
	elseif string.sub(moveName, -1) == "i" then
		return string.sub(moveName, 1, -2)
	else
		return moveName .. "i"
	end
end

--//
return RelativeMoves