local Queue = {}
Queue.__index = Queue

--// Dependencies
local HttpService = game:GetService("HttpService")

--// Variables
local Cache = {}


--// Constructors
function Queue.new(queueKey: any?)
	if queueKey then
		assert(Cache[queueKey] == nil, "Queue with key already exists: " .. queueKey)
	else
		queueKey = HttpService:GenerateGUID(false)
	end
	
	local self = setmetatable({
		_key = queueKey,
		_list = {},
	}, Queue)
	
	Cache[queueKey] = self._list
	
	return self
end

function Queue.get(queueKey)
	local list = Cache[queueKey]
	assert(list, "Invalid queue key: " .. queueKey)
	
	local self = setmetatable({
		_key = queueKey,
		_list = list,
	}, Queue)
	
	return self
end


--// Metamethods
function Queue:__len()
	return #self._list
end


--// Methods
function Queue:GetKey()
	return self._key
end

function Queue:Append(node: any)
	table.insert(self._list, node)
end

function Queue:Pop()
	assert(not self:IsEmpty(), "Cannot pop from empty queue")
	
	local node = self._list[1]
	table.remove(self._list, 1)
	
	return node
end

function Queue:PopMany(n: number)
	local elements = {}
	while #elements < n and not self:IsEmpty() do
		table.insert(elements, self:Pop())
	end

	return elements
end

function Queue:IsEmpty()
	return #self._list == 0
end

function Queue:Clear()
	table.clear(self._list)
end

function Queue:Destroy()
	self:Clear()
	Cache[self._key] = nil
end


--// Bindable Event
script:WaitForChild("Append").Event:Connect(function(queueKey, node)
	local queue = Queue.get(queueKey)
	queue:Append(node)
end)

--//
return Queue