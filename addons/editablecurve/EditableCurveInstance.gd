class_name EditableCurveInstance extends Node3D

# The actual data about the curve, e.g. curve itself, any other metadata, etc...
@export var data: EditableCurveData
@export var control_point_scene: PackedScene

# Useful way for all the control points to keep in sync with each other.
var context := EditableCurveContext.new()

var undo_redo := UndoRedo.new()

func _ready():
	_update_controlpoint_children()
	data.curve.changed.connect(_on_curve_changed)

func _input(event):
	if event.is_action_pressed("ui_undo") && _is_selected():
		undo_redo.undo()
	
	if event.is_action_pressed("ui_redo") && _is_selected():
		undo_redo.redo()

func _is_selected():
	return context.control_point_selected != null

func _update_controlpoint_children():
	for child in get_children():
		child.queue_free()
	
	for i in range(data.curve.point_count): 
		_add_controlpoint_at_index(i)

func _add_controlpoint_at_index(i: int):
	var child: EditableCurveControlPoint = control_point_scene.instantiate()
	child.context = context
	child.moved_while_selected.connect(_update_curve_pos_from_controlpoint_movement)
	child.movement_start.connect(_capture_undoredo_start)
	child.movement_end.connect(_capture_undoredo_end)
	add_child(child)
	child.global_position
	_force_realign()

func _capture_undoredo_start(n: EditableCurveControlPoint):
	undo_redo.create_action("Control point moved")
	undo_redo.add_undo_property(n, "global_transform", n.global_transform)

func _capture_undoredo_end(n: EditableCurveControlPoint):
	undo_redo.add_do_property(n, "global_transform", n.global_transform)
	undo_redo.commit_action(false)

func _on_curve_changed():
	pass

func _update_curve_pos_from_controlpoint_movement(node: EditableCurveControlPoint):
	var idx = node.get_curve_index()
	data.curve.set_point_position(idx, node.global_position)
	
	var is_start = idx == 0
	var is_end = idx == (data.curve.point_count - 1)
	
	if !is_end:
		data.curve.set_point_out(idx, -node.global_basis.z)
	
	if !is_start:
		data.curve.set_point_in(idx, node.global_basis.z)

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
		var dir = data.curve.get_point_out(i) if i != (data.curve.point_count - 1) else -data.curve.get_point_in(i)
		
		if dir != Vector3.ZERO:
			context.known_points[i].look_at(context.known_points[i].position + dir)
	
	context.controls_active = true
