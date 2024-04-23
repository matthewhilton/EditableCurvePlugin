class_name EditableCurveInstance extends Node3D

# The actual data about the curve, e.g. curve itself, any other metadata, etc...
@export var curve: EditableCurve
@export var control_point_scene: PackedScene

# Useful way for all the control points to keep in sync with each other.
var context := EditableCurveContext.new()
var undo_redo := UndoRedo.new()

signal curve_updated

func _ready():
	_update_controlpoint_children()
	curve.changed.connect(_on_curve_changed)
	
	undo_redo.version_changed.connect(func(): print("undoredo version changed"))

func _input(event):
	if event.is_action_pressed("ui_undo") && _is_selected():
		undo_redo.undo()
	
	if event.is_action_pressed("ui_redo") && _is_selected():
		undo_redo.redo()
	
	if event.is_action_pressed("ui_delete") && _is_selected():
		delete_selected_control()

func _is_selected():
	return true # If you had multiple you would check here which is active.

func _update_controlpoint_children():
	for child in get_children():
		child.queue_free()
	
	_realign_controlpoints()

func _add_controlpoint():
	var child: EditableCurveControlPoint = control_point_scene.instantiate()
	child.context = context
	child.moved_while_selected.connect(_update_curve_pos_from_controlpoint_movement)
	child.movement_start.connect(_capture_undoredo_start)
	child.movement_end.connect(_capture_undoredo_end)
	child.movement_end.connect(func(n): curve_updated.emit())
	add_child(child)

func _capture_undoredo_start(n: EditableCurveControlPoint):
	# Keep a copy of the curve, not the control point transform property
	# Because control points are ephemeral and can be created/destroyed easily.
	# We actually want to keep track of the curve changes, and regenerate the control points based off that.
	undo_redo.create_action("Control point moved")
	undo_redo.add_undo_property(self, "curve", curve.duplicate())
	undo_redo.add_undo_method(_realign_controlpoints)

func _capture_undoredo_end(n: EditableCurveControlPoint):
	undo_redo.add_do_property(self, "curve", curve.duplicate())
	undo_redo.add_do_method(_realign_controlpoints)
	undo_redo.commit_action(false)
	print("committed control point move action")

func _on_curve_changed():
	pass

func _update_curve_pos_from_controlpoint_movement(node: EditableCurveControlPoint):
	var idx = node.get_curve_index()
	curve.set_point_position(idx, node.global_position)
	
	var is_start = idx == 0
	var is_end = idx == (curve.point_count - 1)
	
	if !is_end:
		var out_scale = node.global_position.distance_to(curve.get_point_position(idx + 1)) / 4.0
		curve.set_point_out(idx, -node.global_basis.z * out_scale)
	
	if !is_start:
		var in_scale = node.global_position.distance_to(curve.get_point_position(idx - 1)) / 4.0
		curve.set_point_in(idx, node.global_basis.z * in_scale)
	
	if !is_start && !is_end:
		var angle_tilt = Vector3.UP.signed_angle_to(node.global_basis.y, -node.global_basis.z)
		print(angle_tilt)
		curve.set_point_tilt(idx, angle_tilt)
	
	if is_start || is_end:
		curve.set_point_tilt(idx, 0)

func add_point_at_end_of_curve(pos: Vector3):
	# TODO when adding to end, automatically
	# make the point look in an appropriate direction
	_add_point_undoredo(pos)
	_realign_controlpoints()
	_set_last_point_basis()

func _set_last_point_basis():
	if curve.point_count <= 1:
		return
	
	var lastnode = context.known_points[curve.point_count - 1]
	var secondlastpoint = curve.get_point_position(curve.point_count - 2)
	
	lastnode.look_at(secondlastpoint, Vector3.UP, true)
	
func _add_point_undoredo(pos: Vector3, index = -1):
	undo_redo.create_action("Add curve point")
	undo_redo.add_undo_property(self, "curve", curve.duplicate())
	undo_redo.add_undo_method(_realign_controlpoints)
	
	curve.add_point(pos, Vector3.ZERO, Vector3.ZERO, index)
	
	undo_redo.add_do_property(self, "curve", curve.duplicate())
	undo_redo.add_do_method(_realign_controlpoints)
	undo_redo.commit_action(false)
	print("commited add curve point action")

func delete_selected_control():
	if !context.control_point_selected:
		return
	
	delete_point(context.control_point_selected.get_curve_index())
	
func delete_point(i):
	# TODO undo/redo support.
	undo_redo.create_action("Delete curve point")
	undo_redo.add_undo_property(self, "curve", curve.duplicate())
	undo_redo.add_undo_method(_realign_controlpoints)

	# Remove curve data.
	curve.remove_point(i)
	
	undo_redo.add_do_property(self, "curve", curve.duplicate())
	undo_redo.add_do_method(_realign_controlpoints)
	undo_redo.commit_action(false)
	print("commited delete curve point action")
	
	# Remove the controlpoint.
	var p = context.known_points[i]
	p.queue_free()
	context.known_points.remove_at(i)
	
func _realign_controlpoints():
	# Adjust the count based on the curve count.
	var diff = curve.point_count - context.known_points.size()

	# Remove
	if diff < 0:
		for i in range(abs(diff)):
			var n = context.known_points.pop_back()
			n.queue_free()
	
	# Add.
	if diff > 0:
		for i in range(diff):
			_add_controlpoint()
	
	# Force all nodes to re-align, without emitting any movement signal.
	_force_realign()
	curve_updated.emit()

func _force_realign():
	# Disable controls (and associated signals) during realignment.
	context.controls_active = false
	
	for i in range(curve.point_count):
		context.known_points[i].global_position = curve.get_point_position(i)
		var dir = curve.get_point_out(i).normalized() if i != (curve.point_count - 1) else -curve.get_point_in(i).normalized()
		
		# TODO realign rotation and tilt
	
	context.controls_active = true
