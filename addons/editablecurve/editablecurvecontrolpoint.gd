class_name EditableCurveControlPoint extends StaticBody3D

# Shared context between all control points.
@export var context: EditableCurveContext

# All controls, for linking signals to.
@export var controls: Array[ControlPointControl] = []

signal moved_while_selected(n: EditableCurveControlPoint)

var possible_clickout := false

func _ready():
	if self not in context.known_points:
		context.known_points.append(self)
	
	set_notify_transform(true)

	context.selected_control_point_changed.connect(_update_control_visibility)
	_update_control_visibility()
	
	for control in controls:
		control.movement_translate.connect(_handle_translate)
		control.movement_rotation.connect(_handle_rotation)
		control.received_mouse_input.connect(_control_received_mouse_input)
	
func _input_event(camera, event, position, normal, shape_idx):
	if !context.controls_active:
		return
	
	if event.is_action_pressed("select_control_point"):
		_try_select()

func _input(event):
	# When this is pressed, we turn on a flag indicating the user could be clicking outside.
	if event.is_action_pressed("select_control_point"):
		possible_clickout = true
	
	# If the action is released, and this flag is still true, click out is confirmed
	# and control point deselects self.
	if event.is_action_released("select_control_point") && possible_clickout && _is_selected():
		context.control_point_selected = null

# When one of the controls receives a mouse input, we disable the click out flag
# Since user is clearly still interacting with the control.
func _control_received_mouse_input():
	possible_clickout = false

func _is_selectable():
	return true

func _is_selected():
	return context.control_point_selected == self

func _try_select():
	if _is_selectable() && !_is_selected():
		context.control_point_selected = self
		return

func _notification(what):
	if !context || !context.controls_active:
		return
	
	if what == NOTIFICATION_TRANSFORM_CHANGED && _is_selected():
		moved_while_selected.emit(self)

func _update_control_visibility():
	for control in controls:
		control.visible = _is_selected()

func _handle_rotation(axis: Vector3, angle_rad: float):
	global_basis = global_basis.rotated(axis.normalized(), angle_rad)

func _handle_translate(movement: Vector3):
	global_position += movement

func get_curve_index() -> int:
	return context.known_points.find(self)
