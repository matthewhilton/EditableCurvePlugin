class_name EditableCurve extends Node3D

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
	child.child_index = i
	add_child(child)
	
	child.moved_while_selected.connect(_update_curve_pos_from_controlpoint_movement)

func _update_curve_pos_from_controlpoint_movement(node: EditableCurveControlPoint):
	data.curve.set_point_position(node.child_index, node.global_position)

func add_point_at_end_of_curve(pos: Vector3):
	data.curve.add_point(pos)
	# Add new child (no need to rebuild all)
	_add_controlpoint_at_index(data.curve.point_count - 1)
