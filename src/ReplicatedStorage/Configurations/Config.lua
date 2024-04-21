return {
	CubeDimensions = 3,
	
	DefaultRotateSpeed = 0.2,
	ScrambleRotateSpeed = 0.1,
	
	DragThreshold = 1.5,
	
	FaceThickness = 0.2, --0.6,
	FaceBorderSize = 0.2,
	
	ScrambleLength = 25,
	ScrambleMoves = {
		"R", "Ri", "R2", "L", "Li", "L2", "U", "Ui", "U2", 
		"D", "Di", "D2", "F", "Fi", "F2", "B", "Bi", "B2",
	},
	
	SolveMoves = {
		"R", "Ri", "L", "Li", "U", "Ui",
		"D", "Di", "F", "Fi", "B", "Bi",
		"R2", "L2", "U2", "D2", "F2", "B2",
		--"M", "Mi", "M2", "E", "Ei", "E2", "S", "Si", "S2",
	},
	
	UnpaintedColor = Color3.fromRGB(17, 17, 17)
}