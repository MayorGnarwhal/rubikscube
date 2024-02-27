export type Palette = {
	Core: Color3,
	Top: Color3,
	Bottom: Color3,
	Front: Color3,
	Back: Color3,
	Left: Color3,
	Right: Color3,
}

local Palettes = {}

Palettes.Standard = {
	Core = BrickColor.new("Really black").Color,
	Top = BrickColor.new("Institutional white").Color,
	Bottom = BrickColor.new("Bright yellow").Color,
	Front = BrickColor.new("Bright green").Color,
	Back = BrickColor.new("Bright blue").Color,
	Left = BrickColor.new("Bright red").Color,
	Right = BrickColor.new("Bright orange").Color,
}

-- Rubik's brand palette
Palettes.Rubiks = {
	Core = BrickColor.new("Really black").Color;
	Top = Color3.fromHex("ffffff"),
	Bottom = Color3.fromHex("FFD500"),
	Front = Color3.fromHex("009B48"),
	Back = Color3.fromHex("0046AD"),
	Left = Color3.fromHex("FF5800"),
	Right = Color3.fromHex("B71234"),
}

return Palettes