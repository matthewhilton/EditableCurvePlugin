class_name ControlPointControlRotation extends ControlPointControl

var previous_angle := 0.0

# TODO on drag end, re-align self with the world axis

func _ready():
	drag_start.connect(_reset)
	drag_end.connect(_reset)

func _reset():
	previous_angle = 0.0
	
func _get_movement_dir() -> Vector3:
	return global_basis.z

func _get_face_normal() -> Vector3:
	return global_basis.z
	
func _handle_drag_event(event: InputEvent):
	if !(event is InputEventMouseMotion):
		return

	var center_pos_screen = get_viewport().get_camera_3d().unproject_position(global_position)
	var dir = center_pos_screen.direction_to(event.position)
	var angle = Vector2.UP.angle_to(dir)
	
	# Invert if dragging from back.
	if drag_started_from_back:
		angle *= -1
	
	if previous_angle == 0.0:
		previous_angle = angle
		return
	
	var diff = previous_angle - angle
	previous_angle = angle
	
	movement_rotation.emit(_get_movement_dir(), diff)
