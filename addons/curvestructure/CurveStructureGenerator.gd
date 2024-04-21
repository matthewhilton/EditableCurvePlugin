class_name CurveStructureGenerator extends Resource

# Takes in the curve data, and generates.
# Overwrite in subclasses to provide various functionality.
func generate(data: CurveData) -> Node3D:
	return Node3D.new()
