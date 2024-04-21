local Instructions = {}
Instructions.__index = Instructions

--// Dependencies
local Services = game.ReplicatedStorage.Services
local RelativeMoves = require(Services.RelativeMoves)

export type Face = "Front" | "Back" | "Left" | "Right" | "Top" | "Bottom"

export type Instruction = {
	Description: string,
	Stage: "Cross" | "First Layer" | "F2L" | "OLL" | "PLL",
	FrontFace: Face,
	TopFace: Face,
	Algorithm: table,
	Timestamp: number,
}


--// Constructor
function Instructions.new()
	local self = setmetatable({
		_list = {},
	}, Instructions)
	
	return self
end

function Instructions.fromList(list)
	local self = setmetatable({
		_list = list,
	}, Instructions)

	return self
end


--// Methods
function Instructions:Insert(instruction: Instruction)
	instruction.FrontFace = instruction.FrontFace or self:CurrentFrontFace()
	instruction.TopFace = instruction.TopFace or self:CurrentTopFace()
	instruction.Timestamp = instruction.Timestamp or os.clock()
	
	table.insert(self._list, instruction)
end

function Instructions:CurrentFrontFace(): Face
	local lastInstruction = self._list[#self._list]
	return lastInstruction and lastInstruction.FrontFace or "Back"
end

function Instructions:CurrentTopFace(): Face
	local lastInstruction = self._list[#self._list]
	return lastInstruction and lastInstruction.TopFace or "Top"
end

function Instructions:CurrentDescription()
	local lastInstruction = self._list[#self._list]
	return lastInstruction and lastInstruction.Description
end

function Instructions:CurrentStage()
	local lastInstruction = self._list[#self._list]
	return lastInstruction and lastInstruction.Stage
end

function Instructions:Algorithm()
	local lastInstruction = self._list[#self._list]
	return lastInstruction and lastInstruction.Algorithm or {}
end

function Instructions:RelativeAlgorithm()
	return RelativeMoves.TranslateAlgorithm(self:Algorithm(), self:CurrentFrontFace(), self:CurrentTopFace())
end

function Instructions:Next()
	assert(not self:IsEmpty(), "Instruction list is empty")
	
	local instruction = self._list[1]
	table.remove(self._list, 1)
	
	return instruction
end

function Instructions:IsEmpty()
	return #self._list == 0
end

function Instructions:Get()
	return self._list
end

function Instructions:GetStep(index)
	return self._list[index]
end

function Instructions:__len()
	return #self._list
end

--//
return Instructions