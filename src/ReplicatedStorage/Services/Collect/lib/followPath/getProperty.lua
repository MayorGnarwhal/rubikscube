-- lol
return function(object, property)
	local success, result = pcall(function()
		return object[property]
	end)
	return success and result
end