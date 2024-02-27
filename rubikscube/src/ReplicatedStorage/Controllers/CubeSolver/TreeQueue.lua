local TreeQueue = {}

--// Variables
local Queue = {}


--// Methods
function TreeQueue.Append(cubeMap, depth, pathCost, path)
	local node = {
		Cube = cubeMap,
		Depth = depth,
		Cost = pathCost,
		Path = path,
	}
	
	table.insert(Queue, node)
	--print("add", #Queue, node)
	
	return node
end

function TreeQueue.Pop()
	assert(not TreeQueue.IsEmpty(), "Cannot pop from empty queue.")
	
	local node = Queue[1]
	table.remove(Queue, 1)
	
	return node
end

function TreeQueue.PopMany(n)
	local elements = {}
	while #elements < n and not TreeQueue.IsEmpty() do
		table.insert(elements, TreeQueue.Pop())
	end
	
	return elements
end

function TreeQueue.IsEmpty()
	return #Queue == 0
end

function TreeQueue.Clear()
	table.clear(Queue)
end

function TreeQueue.Size()
	return #Queue
end


script.Event.Event:Connect(function(...)
	TreeQueue.Append(...)
end)

--//
return TreeQueue