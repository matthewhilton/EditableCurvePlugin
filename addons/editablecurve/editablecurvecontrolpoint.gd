class_name EditableCurveControlPoint extends StaticBody3D

# Shared context between all control points.
@export var context: EditableCurveContext

# All controls, for linking signals to.
@export var controls: Array[ControlPointControl] = []

signal mode_changed(to: MODE)

signal movement_start
signal movement_update(n: EditableCurveControlPoint, data: CurvePointData)
signal movement_end

# Flag used to detect if user clicks outside of control, in order to deselect control.
var possible_clickout := false

enum MODE { TRANSLATE, SIZE, ROTATION }
var mode := MODE.TRANSLATE:
	set(v):
		mode = v
		mode_changed.emit(v)

const mode_mappings = {
	MODE.TRANSLATE: [ControlPointControl.TYPE.LINEAR],
	MODE.ROTATION: [ControlPointControl.TYPE.RADIAL],
	MODE.SIZE: [ControlPointControl.TYPE.SCALE],
}

var point_data := CurvePointData.new()

func _ready():
	if self not in context.known_points:
		context.known_points.append(self)

	context.selected_control_point_changed.connect(_update_control_visibility)
	_update_control_visibility()
	
	for control in controls:
		control.movement_translate.connect(_handle_translate)
		control.movement_scale.connect(_handle_scale)
		control.movement_rotation.connect(_handle_rotation)
		control.received_mouse_input.connect(_control_received_mouse_input)
		control.drag_start.connect(func(): movement_start.emit())
		control.drag_end.connect(func(): movement_end.emit())
	
	mode_changed.connect(_on_mode_change)

func _on_mode_change(to: MODE):
	for control in controls:
		control.visible = control.type in mode_mappings.get(to, [])

func _input_event(camera, event, position, normal, shape_idx):
	if !context.controls_active:
		return
	
	if event.is_action_pressed("select_control_point"):
		_on_select()
	
	# Clicked/moused over self, disable click out flag.
	if event is InputEventMouseButton || event is InputEventMouseMotion:
		possible_clickout = false

func _input(event):
	# When this is pressed, we turn on a flag indicating the user could be clicking outside.
	if event.is_action_pressed("select_control_point"):
		possible_clickout = true

func _unhandled_input(event):
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

func _on_select():
	# Select self.
	if _is_selectable() && !_is_selected():
		context.control_point_selected = self
		_on_mode_change(mode)
		return

	# Already selected, change modes.
	elif _is_selected():
		mode = EditableCurveUtils.loop_next(MODE.values(), mode)

func _update_control_visibility():
	for control in controls:
		control.visible = _is_selected()

func _handle_scale(scale_delta: Vector3):
	var new_data = point_data.duplicate()
	new_data.axis_scale += scale_delta
	
	# Ensure it is always >= Vector3.ONE
	new_data.axis_scale.x = max(new_data.axis_scale.x, 1)
	new_data.axis_scale.y = max(new_data.axis_scale.y, 1)
	new_data.axis_scale.z = max(new_data.axis_scale.z, 1)
	
	movement_update.emit(self, new_data)
	
func _handle_rotation(axis: Vector3, angle_rad: float):
	var new_data = point_data.duplicate()
	new_data.global_transform.basis = new_data.global_transform.basis.rotated(axis.normalized(), angle_rad)
	movement_update.emit(self, new_data)

func _handle_translate(movement: Vector3):
	var new_data = point_data.duplicate()
	new_data.global_transform.origin += movement
	movement_update.emit(self, new_data)

func get_curve_index() -> int:
	return context.known_points.find(self)
