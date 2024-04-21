local Timer = {}

--// Dependencies
local RunService = game:GetService("RunService")

local Services = game.ReplicatedStorage.Services
local Util = require(Services.Util)

local LocalPlayer = game.Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Display = PlayerGui:WaitForChild("MainGui"):WaitForChild("TopBar"):WaitForChild("Timer")

--// Variables
local IsRunning = false
local Blinking = false
local StartTimestamp
local Connect


--// Methods
function Timer.Start()
	if IsRunning then
		Timer.Stop()
	end
	Timer.StopBlinking()
	IsRunning = true
	
	StartTimestamp = os.clock()
	Connect = RunService.Heartbeat:Connect(function()
		Timer.SetTime()
	end)
end

function Timer.Stop()
	if not IsRunning then return end
	IsRunning = false
	
	Connect:Disconnect()
	
	Timer.SetTime()
	StartTimestamp = nil
end

function Timer.Blink()
	if Blinking then return end
	Blinking = true
	
	while Blinking do
		Display.Title.Visible = not Display.Title.Visible
		task.wait(0.5)
	end
	
end

function Timer.StopBlinking()
	Blinking = false
	Display.Title.Visible = true
end

function Timer.SetTime(seconds: number?)
	Display.Title.Text = Util.ClockTime(seconds or Timer.GetTime())
end

function Timer.GetTime()
	if StartTimestamp then
		return os.clock() - StartTimestamp
	else
		return 0
	end
end

function Timer.IsRunning()
	return IsRunning
end

--//
return Timer