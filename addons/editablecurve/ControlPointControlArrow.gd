class_name ControlPointControlArrow extends ControlPointControl

@onready var movement_axis := global_basis.y.normalized()

# Arrows only move linearly in the direction of their global Y basis vector.
func _get_movement_dir() -> Vector3:
	return global_basis.y

func _handle_drag_event(event: InputEvent):
	if !(event is InputEventMouseMotion):
		return
	
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
	
	movement_translate.emit(pos - global_position)
