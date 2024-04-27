class_name CurveStructureGenerator extends Resource

# Takes in the curve data, and generates.
# Overwrite in subclasses to provide various functionality.
func generate(data: EditableCurveData, state: PhysicsDirectSpaceState3D) -> Node3D:
	return Node3D.new()
