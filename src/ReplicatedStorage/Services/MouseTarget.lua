local MouseTarget = {}

--// Dependencies
local LocalPlayer = game.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// Variables
local DefaultCastDistance = 100


--// Methods
function MouseTarget.GetPosition(distance): Vector3
	distance = distance or DefaultCastDistance
	
	local unit = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
	return unit.Origin + (unit.Direction * distance)
end

function MouseTarget.GetDirection(): Vector3
	local unit = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
	return unit.Direction
end

function MouseTarget.GetFromWhitelist(filterObjects, distance): RaycastResult
	distance = distance or DefaultCastDistance
	
	local rParams = RaycastParams.new()
	rParams.FilterDescendantsInstances = filterObjects
	rParams.FilterType = Enum.RaycastFilterType.Include
	
	local unit = workspace.CurrentCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
	local result = workspace:Raycast(unit.Origin, unit.Direction * distance, rParams)
	
	return result
end

--//
return MouseTarget