local InterfaceUtil = {}

--// Dependencies
local TweenService = game:GetService("TweenService")

local Services = game.ReplicatedStorage.Services
local Audio = require(Services.Audio)


--// Methods
function InterfaceUtil.HoverUnderline(toggle)
	local height = toggle.Underline.Size.Y.Offset
	toggle.Underline.Size = UDim2.fromOffset(0, height)

	toggle.MouseEnter:Connect(function()
		Audio.Play(Audio.Sounds.HoverEnter)
		
		local width = toggle.Title:IsA("TextLabel") and toggle.Title.TextBounds.X or toggle.Title.AbsoluteSize.X - 8
		
		TweenService:Create(
			toggle.Underline, 
			TweenInfo.new(0.2, Enum.EasingStyle.Sine), 
			{Size = UDim2.fromOffset(width, height)}
		):Play()
		TweenService:Create(
			toggle.Title, 
			TweenInfo.new(0.1, Enum.EasingStyle.Sine), 
			{Position = UDim2.fromScale(0, 0.45)}
		):Play()
	end)

	toggle.MouseLeave:Connect(function()
		TweenService:Create(
			toggle.Underline, 
			TweenInfo.new(0.2, Enum.EasingStyle.Sine), 
			{Size = UDim2.fromOffset(0, height)}
		):Play()
		TweenService:Create(
			toggle.Title, 
			TweenInfo.new(0.1, Enum.EasingStyle.Sine), 
			{Position = UDim2.fromScale(0, 0.5)}
		):Play()
	end)

	toggle.MouseButton1Click:Connect(function()
		Audio.Play(Audio.Sounds.GuiClick)
	end)
end

--//
return InterfaceUtil