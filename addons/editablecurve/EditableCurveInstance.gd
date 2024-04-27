class_name EditableCurveInstance extends Node3D

# The actual data about the curve, e.g. curve itself, any other metadata, etc...
@export var data: EditableCurveData:
	set(v):
		data = v
		curve_updated.emit()
		
@export var control_point_scene: PackedScene

# Useful way for all the control points to keep in sync with each other.
var context := EditableCurveContext.new()
var undo_redo := UndoRedo.new()

signal curve_updated

func is_control_selected():
	return context.control_point_selected != null

func _ready():
	_match_controlpoints_to_curve_point_count()
	curve_updated.connect(_on_curve_updated)

func _input(event):
	if event.is_action_pressed("ui_undo") && _is_selected():
		undo_redo.undo()
	
	if event.is_action_pressed("ui_redo") && _is_selected():
		undo_redo.redo()

func _capture_undoredo_start():
	undo_redo.create_action("Edit curve data")
	undo_redo.add_undo_property(self, "data", data.duplicate())
	undo_redo.add_undo_method(_on_undoredo_executed)

func _capture_undoredo_end():
	undo_redo.add_do_property(self, "data", data.duplicate())
	undo_redo.add_do_method(_on_undoredo_executed)
	undo_redo.commit_action(false)

# After undo/redo, the curve is reset back to previous state
# So emit curve_updated to let all listeners know it changed.
# This will also re-align the control points.
func _on_undoredo_executed():
	curve_updated.emit()

func _is_selected():
	return true # If you had multiple you would check here which is active.

func remove_selected_control():
	if !context.control_point_selected:
		return
	
	var idx = context.known_points.find(context.control_point_selected)
	
	if idx == -1:
		return
	
	data.remove_point(idx)
	curve_updated.emit()

func add_point_in_middle(t: Transform3D, autoalign := false):
	# TODO implement autoalign in middle.
	_capture_undoredo_start()
	
	# Add this point at the given index, then update it as normal.
	var idx = EditableCurveUtils.get_index_to_insert_pos_after(data.get_internal_curve(), t.origin)

	if idx == -1:
		return
	
	# Replace transform entirely with a logical point in the center of the existing two.
	if autoalign:
		t = get_transform_between(idx - 1, idx)

	data.add_point(t.origin, Vector3.ZERO, Vector3.ZERO, idx)
	_update_curve_based_on_transform(idx, t)

	_capture_undoredo_end()
	
func add_to_end(t: Transform3D, autoalign := false):
	if autoalign:
		t = align_basis_to_end_of_curve(t)

	_capture_undoredo_start()
	_update_curve_based_on_transform(-1, t)
	_capture_undoredo_end()

# Ensure we have a control point for each curve point.
# Delete any extras, or add any missing.
func _match_controlpoints_to_curve_point_count():
	if !data:
		# No curve - clear all.
		while !context.known_points.is_empty():
			var n = context.known_points.pop_back()
			n.queue_free()
		return

	# Adjust the count based on the curve count.
	var diff = data.point_count - context.known_points.size()

	# Remove
	if diff < 0:
		for i in range(abs(diff)):
			var n = context.known_points.pop_back()
			n.queue_free()
	
	# Add.
	if diff > 0:
		for i in range(diff):
			var child: EditableCurveControlPoint = control_point_scene.instantiate()
			context.known_points.append(child)
			child.context = context
			child.movement_start.connect(_capture_undoredo_start)
			child.movement_update.connect(_handle_controlpoint_movement_update)
			child.scale_update.connect(_handle_controlpoint_scale_update)
			child.movement_end.connect(_capture_undoredo_end)
			add_child(child)

func _handle_controlpoint_scale_update(n: EditableCurveControlPoint, s: Vector3):
	var idx = n.get_curve_index()
	_update_curve_based_on_scale(idx, s)

func _handle_controlpoint_movement_update(n: EditableCurveControlPoint, t: Transform3D):
	var idx = n.get_curve_index()
	_update_curve_based_on_transform(idx, t)

# Usually when adding a point to the end of the curve
# its nice to have the basis aligned in some logicaly way
func align_basis_to_end_of_curve(t: Transform3D) -> Transform3D:
	# Nothing to align to
	if data.point_count == 0:
		return t
	
	var last_point_pos = data.get_point_position(data.point_count - 1)
	t = t.looking_at(last_point_pos, Vector3.UP, true) # Invert because looking backwards.
	return t

func get_transform_between(i1: int, i2: int):
	var i1_offset = data.get_closest_offset(data.get_point_position(i1))
	var i2_offset = data.get_closest_offset(data.get_point_position(i2))
	var center = (i1_offset + i2_offset) / 2.0
	return data.sample_baked_with_rotation(center, false, true)

func _update_curve_based_on_scale(idx: int, s: Vector3):
	data.set_point_scale(idx, s)
	curve_updated.emit()

func _update_curve_based_on_transform(idx: int, t: Transform3D):
	# Extend curve if given -1
	if idx == -1:
		data.add_point(t.origin)
		idx = data.point_count - 1
	
	data.set_point_position(idx, t.origin)
	
	var is_start = idx == 0
	var is_end = idx == (data.point_count - 1)
	
	if !is_start:
		data.set_point_in(idx, t.basis.z.normalized()) # Back
	
	if !is_start:
		data.set_point_out(idx, -t.basis.z.normalized()) # Front
	
	var ref = Plane(t.basis.z).project(Vector3.UP).normalized()
	var tilt = ref.signed_angle_to(t.basis.y, -t.basis.z)
	data.set_point_tilt(idx, tilt)

	curve_updated.emit()

func _on_curve_updated():
	_match_controlpoints_to_curve_point_count()
	_align_controlpoints_to_curve()

func _align_controlpoints_to_curve():
	if !data:
		return
	
	for i in range(data.point_count):
		var n: EditableCurveControlPoint = context.known_points[i]
		
		# Note - we do NOT use sample_baked_with_rotation here
		# Because the values this produces are != what is actually set at that exact index.
		# We want to basically recreate what the curve data is at this index (in,out,pos,tilt)
		
		n.global_position = data.get_point_position(i)
		n.curve_scale = data.get_point_scale(i)
		
		var is_end = i == (data.point_count - 1)
		if !is_end:
			# Look at out forwards.
			var out = data.get_point_out(i)
			
			if out != Vector3.ZERO:
				var look_at_up_vector = Vector3.UP.rotated(out.normalized(), data.get_point_tilt(i))
				n.look_at(n.global_position + out, look_at_up_vector)
		else:
			# If end, look at in backwards.
			var in_dir = data.get_point_in(i)
			
			if in_dir != Vector3.ZERO:
				var look_at_up_vector = Vector3.UP.rotated(in_dir.normalized(), -data.get_point_tilt(i))
				n.look_at(n.global_position + in_dir, look_at_up_vector, true)
