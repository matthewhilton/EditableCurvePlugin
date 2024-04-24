class_name CurveStructureGeneratorWoodPlankPath extends CurveStructureGenerator

@export_flags_3d_physics var ground_raycast_mask := 0

@export_category("Planks")
@export var plank_width := 0.5
@export var plank_height := 0.2
@export var plank_gap := 0.1

@export_category("Vertical supports")
@export var supports_max_height := 10 # TODO limit these via raycast to ground.
@export var supports_square_size := 0.5
@export var supports_spacing := 4.0

# TODO horizontal supports.

# TODO crossbeams.

func generate(data: CurveData, state: PhysicsDirectSpaceState3D) -> Node3D:
	if !data.curve:
		return Node3D.new()
	
	var parent = Node3D.new()
	
	# Top planks.
	parent.add_child(_get_top_planks_mmi(data))
	
	# Vertical supports.
	parent.add_child(_get_vertical_supports_mmi(data, state))
	
	return parent

func _get_vertical_supports_mmi(data: CurveData, state: PhysicsDirectSpaceState3D) -> MultiMeshInstance3D:
	var num_supports = ceil(data.curve.get_baked_length() / (supports_square_size + supports_spacing)) # Add two for final posts.
	
	# Avoid fencepost problem by removing 1 to count gaps not posts.
	var offset_per_support = data.curve.get_baked_length() / (num_supports - 1)
	
	var multimesh = MultiMesh.new()
	multimesh.mesh = BoxMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = num_supports * 2 # One support on either side.
	
	for i in range(num_supports):
		# Don't sample near the end, since it produces odd results.
		var offset = min(i * offset_per_support, data.curve.get_baked_length() - 0.2)
		var t = data.curve.sample_baked_with_rotation(offset, false, true)
		var width = data.get_width_at_offset(offset)
		
		# Scale horizontally
		t.basis.x *= supports_square_size
		t.basis.z *= supports_square_size
		
		# Left side.
		var left_top = t.translated(t.basis.x.normalized() * width / 2.0)
		var left_height = get_ground_height(state, left_top.origin, -left_top.basis.y, supports_max_height)
		left_top.basis.y *= left_height
		var left_center = left_top.translated(-left_top.basis.y.normalized() * left_height / 2.0)
		
		# Right side.
		var right_top = t.translated(-t.basis.x.normalized() * width / 2.0)
		var right_height = get_ground_height(state, right_top.origin, -right_top.basis.y, supports_max_height)
		right_top.basis.y *= right_height
		var right_center = right_top.translated(-right_top.basis.y.normalized() * left_height / 2.0)
		
		# TODO make this reusable, and also make it flip around if upside down ?
		
		multimesh.set_instance_transform(i, left_center)
		multimesh.set_instance_transform(i + num_supports, right_center)
	
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
		# Don't sample near the end, since it produces odd results.
		var offset = min(i * offset_per_plank, data.curve.get_baked_length() - 0.2)
		var structure_width = data.get_width_at_offset(offset)
	
		var t = data.curve.sample_baked_with_rotation(offset, false, true)
		
		t.basis.x *= structure_width
		t.basis.z *= plank_width
		t.basis.y *= plank_height
		multimesh.set_instance_transform(i, t)
	
	var mmi = MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	return mmi

func get_ground_height(state: PhysicsDirectSpaceState3D, origin: Vector3, dir: Vector3, max := 100, default := 10):
	var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * max, ground_raycast_mask)
	var result = state.intersect_ray(query)
	
	if "position" not in result:
		return default
	
	return origin.distance_to(result.position)
