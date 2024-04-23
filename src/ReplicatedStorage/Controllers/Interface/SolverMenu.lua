local SolverMenu = {}

--// Dependencies
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Controllers = game.ReplicatedStorage.Controllers
local CubeController = require(Controllers.CubeController)
local InterfaceUtil = require(Controllers.Interface.InterfaceUtil)
local CubePainter = require(Controllers.Interface.CubePainter)
local CubeSolver = require(Controllers.CubeSolver)

local Services = game.ReplicatedStorage.Services
local RelativeMoves = require(Services.RelativeMoves)
local RichTextColor = require(Services.RichTextColor)
local Instructions = require(Services.Instructions)
local RubiksCube = require(Services.RubiksCube)
local Collect = require(Services.Collect)
local Slider = require(Services.Slider)
local Audio = require(Services.Audio)
local Tween = require(Services.Tween)
local Util = require(Services.Util)

local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)
local Palettes = require(Configurations.Palettes)
local Moves = require(Configurations.Moves)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Menu = PlayerGui:WaitForChild("Menus"):WaitForChild("Solver")
local Walkthrough = Menu:WaitForChild("Walkthrough")
local Breakdown = Menu:WaitForChild("Breakdown")
local HomePage = Menu:WaitForChild("HomePage")
local MinimizeButton = Menu:WaitForChild("Minimize"):WaitForChild("Input")

local SolveOptions = HomePage:WaitForChild("SolveOptions")
local Header = Walkthrough:WaitForChild("Header")
local Content = Walkthrough:WaitForChild("Content")
local Progress = Walkthrough:WaitForChild("Progress")
local ContextMenu = Walkthrough:WaitForChild("ContextMenu")
local AlgorithmList = Content:WaitForChild("Algorithm"):WaitForChild("List")
local OrientationInfo = Content:WaitForChild("Orientation")
local LoadSpinner = Walkthrough:WaitForChild("LoadSpinner")

local TemplateMoveItem = AlgorithmList:WaitForChild("Move"):Clone()

--// Variables
local IsSolving = false
local IsMaximized = true
local AutoPlayback = false

local AutoPlayDebounce = false

local StageCache = {}
local StageIndex = 0

local InstructionCache = Instructions.new()
local CurrentInstruction

local DisplayedAlgorithm = {}
local AlgorithmItems = {}
local AlgorithmIndex = 0

local PreviousRotationSpeed

local LoadConnect
local PlaybackConnect

local SolveStats = {}

local SpeedSlider = Slider.new(ContextMenu.Slider.Container, {
	SliderData = {
		Start = 0,
		End = 5,
		Increment = 0.1,
	},
	MoveType = "Instant",
	Axis = "X",
	Padding = 0,
})


--// Helper functions
local function DisplayLoading()
	if LoadConnect then return end
	
	LoadSpinner.Visible = true
	LoadConnect = RunService.Heartbeat:Connect(function(dt)
		LoadSpinner.Rotation += 60 * dt
	end)
end

local function StopLoading()
	if LoadConnect then
		LoadSpinner.Visible = false
		LoadConnect:Disconnect()
		LoadConnect = nil
	end
end

local StageOrder = {"Cross", "First Layer", "F2L", "OLL", "PLL"}
local StageNames = {
	["Cross"] = "White Cross", 
	["First Layer"] = "First Layer", 
	["F2L"] = "Second Layer", 
	["OLL"] = "Orient Last Layer", 
	["PLL"] = "Permute Last Layer",
}

local function UpdateProgress()
	local lastInstruction = InstructionCache:GetStep(StageIndex)
	local currentStage = lastInstruction.Stage
	local stepIndex = table.find(StageOrder, currentStage)
	
	Header.Title.Text = StageNames[currentStage]
	
	for index, stageName in ipairs(StageOrder) do
		local item = Progress:FindFirstChild(stageName)
		item.Bubble.BackgroundColor3 = (stepIndex > index and Color3.fromRGB(85, 255, 0) or Color3.fromRGB(255, 255, 255))
		if index == #StageOrder then
			item.Bar.Progress.Size = (lastInstruction.LastInstruction and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 1))
		else
			item.Bar.Progress.Size = (stepIndex > index and UDim2.fromScale(1, 1) or UDim2.fromScale(0, 1))
		end
	end
