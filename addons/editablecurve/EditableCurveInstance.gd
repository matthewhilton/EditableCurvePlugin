class_name EditableCurveInstance extends Node3D

# The actual data about the curve, e.g. curve itself, any other metadata, etc...
@export var data: EditableCurveData
@export var control_point_scene: PackedScene

# Useful way for all the control points to keep in sync with each other.
var context := EditableCurveContext.new()

func _ready():
	_update_controlpoint_children()
	
func _update_controlpoint_children():
	for child in get_children():
		child.queue_free()
	
	for i in range(data.curve.point_count): 
		_add_controlpoint_at_index(i)

func _add_controlpoint_at_index(i: int):
	var child: EditableCurveControlPoint = control_point_scene.instantiate()
	child.context = context
	child.global_position
	child.moved_while_selected.connect(_update_curve_pos_from_controlpoint_movement)
	add_child(child)
	_force_realign()

func _update_curve_pos_from_controlpoint_movement(node: EditableCurveControlPoint):
	data.curve.set_point_position(node.get_curve_index(), node.global_position)

func add_point_at_end_of_curve(pos: Vector3):
	data.curve.add_point(pos)

	# Add new child (no need to rebuild all)
	_add_controlpoint_at_index(data.curve.point_count - 1)

func delete_selected_control():
	if !context.control_point_selected:
		return
	
	delete_point(context.control_point_selected.get_curve_index())
	
func delete_point(i):
	# Remove curve data.
	data.curve.remove_point(i)
	
	# Remove the controlpoint.
	var p = context.known_points[i]
	p.queue_free()
	context.known_points.remove_at(i)
	
	# Force all nodes to re-align, without emitting any movement signal.
	_force_realign()

func _force_realign():
	# Disable controls (and associated signals) during realignment.
	context.controls_active = false
	
	for i in range(data.curve.point_count):
		context.known_points[i].global_position = data.curve.get_point_position(i)
	
	context.controls_active = true
