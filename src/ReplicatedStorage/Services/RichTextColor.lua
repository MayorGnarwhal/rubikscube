local RichTextColor = {}

--// Dependencies
local Configurations = game.ReplicatedStorage.Configurations
local FaceColorMap = require(Configurations.FaceColorMap)
local Palletes = require(Configurations.Palettes)


--// Helper functions
local function StringifyColor(color: Color3)
	local r = math.round(color.R * 255)
	local g = math.round(color.G * 255)
	local b = math.round(color.B * 255)

	return ("rgb(%s,%s,%s)"):format(r, g, b)
end


--// Match Colors
local MatchColors = {}
for faceName, color in pairs(Palletes.Standard) do
	local colorName = FaceColorMap[faceName]
	if colorName then
		if colorName == "White" then
			color = Color3.fromRGB(170, 170, 170)
		else
			color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
		end
		
		local str = ("<font color='%s'>%s</font>"):format(StringifyColor(color), string.lower(colorName))
		MatchColors[colorName] = str
	end
end


--// Methods
function RichTextColor.Apply(str)
	local newStr = str
	for faceName, replaceStr in pairs(MatchColors) do
		newStr = newStr:gsub(faceName, replaceStr)
	end
	
	return newStr
end

--//
return RichTextColor