class_name CurveData extends Resource

# Curve only stores the path, but here we can store additional data.
# E.g. width (as a curve, or static), etc...
@export var curve: EditableCurveData
@export var width := 2.0

# Overwrite in subclasses for more interesting functionality, e.g. variable width using a curve profile.
func get_width_at_offset(offset: float):
	return width
