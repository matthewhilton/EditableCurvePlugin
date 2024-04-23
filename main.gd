extends Node3D

@export var delete_selected: Button
@export var add_new_selected: Button
@export var generate_structure: Button
@export var curve: EditableCurveInstance
@export var structure: CurveStructureInstance
@export var path: Path3D

func _ready():
	delete_selected.pressed.connect(func(): curve.delete_selected_control())
	add_new_selected.pressed.connect(_add_new_selected)
	curve.curve_updated.connect(func(): _regenerate())
	generate_structure.pressed.connect(func(): _regenerate())

func _regenerate():
	structure.curve_data.curve = curve.curve
	structure.regenerate()
	
func _add_new_selected():
	var cam: Camera3D = get_viewport().get_camera_3d()
	var pos = cam.global_position - cam.global_basis.z * 5.0
	curve.add_point_at_end_of_curve(pos)
