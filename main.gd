extends Node3D

@export var delete_selected: Button
@export var add_new_selected: Button
@export var generate_structure: Button
@export var smooth_button: Button
@export var curve: EditableCurveInstance
@export var structure: CurveStructureInstance
@export var path: Path3D

func _ready():
	delete_selected.pressed.connect(func(): curve.delete_selected_control())
	add_new_selected.pressed.connect(_add_new_selected)
	smooth_button.pressed.connect(func(): EditableCurveUtils.smooth_curve_corners(curve.data.curve))
	
	path.curve = curve.data.curve
	structure.curve_data.curve = curve.data.curve
	
	generate_structure.pressed.connect(func(): structure.regenerate())

func _add_new_selected():
	var cam: Camera3D = $Camera3D
	var pos = cam.global_position - cam.global_basis.z * 30.0
	curve.add_point_at_end_of_curve(pos)
