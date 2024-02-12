local getProperty = require(script.getProperty)

function followPath(item: any, path: table)
	local property = path[1]
	local isInstance = (typeof(item) == "Instance")
	
	if property == nil or property == "" then
		return item
	elseif isInstance and item:FindFirstChild(property) then
		item = item:FindFirstChild(property)
	elseif isInstance and item:GetAttribute(property) then
		item = item:GetAttribute(property)
	else
		item = getProperty(item, property)
	end
	
	table.remove(path, 1)
	return item and followPath(item, path)
end

return function(item: any, path: string?)
	path = string.split(path or ".", ".")
	if path[1] == "" then
		table.remove(path, 1)
	end
	
	return followPath(item, path)
end