end

local function PopulateAlgorithm(algorithm: table, fromEnd: boolean?)
	Collect(AlgorithmList:GetChildren()):whereInstanceOf(TemplateMoveItem.ClassName):Destroy()
	
	DisplayedAlgorithm = algorithm
	AlgorithmIndex = fromEnd and #algorithm or 0
	
	for i, moveName in ipairs(algorithm) do
		local item = TemplateMoveItem:Clone()
		item.LayoutOrder = i
		item.Text = Util.FormatMoveName(moveName)
		item.TextColor3 = fromEnd and Color3.new(0, 255, 255) or Color3.fromRGB(255, 255, 255)
		item.Parent = AlgorithmList
		
		AlgorithmItems[i] = item
	end
end

local function ShowSolveBreakdown()
	SolverMenu.ToggleAutoPlayback(false)
	
	local solveTime = SolveStats.SolveFinish - SolveStats.Start
	local computeTime = SolveStats.ComputeFinish - SolveStats.Start
	
	Breakdown.Content.SolveTime.Value.Text = Util.ClockTime(solveTime)
	Breakdown.Content.ComputeTime.Value.Text = Util.ClockTime(computeTime)
	Breakdown.Content.NumMoves.Value.Text = SolveStats.NumMoves
	
	HomePage.Visible = false
	Walkthrough.Visible = false
	Breakdown.Visible = true
end


--// Methods
function SolverMenu.Maximize(instant: boolean?)
	if IsMaximized then return end
	IsMaximized = true

	MinimizeButton.Title.Text = ">"

	TweenService:Create(
		Menu,
		TweenInfo.new(instant and 0 or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(1, 1)}
	):Play()
end

function SolverMenu.Minimize(instant: boolean?)
	if not IsMaximized then return end
	IsMaximized = false

	MinimizeButton.Title.Text = "<"

	TweenService:Create(
		Menu,
		TweenInfo.new(instant and 0 or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.new(1, Menu.AbsoluteSize.X + 10, 1, 0)}
	):Play()
end

function SolverMenu.Restart()
	HomePage.Visible = true
	Walkthrough.Visible = false
	Breakdown.Visible = false
	
	SolverMenu.ToggleAutoPlayback(false)
	
	if PreviousRotationSpeed then
		CubeController.CurrentCube().RotationSpeed = PreviousRotationSpeed
	end
	CubeController.SetMovementLock(false)
	IsSolving = false
end

