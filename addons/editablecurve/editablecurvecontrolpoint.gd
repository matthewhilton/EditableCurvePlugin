class_name EditableCurveControlPoint extends StaticBody3D

# Shared context between all control points.
@export var context: EditableCurveContext

# What index am I representing/controlling on the curve.
var child_index := 0

signal moved_while_selected(n: EditableCurveControlPoint)

@export var controls: Array[ControlPointControl] = []

func _ready():
	set_notify_transform(true)

	context.selected_control_point_changed.connect(_update_control_visibility)
	_update_control_visibility()
	
	for control in controls:
		control.movement_translate.connect(_handle_translate)

func _input_event(camera, event, position, normal, shape_idx):
	if event.is_action_pressed("select_control_point"):
		_try_select()

func _is_selectable():
	return true

func _is_selected():
	return context.control_point_selected == self

func _try_select():
	if _is_selectable() && !_is_selected():
		context.control_point_selected = self
		return
	
	if _is_selected():
		context.control_point_selected = null
		return

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED && _is_selected():
		moved_while_selected.emit(self)

func _update_control_visibility():
	for control in controls:
		control.visible = _is_selected()

func _handle_translate(movement: Vector3):
	global_position += movement
