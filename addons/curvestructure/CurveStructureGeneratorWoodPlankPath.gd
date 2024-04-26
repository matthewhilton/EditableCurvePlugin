class_name CurveStructureGeneratorWoodPlankPath extends CurveStructureGenerator

@export_flags_3d_physics var ground_raycast_mask := 0

@export_category("Planks")
@export var plank_width := 0.5
@export var plank_depth := 0.2
@export var plank_gap := 0.1

@export_category("Vertical supports")
@export var supports_max_height := 30
@export var supports_square_size := 0.5
@export var supports_spacing := 2.0

@export_category("Crossbeams")
@export var crossbeam_support_end_offset := 0.5

# TODO horizontal supports.

# TODO crossbeams.

class Plank:
	var start: Vector3
	var end: Vector3
	var basis: Basis
	var depth := 0.2
	var width := 0.5
	var curve_offset := 0.0
	
	func to_transform3d():
		var t = Transform3D()
		t.basis = basis
	
		t.basis.x = t.basis.x.normalized() * start.distance_to(end)
		t.basis.y = t.basis.y.normalized() * depth
		t.basis.z = t.basis.z.normalized() * width
		
		t.origin = (start + end) / 2.0
		
		return t

func generate(data: CurveData, state: PhysicsDirectSpaceState3D) -> Node3D:
	if !data.curve:
		return Node3D.new()
	
	var parent = Node3D.new()
	
	var planks: Array[Plank] = _generate_top_planks(data)
	parent.add_child(_bake_objects_to_mmi(planks))
	
	var support_beams: Array[Plank] = _generate_support_beams(data, state)
	parent.add_child(_bake_objects_to_mmi(support_beams))
	
	return parent

func _bake_objects_to_mmi(objects: Array):
	var multimesh = MultiMesh.new()
	multimesh.mesh = BoxMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = objects.size()
	
	for i in range(objects.size()):
		multimesh.set_instance_transform(i, objects[i].to_transform3d())
	
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	return mmi
	
func _generate_top_planks(data: CurveData):
	# First calculate the number of planks.
	var num_planks = ceil(data.curve.get_baked_length() / (plank_width + plank_gap))
	
	# Avoid fencepost problem by removing 1 to count gaps not posts.
	var offset_per_plank = data.curve.get_baked_length() / (num_planks - 1)
	
	var planks_generated: Array[Plank] = []
	for i in range(num_planks):
		# Don't sample near the end, since it produces odd results.
		var offset = min(i * offset_per_plank, data.curve.get_baked_length() - 0.2)
		var structure_width = data.get_width_at_offset(offset)
		var t := data.curve.sample_baked_with_rotation(offset, false, true)
		
		var plank = Plank.new()
		plank.basis = t.basis
		plank.start = t.translated(t.basis.x * structure_width / 2.0).origin
		plank.end = t.translated(-t.basis.x * structure_width / 2.0).origin
		plank.width = plank_width
		plank.depth = plank_depth
		plank.curve_offset = offset
		planks_generated.append(plank)
	
	return planks_generated

func _generate_support_beams(data: CurveData, state: PhysicsDirectSpaceState3D):
	var num_supports = ceil(data.curve.get_baked_length() / (supports_square_size + supports_spacing)) # Add two for final posts.
	
	# Avoid fencepost problem by removing 1 to count gaps not posts.
	var offset_per_support = data.curve.get_baked_length() / (num_supports - 1)
	
	var supports_generated: Array[Plank] = []
	for i in range(num_supports):
		# Don't sample near the end, since it produces odd results.
		var offset = min(i * offset_per_support, data.curve.get_baked_length() - 0.2)
		var structure_width = data.get_width_at_offset(offset)
		var t := data.curve.sample_baked_with_rotation(offset, false, true)
		
		# Generate left and right down posts.
		var downposts_at_this_offset = []
		
		for dir in [-1, 1]:
			var support = Plank.new()
			
			# Rotate basis so +X is the expand direction (up/down)
			support.basis = t.basis.rotated(t.basis.z, -deg_to_rad(90))
			support.start = t.origin + (dir * t.basis.x * structure_width / 2.0)
			
			# Raycast to get ground.
			var support_height = get_ground_height(state, support.start, -t.basis.y, supports_max_height)
			
			# No raycast hit or is tiny, ignore.
			if support_height == null || support_height < 0.1:
				continue
			
			support.end = support.start + (-t.basis.y * support_height)
			support.width = supports_square_size
			support.depth = supports_square_size
			support.curve_offset = offset
			supports_generated.append(support)
			downposts_at_this_offset.append(support)
		
		# If we generated 2 downposts, generate a cross beam.
		var has_twodownposts = downposts_at_this_offset.size() == 2
		var downposts_have_enough_length = downposts_at_this_offset.filter(func(d): return d.start.distance_to(d.end) > crossbeam_support_end_offset * 2).size() == 2
		
		if has_twodownposts && downposts_have_enough_length:
			var crossbeam = Plank.new()
			
			# Alternate which is the start and end
			var start_downpost_idx = int(i % 2 == 0)
			var end_downpost_idx = abs(start_downpost_idx - 1)
			
			crossbeam.start = downposts_at_this_offset[start_downpost_idx].start - t.basis.y * crossbeam_support_end_offset
			crossbeam.end = downposts_at_this_offset[end_downpost_idx].end + t.basis.y * crossbeam_support_end_offset
			
			# Rotate it so it goes diagonally from start -> end
			var angle = t.basis.x.signed_angle_to(crossbeam.start.direction_to(crossbeam.end), -t.basis.z)
			crossbeam.basis = t.basis.rotated(-t.basis.z, angle)
			crossbeam.curve_offset = offset
			crossbeam.width = supports_square_size
			crossbeam.depth = supports_square_size
			supports_generated.append(crossbeam)
		
	return supports_generated

func get_ground_height(state: PhysicsDirectSpaceState3D, origin: Vector3, dir: Vector3, max := 30, default = null):
	var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * max, ground_raycast_mask)
	var result = state.intersect_ray(query)
	
	if "position" not in result:
		return default
	
	return origin.distance_to(result.position)
