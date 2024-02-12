local FaceMaps = {}

FaceMaps.AxisMap = {
	[Enum.NormalId.Top] = Enum.Axis.Y,
	[Enum.NormalId.Bottom] = Enum.Axis.Y,
	[Enum.NormalId.Left] = Enum.Axis.X,
	[Enum.NormalId.Right] = Enum.Axis.X,
	[Enum.NormalId.Front] = Enum.Axis.Z,
	[Enum.NormalId.Back] = Enum.Axis.Z,
}

FaceMaps.RotationMap = {
	[Enum.Axis.X] = {
		[Enum.Axis.X] = "Row",
		[Enum.Axis.Y] = "Col",
		[Enum.Axis.Z] = "Col",
	},
	[Enum.Axis.Y] = {
		[Enum.Axis.X] = "Row",
		[Enum.Axis.Y] = "Col",
		[Enum.Axis.Z] = "Row",
	},
	[Enum.Axis.Z] = {
		[Enum.Axis.X] = "Col",
		[Enum.Axis.Y] = "Row",
		[Enum.Axis.Z] = "Col",
	},
}

FaceMaps.FlipedFaces = {
	Col = {
		[Enum.NormalId.Right] = true,
		[Enum.NormalId.Front] = true,
	},
	Row = {
		[Enum.NormalId.Bottom] = true,
		
		[Enum.NormalId.Left] = true,
		[Enum.NormalId.Right] = true,
		[Enum.NormalId.Front] = true,
		[Enum.NormalId.Back] = true,
	},
}

FaceMaps.Reverse = {
	[Enum.NormalId.Top] = {
		[Enum.NormalId.Left] = true,
		[Enum.NormalId.Front] = true,
	},
	[Enum.NormalId.Bottom] = {
		[Enum.NormalId.Front] = true,
		[Enum.NormalId.Right] = true,
	},
	[Enum.NormalId.Left] = {
		[Enum.NormalId.Top] = true,
	},
	[Enum.NormalId.Right] = {
		[Enum.NormalId.Bottom] = true,
	},
	[Enum.NormalId.Front] = {
		[Enum.NormalId.Top] = true,
		[Enum.NormalId.Bottom] = true,
	},
	[Enum.NormalId.Back] = {
		
	},
}

return FaceMaps