function SolverMenu.DisplayStage(index, fromEnd: boolean?)
	if index <= 0 then return end
	if #InstructionCache == 0 then return end
	
	local previousInstruction = InstructionCache:GetStep(index - 1)
	if previousInstruction and previousInstruction.FinalInstruction then
		SolveStats.SolveFinish = os.clock()
		
		ShowSolveBreakdown()
		return
	end
	
	if not StageCache[index] then
		DisplayLoading()
		repeat task.wait() until StageCache[index]
		StopLoading()
	end
	
	local cube = StageCache[index]
	local instruction = InstructionCache:GetStep(index)
	if not (cube and instruction) then
		warn("Failed to display stage:", index)
		return
	end
	
	AutoPlayDebounce = true
	local debounceDelay = math.min(SpeedSlider:GetValue() * 2, #instruction.Algorithm)
	task.delay(debounceDelay, function()
		AutoPlayDebounce = false
	end)
	
	local topNormalId = Enum.NormalId[instruction.TopFace]
	local frontNormalId = Enum.NormalId[instruction.FrontFace]
	
	OrientationInfo.Title.Text = RichTextColor.Apply(("Orientation: Top %s, Front %s")
		:format(FaceColorMap[instruction.TopFace], FaceColorMap[instruction.FrontFace]))
	
	local orientSpeed = SpeedSlider:GetValue() / 2
	CubeController.CurrentCube():Orient(topNormalId, Enum.NormalId.Top, orientSpeed)
	CubeController.CurrentCube():Orient(frontNormalId, Enum.NormalId.Back, orientSpeed)
	
	StageIndex = index
	CurrentInstruction = instruction
	
	local description = RichTextColor.Apply(instruction.Description)
	Content.Description.Text = description
	
	local algorithm = RelativeMoves.TranslateAlgorithm2(instruction.Algorithm, instruction.FrontFace, instruction.TopFace)

	PopulateAlgorithm(algorithm, fromEnd)
	UpdateProgress()
end

function SolverMenu.BeginSolve()
	if IsSolving then return end
	
	SolveStats = {
		Start = os.clock(),
		ComputeFinish = nil,
		SolveFinish = nil,
		NumMoves = 0,
	}
	
	StageIndex = 0
	
	IsSolving = true
	CubeController.SetMovementLock(true)
	
	table.clear(StageCache)
	
	local cube = CubeController.CurrentCube()
	cube:Orient(Enum.NormalId.Top, Enum.NormalId.Top)
	cube:Orient(Enum.NormalId.Back, Enum.NormalId.Back)
	
	PreviousRotationSpeed = cube.RotationSpeed
	cube.RotationSpeed = SpeedSlider:GetValue()
	
	InstructionCache = Instructions.new()
	local lastInstructionIndex = 0
	
	SolverMenu.ToggleAutoPlayback(false)
	
	HomePage.Visible = false
	Walkthrough.Visible = true
	Breakdown.Visible = false
	DisplayLoading()
	
	for index, stageName in ipairs(CubeSolver.SolveOrder) do
		InstructionCache = CubeSolver.SolveStage(cube.Map, stageName, InstructionCache:Get())
		
		StopLoading()
		
		for i = lastInstructionIndex + 1, #InstructionCache do
			cube = RubiksCube.fromMap(Util.DeepCopy(cube.Map))
			
			local instruction = InstructionCache:GetStep(i)
			
			for j, moveName in ipairs(instruction.Algorithm) do
				cube:Move(Moves[moveName])
				SolveStats.NumMoves += 1
			end
			
			StageCache[i] = cube
		end
		
		lastInstructionIndex = #InstructionCache
		
		if StageIndex == 0 and #InstructionCache > 0 then
			SolverMenu.DisplayStage(1)
		end
	end
	
	SolveStats.ComputeFinish = os.clock()
	
	if #InstructionCache > 0 then
		InstructionCache:GetStep(#InstructionCache).FinalInstruction = true
	else
		SolveStats.SolveFinish = os.clock()
		SolveStats.ComputeFinish = os.clock()
		ShowSolveBreakdown()
	end
end

function SolverMenu.StepAlgorithm()
	if CubeController.CurrentCube().Rotating then return end
	
	AlgorithmIndex += 1
	local move = DisplayedAlgorithm[AlgorithmIndex]
	if move then
		local moveItem = AlgorithmItems[AlgorithmIndex]
		moveItem.TextColor3 = Color3.fromRGB(0, 255, 255)
		
		CubeController.Move(move)
	else
		SolverMenu.DisplayStage(StageIndex + 1)
	end
end

function SolverMenu.StepAlgorithmBack()
	if CubeController.CurrentCube().Rotating then return end
	
	local move = DisplayedAlgorithm[AlgorithmIndex]
	if move then
		local moveItem = AlgorithmItems[AlgorithmIndex]
		moveItem.TextColor3 = Color3.fromRGB(255, 255, 255)
		
		local inverseMove = RelativeMoves.Inverse(move)
		CubeController.Move(inverseMove, PreviousRotationSpeed)
		
		AlgorithmIndex -= 1
	else
		SolverMenu.DisplayStage(StageIndex - 1, true)
	end
end

function SolverMenu.ToggleAutoPlayback(enabled: boolean?)
	if enabled == nil then enabled = not AutoPlayback end
	
	AutoPlayback = enabled
	
	if PlaybackConnect then
		PlaybackConnect:Disconnect()
	end
	
	if AutoPlayback then
		PlaybackConnect = RunService.Heartbeat:Connect(function()
			if not AutoPlayDebounce and not CubeController.CurrentCube().Rotating then
				SolverMenu.StepAlgorithm()
			end
		end)
		
		ContextMenu.Playback.Pause.Visible = true
		ContextMenu.Playback.Play.Visible = false
		ContextMenu.Playback.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	else
		ContextMenu.Playback.Pause.Visible = false
		ContextMenu.Playback.Play.Visible = true
		ContextMenu.Playback.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	end
end


--// Slider
SpeedSlider:OverrideValue(1)
SpeedSlider:Track()

local function updateSliderSpeed(speed)
	ContextMenu.Slider.Value.Text = ("%.1f seconds"):format(speed)
	if IsSolving then
		CubeController.CurrentCube().RotationSpeed = speed
	end
end

SpeedSlider.Changed:Connect(updateSliderSpeed)
SpeedSlider.Released:Connect(updateSliderSpeed)
updateSliderSpeed(SpeedSlider:GetValue())


--// Setup
ContextMenu.StepNext.MouseButton1Click:Connect(function()
	--Audio.Play(Audio.Sounds.GuiClick)
	-- TODO: this sound annoys me
	SolverMenu.StepAlgorithm()
end)

ContextMenu.StepBack.MouseButton1Click:Connect(function()
	--Audio.Play(Audio.Sounds.GuiClick)
	SolverMenu.StepAlgorithmBack()
end)

ContextMenu.Playback.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	SolverMenu.ToggleAutoPlayback()
end)

InterfaceUtil.HoverUnderline(Breakdown.ContextMenu.Continue)
Breakdown.ContextMenu.Continue.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	SolverMenu.Restart()
end)

