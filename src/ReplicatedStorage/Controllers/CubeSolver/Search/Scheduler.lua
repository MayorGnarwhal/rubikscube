local Scheduler = {}

--// Dependencies
local Services = game.ReplicatedStorage.Services
local ParallelScheduler = require(Services.ParallelScheduler)


--// Methods
function Scheduler.Create()
	return ParallelScheduler:LoadModule(script.Parent)
end
script.Create.OnInvoke = Scheduler.Create

--//
return Scheduler