class_name CurveStructureInstance extends Node3D

@export var curve_data: CurveData
@export var structure_generator: CurveStructureGenerator

func _ready():
	regenerate()

func regenerate():
	for child in get_children():
		child.queue_free()
	
	if !curve_data || !structure_generator:
		push_error("No curve data or structure generator defined")
		return
		
	add_child(structure_generator.generate(curve_data, get_world_3d().direct_space_state))
