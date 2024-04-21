extends Node3D

@export var delete_selected: Button
@export var add_new_selected: Button
@export var curve: EditableCurveInstance
@export var path: Path3D

func _ready():
	delete_selected.pressed.connect(func(): curve.delete_selected_control())
	add_new_selected.pressed.connect(_add_new_selected)
	
	path.curve = curve.data.curve

func _add_new_selected():
	var cam: Camera3D = $Camera3D
	var pos = cam.global_position - cam.global_basis.z * 30.0
	curve.add_point_at_end_of_curve(pos)
