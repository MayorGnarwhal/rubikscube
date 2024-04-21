local CustomRange = {}
CustomRange.__index = CustomRange

function CustomRange:__tostring()
	return "CustomRange(" .. self.Min .. ", " .. (self.Max or self.Min) .. ")"
end

--// Constructor
function CustomRange.new(min: number, max: number?)
	assert(typeof(min) == "number", "Invalid minimum value given.")
	assert(max == nil or typeof(min) == "number", "Invalid maximum value given.")
	
	if max == nil or min == max then 
		return setmetatable({
			Value = min;
		}, CustomRange)
	else
		return setmetatable({
			Min = min;
			Max = max;
			Random = Random.new();
		}, CustomRange)
	end
end

--// Methods
function CustomRange:GetValue()
	if self.Value then
		return self.Value
	else
		return self.Random:NextNumber(self.Min, self.Max)
	end
end

function CustomRange:IsRange()
	return (self.Value == nil)
end

--//
return CustomRange