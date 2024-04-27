class_name Curve3DWithHooks extends Resource

# We cannot override internal engine methods i.e. any Curve3D methods
# to hook into various things e.g. point adding, removal
# https://github.com/godotengine/godot/issues/55024
# So we must duplicate these methods here, with the hooks added.
@export var _internal_curve := Curve3D.new()

# This is simply a wrapper for Curve3D that adds signals for relevant functions
# So other code can hook in, mostly where points are added/removed.
signal add_point_called(position: Vector3, in_vec: Vector3, out_vec: Vector3, index: int)
signal remove_point_called(idx: int)

var point_count:
	get:
		return _internal_curve.point_count

func _init():
	_internal_curve.changed.connect(func(): changed.emit())

func add_point(position: Vector3, in_vec := Vector3.ZERO, out_vec := Vector3.ZERO, index := -1):
	_internal_curve.add_point(position, in_vec, out_vec, index)
	add_point_called.emit(position, in_vec, out_vec, index)

func remove_point(idx: int):
	_internal_curve.remove_point(idx)
	remove_point_called.emit(idx)

func sample_baked(offset: float) -> Vector3:
	return _internal_curve.sample_baked(offset)

func sample_baked_with_rotation(offset: float = 0.0, cubic := false, apply_tilt := false) -> Transform3D:
	return _internal_curve.sample_baked_with_rotation(offset, cubic, apply_tilt)

func set_point_in(idx: int, position: Vector3):
	_internal_curve.set_point_in(idx, position)

func set_point_out(idx: int, position: Vector3):
	_internal_curve.set_point_out(idx, position)

func set_point_position(idx: int, position: Vector3):
	_internal_curve.set_point_position(idx, position)

func set_point_tilt(idx: int, tilt: float):
	_internal_curve.set_point_tilt(idx, tilt)

# For anything core that needs an actual curve, e.g. Path3D.
func get_internal_curve() -> Curve3D:
	return _internal_curve

func get_point_position(idx: int) -> Vector3:
	return _internal_curve.get_point_position(idx)

func get_point_in(idx: int) -> Vector3:
	return _internal_curve.get_point_in(idx)

func get_point_out(idx: int) -> Vector3:
	return _internal_curve.get_point_out(idx)

func get_point_tilt(idx: int) -> float:
	return _internal_curve.get_point_tilt(idx)

func get_baked_length() -> float:
	return _internal_curve.get_baked_length()