for i, toggle in ipairs(SolveOptions:GetChildren()) do
	if toggle:IsA("TextButton") then
		InterfaceUtil.HoverUnderline(toggle)
	end
end

SolveOptions.Solve.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	SolverMenu.BeginSolve()
end)

SolveOptions.Scramble.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubeController.Scramble()
end)

SolveOptions.Paint.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	CubePainter.OpenPainter()
end)

MinimizeButton.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	if IsMaximized then
		SolverMenu.Minimize()
	else
		SolverMenu.Maximize()
	end
end)

MinimizeButton.MouseEnter:Connect(function()
	Audio.Play(Audio.Sounds.HoverEnter)
	TweenService:Create(MinimizeButton, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.3, 0)}):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
	TweenService:Create(MinimizeButton, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(0.4, 0)}):Play()
end)

Header.Cancel.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	SolverMenu.Restart()
end)

SolverMenu.ToggleAutoPlayback(false)

local lastSpacePress = 0
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Space then
		local timeSinceLastPress = os.clock() - lastSpacePress
		lastSpacePress = os.clock()
		
		if AutoPlayback then
			SolverMenu.ToggleAutoPlayback(false)
			lastSpacePress = 0
		elseif timeSinceLastPress <= 0.4 then
			SolverMenu.ToggleAutoPlayback(true)
		else
			SolverMenu.StepAlgorithm()
		end
	elseif input.KeyCode == Enum.KeyCode.Up then
		SolverMenu.StepAlgorithm()
	elseif input.KeyCode == Enum.KeyCode.Down then
		SolverMenu.StepAlgorithmBack()
	end
end)

SolverMenu.Restart()

--//
return SolverMenu