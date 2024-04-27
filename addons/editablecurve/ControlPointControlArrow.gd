class_name ControlPointControlArrow extends ControlPointControl

# TODO move this into its own script.
@export var MIN_SCALE := Vector3.ONE

# Arrows only move linearly in the direction of their global Y basis vector.
func _get_movement_dir() -> Vector3:
	return global_basis.y

func _get_face_normal() -> Vector3:
	return global_basis.x

func _handle_drag_event(event: InputEvent):
	if !(event is InputEventMouseMotion):
		return
	
	# TODO instead of using global_position, use the pos on the node first touched by the input event
	# Stops weird snapping when clicking outside of the center.
	
	var plane = Plane(drag_start_normal, global_position)
	
	var cam := get_viewport().get_camera_3d()
	var normal = cam.project_ray_normal(event.position)
	var ray = plane.intersects_ray(cam.global_position, normal)
	
	if !ray:
		return
	
	# Make a temporary curve in the movement dir and get the closest position.
	# (probably not super efficient, but its simple...)
	var curve = Curve3D.new()
	curve.add_point(global_position - _get_movement_dir() * 10)
	curve.add_point(global_position + _get_movement_dir() * 10)
	
	var offset = curve.get_closest_offset(ray)
	var pos = curve.sample_baked(offset)
	
	match type:
		TYPE.LINEAR:
			movement_translate.emit(pos - global_position)
		TYPE.SCALE:
			var new_scale: Vector3 = curve_scale + (Vector3.RIGHT * -1 * (pos - global_position))
			
			# Ensure its always at least the MIN_SCALE
			new_scale.x = max(new_scale.x, MIN_SCALE.x)
			new_scale.y = max(new_scale.y, MIN_SCALE.y)
			new_scale.z = max(new_scale.z, MIN_SCALE.z)
			
			movement_scale.emit(new_scale)
