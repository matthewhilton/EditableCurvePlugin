class_name EditableCurveInstance extends Node3D

# The actual data about the curve, e.g. curve itself, any other metadata, etc...
@export var curve: EditableCurve
@export var control_point_scene: PackedScene

# Useful way for all the control points to keep in sync with each other.
var context := EditableCurveContext.new()
var undo_redo := UndoRedo.new()

signal curve_updated

func _ready():
	_match_controlpoints_to_curve_point_count()
	curve_updated.connect(_on_curve_updated)
	undo_redo.version_changed.connect(func(): print("undoredo version changed"))

func _input(event):
	if event.is_action_pressed("ui_undo") && _is_selected():
		undo_redo.undo()
	
	if event.is_action_pressed("ui_redo") && _is_selected():
		undo_redo.redo()

func _capture_undoredo_start():
	undo_redo.create_action("Edit curve")
	undo_redo.add_undo_property(self, "curve", curve.duplicate())
	undo_redo.add_undo_method(func(): curve_updated.emit())

func _capture_undoredo_end():
	undo_redo.add_do_property(self, "curve", curve.duplicate())
	undo_redo.add_do_method(func(): curve_updated.emit())
	undo_redo.commit_action(false)

func _is_selected():
	return true # If you had multiple you would check here which is active.

func add_to_end(t: Transform3D):
	_capture_undoredo_start()
	_update_curve_based_on_transform(-1, t)
	_capture_undoredo_end()

# Ensure we have a control point for each curve point.
# Delete any extras, or add any missing.
func _match_controlpoints_to_curve_point_count():
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
			var child: EditableCurveControlPoint = control_point_scene.instantiate()
			context.known_points.append(child)
			child.context = context
			child.movement_start.connect(_capture_undoredo_start)
			child.movement_update.connect(_handle_controlpoint_movement_update)
			child.movement_end.connect(_capture_undoredo_end)
			add_child(child)

func _handle_controlpoint_movement_update(n: EditableCurveControlPoint, t: Transform3D):
	var idx = n.get_curve_index()
	_update_curve_based_on_transform(idx, t)

func _update_curve_based_on_transform(idx: int, t: Transform3D):
	# Extend curve if given -1
	if idx == -1:
		curve.add_point(t.origin)
		idx = curve.point_count - 1
	
	curve.set_point_position(idx, t.origin)
	
	var is_start = idx == 0
	var is_end = idx == (curve.point_count - 1)
	
	if !is_start:
		curve.set_point_in(idx, t.basis.z) # Back
	
	if !is_start:
		curve.set_point_out(idx, -t.basis.z) # Front
	
	var ref = Plane(t.basis.z).project(Vector3.UP).normalized()
	var tilt = ref.signed_angle_to(t.basis.y, -t.basis.z)
	curve.set_point_tilt(idx, tilt)
	
	# TODO in/out scale based on distance to/from previous ?

	curve_updated.emit()

func _on_curve_updated():
	_match_controlpoints_to_curve_point_count()
	_align_controlpoints_to_curve()

func _align_controlpoints_to_curve():
	for i in range(curve.point_count):
		var n: EditableCurveControlPoint = context.known_points[i]
		
		# Note - we do NOT use sample_baked_with_rotation here
		# Because the values this produces are != what is actually set at that exact index.
		# We want to basically recreate what the curve data is at this index (in,out,pos,tilt)
		
		n.global_position = curve.get_point_position(i)
		
		var is_end = i == (curve.point_count - 1)
		if !is_end:
			# Look at out forwards.
			var out = curve.get_point_out(i)
			
			if out != Vector3.ZERO:
				var look_at_up_vector = Vector3.UP.rotated(out, curve.get_point_tilt(i))
				n.look_at(n.global_position + out, look_at_up_vector)
		else:
			# If end, look at in backwards.
			var in_dir = curve.get_point_in(i)
			
			if in_dir != Vector3.ZERO:
				var look_at_up_vector = Vector3.UP.rotated(in_dir, -curve.get_point_tilt(i))
				n.look_at(n.global_position + in_dir, look_at_up_vector, true)
