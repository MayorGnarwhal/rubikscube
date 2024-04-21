local MainMenu = {}

--// Dependencies
local TweenService = game:GetService("TweenService")

local Services = game.ReplicatedStorage.Services
local Audio = require(Services.Audio)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Menu = PlayerGui:WaitForChild("Menus"):WaitForChild("MainMenu")

local Header = Menu:WaitForChild("Header")
local Toggles = Header:WaitForChild("Toggles")
local Content = Menu:WaitForChild("Content")
local MinimizeButton = Menu:WaitForChild("Minimize"):WaitForChild("Input")

--// Variables
local IsMaximized = true


--// Methods
function MainMenu.Maximize(instant: boolean?)
	if IsMaximized then return end
	IsMaximized = true
	
	MinimizeButton.Title.Text = ">"
	
	TweenService:Create(
		Menu,
		TweenInfo.new(instant and 0 or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(0, 0)}
	):Play()
end

function MainMenu.Minimize(instant: boolean?)
	if not IsMaximized then return end
	IsMaximized = false
	
	MinimizeButton.Title.Text = "<"
	
	TweenService:Create(
		Menu,
		TweenInfo.new(instant and 0 or 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{Position = UDim2.fromOffset(-Menu.AbsoluteSize.X - 10, 0)}
	):Play()
end


--// Setup
for i, toggle in ipairs(Toggles:GetChildren()) do
	if not toggle:IsA("TextButton") then continue end
	
	toggle.Underline.Size = UDim2.fromOffset(0, 2)
	
	local underlineTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine)
	
	toggle.MouseEnter:Connect(function()
		Audio.Play(Audio.Sounds.HoverEnter)
		TweenService:Create(toggle.Underline, underlineTweenInfo, {Size = UDim2.fromOffset(toggle.Title.TextBounds.X, 2)}):Play()
	end)
	
	toggle.MouseLeave:Connect(function()
		TweenService:Create(toggle.Underline, underlineTweenInfo, {Size = UDim2.fromOffset(0, 2)}):Play()
	end)
	
	toggle.MouseButton1Click:Connect(function()
		Audio.Play(Audio.Sounds.GuiClick)
	end)
end

MinimizeButton.MouseButton1Click:Connect(function()
	Audio.Play(Audio.Sounds.GuiClick)
	if IsMaximized then
		MainMenu.Minimize()
	else
		MainMenu.Maximize()
	end
end)

MinimizeButton.MouseEnter:Connect(function()
	Audio.Play(Audio.Sounds.HoverEnter)
	TweenService:Create(MinimizeButton, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(-0.3, 0)}):Play()
end)

MinimizeButton.MouseLeave:Connect(function()
	TweenService:Create(MinimizeButton, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Position = UDim2.fromScale(-0.4, 0)}):Play()
end)

MainMenu.Minimize(true)

--//
return MainMenu