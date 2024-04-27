class_name ControlPointControl extends StaticBody3D

var is_being_dragged := false
var drag_start_pos := Vector3.ZERO
var drag_start_mouse_pos := Vector2.ZERO
var drag_start_normal := Vector3.ZERO
var drag_started_from_back := false

signal drag_start
signal drag_end
signal received_mouse_input

signal movement_scale(amount: Vector3)
signal movement_translate(amount: Vector3)
signal movement_rotation(axis: Vector3, amount_rad: float)

enum TYPE { LINEAR, RADIAL, SCALE }
var type: TYPE

# Overwrite in subclass
func _get_face_normal() -> Vector3:
	return Vector3.FORWARD

func _input(event):
	# This is not on the _input_event, since the mouse may move outside of the object while dragging.
	if event.is_action_released("select_control_point") && is_being_dragged:
		is_being_dragged = false
		drag_start_pos = Vector3.ZERO
		drag_start_mouse_pos = Vector2.ZERO
		drag_start_normal = Vector3.ZERO
		drag_end.emit()
	
	if is_being_dragged:
		_handle_drag_event(event)

func _input_event(camera, event, position, normal, shape_idx):
	if event.is_action_pressed("select_control_point"):
		is_being_dragged = true
		drag_start_pos = global_position
		drag_start_mouse_pos = event.position
		drag_start_normal = camera.project_ray_normal(event.position)
		
		# Check if was from back or front.
		var plane = Plane(_get_face_normal(), global_position)
		drag_started_from_back = !plane.is_point_over(position)
		
		drag_start.emit()
	
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		received_mouse_input.emit()

# Overwrite in subclass
# E.g. arrow could be linear, but rotation could be to rotate the object.
func _handle_drag_event(event):
	pass
