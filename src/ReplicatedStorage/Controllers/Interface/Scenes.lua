local Scenes = {}

--// Dependencies
local StarterGui = game:GetService("StarterGui")

local Services = game.ReplicatedStorage.Services
local Collect = require(Services.Collect)
local Tween = require(Services.Tween)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("MainGui")
local Menus = PlayerGui:WaitForChild("Menus")

--// Variables
local ShowInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local HideInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)

local UIElements = {
	[Menus:WaitForChild("ColorPicker")] = "Bottom",
	[Menus:WaitForChild("Solver")] = "Right",
}

local PositionCache = Collect(UIElements):map(function(func, element)
	return element.Position
end):get()

local HiddenElements = {}
local BillboardEnabled = true


--// Helper functions
local HideFunctions = {}
function HideFunctions.Right(item)
	local pos = PositionCache[item]
	local size = item.Size
	local anchor = item.AnchorPoint
	
	Tween:Create(item, HideInfo, {Position = UDim2.new(
		size.X.Scale + anchor.X,
		size.X.Offset + 10,
		pos.Y.Scale,
		pos.Y.Offset
	)}):Play()
end

function HideFunctions.Left(item)
	local pos = PositionCache[item]
	local size = item.Size
	local anchor = item.AnchorPoint
	
	Tween:Create(item, HideInfo, {Position = UDim2.new(
		-size.X.Scale - anchor.X,
		-size.X.Offset - 10,
		pos.Y.Scale,
		pos.Y.Offset
	)}):Play()
end

function HideFunctions.Top(item)
	local pos = PositionCache[item]
	local size = item.Size
	local anchor = item.AnchorPoint
	
	Tween:Create(item, HideInfo, {Position = UDim2.new(
		pos.X.Scale,
		pos.X.Offset,
		-size.Y.Scale - anchor.Y,
		-size.Y.Offset - 10
	)}):Play()
end

function HideFunctions.Bottom(item)
	local pos = PositionCache[item]
	local size = item.Size
	local anchor = item.AnchorPoint

	Tween:Create(item, HideInfo, {Position = UDim2.new(
		pos.X.Scale,
		pos.X.Offset,
		size.Y.Scale + anchor.Y,
		size.Y.Offset + 10
	)}):Play()
end

local function Show(item)
	if not HiddenElements[item] then return end
	HiddenElements[item] = nil
	
	item.Visible = true
	
	Tween:Create(item, ShowInfo, {Position = PositionCache[item]}):Play()
end

local function Hide(item)
	if HiddenElements[item] then return end
	
	local hideDirection = UIElements[item]
	if not hideDirection then
		warn("No hide direction set for element:", item)
		return
	end
	
	local hideFunc = HideFunctions[hideDirection]
	if not hideFunc then
		warn("Invalid hide direction (" .. hideDirection .. ") set for element:", item)
		return
	end
	
	HiddenElements[item] = true
	hideFunc(item)
end


--// Methods
function Scenes.Default()
	Show(Menus.Solver)
	Hide(Menus.ColorPicker)
end

function Scenes.ColorPicker()
	Hide(Menus.Solver)
	Show(Menus.ColorPicker)
end

Scenes.Default()

--//
return Scenes