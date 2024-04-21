class_name CurveStructureGeneratorWoodPlankPath extends CurveStructureGenerator

@export_category("Planks")
@export var plank_width := 0.5
@export var plank_height := 0.2
@export var plank_gap := 0.1

@export_category("Vertical supports")
@export var supports_max_height := 5 # TODO limit these via raycast to ground.
@export var supports_square_size := 0.5
@export var supports_spacing := 4.0

# TODO horizontal supports.

# TODO crossbeams.

func generate(data: CurveData) -> Node3D:
	if !data.curve:
		push_error("No curve defined, cannot generate structure")
		return Node3D.new()
	
	var parent = Node3D.new()
	
	# Top planks.
	parent.add_child(_get_top_planks_mmi(data))
	
	# Vertical supports.
	parent.add_child(_get_vertical_supports_mmi(data))
	
	return parent

func _get_vertical_supports_mmi(data: CurveData) -> MultiMeshInstance3D:
	var num_supports = ceil(data.curve.get_baked_length() / (supports_square_size + supports_spacing)) # Add two for final posts.
	
	# Avoid fencepost problem by removing 1 to count gaps not posts.
	var offset_per_support = data.curve.get_baked_length() / (num_supports - 1)
	
	print("[Gen] ", num_supports, " supports")
	
	var multimesh = MultiMesh.new()
	multimesh.mesh = BoxMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = num_supports * 2 # One support on either side.
	
	for i in range(num_supports):
		var offset = i * offset_per_support
		var t = data.curve.sample_baked_with_rotation(offset, false, false)
		
		var width = data.get_width_at_offset(offset)
		var height = supports_max_height # TODO raycast to get actual height.
		
		# Scale.
		t.basis.x *= supports_square_size
		t.basis.z *= supports_square_size
		t.basis.y *= height
		
		# Translate left and right (normalise so scale does not affect it)
		var left_t = t.translated(t.basis.x.normalized() * width / 2.0).translated(-t.basis.y.normalized() * height / 2.0)
		var right_t = t.translated(-t.basis.x.normalized() * width / 2.0).translated(-t.basis.y.normalized() * height / 2.0)
		
		multimesh.set_instance_transform(i, left_t)
		multimesh.set_instance_transform(i + num_supports, right_t)
	
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	return mmi
	
func _get_top_planks_mmi(data: CurveData) -> MultiMeshInstance3D:
	# First calculate the number of planks.
	var num_planks = ceil(data.curve.get_baked_length() / (plank_width + plank_gap))
	
	# Avoid fencepost problem by removing 1 to count gaps not posts.
	var offset_per_plank = data.curve.get_baked_length() / (num_planks - 1)
	
	# Make wood plank path with multimesh.
	var multimesh = MultiMesh.new()
	multimesh.mesh = BoxMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = num_planks
	
	for i in range(num_planks):
		var offset = i * offset_per_plank
		var structure_width = data.get_width_at_offset(offset)
		var t = data.curve.sample_baked_with_rotation(offset, false, false)
		t.basis.x *= structure_width
		t.basis.z *= plank_width
		t.basis.y *= plank_height
		multimesh.set_instance_transform(i, t)
	
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	return mmi
