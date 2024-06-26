class_name EditableCurveUtils extends Node

static func curve_point_distance(curve_to_use: Curve3D, from_i = 0, to_i = 0, normalise: bool = true) -> Vector3:
	var vec = (curve_to_use.get_point_position(to_i) - curve_to_use.get_point_position(from_i))
	return vec if not normalise else vec.normalized()

static func smooth_curve_corners(curve_to_smooth: Curve3D, in_out_scale: float = 0.25):
	if(curve_to_smooth.point_count < 3):
		return

	for i in range(0, curve_to_smooth.point_count):

		# Start - only set out
		if(i == 0):
			curve_to_smooth.set_point_out(i, curve_point_distance(curve_to_smooth, i, i+1) * in_out_scale * 0.05)
		
		# End - only set in
		elif(i == curve_to_smooth.point_count - 1):
			curve_to_smooth.set_point_in(i, curve_point_distance(curve_to_smooth, i-1, i) * in_out_scale * 0.05)
		
		else:
			# Else get vector between n-1 to n+1 (unnormalised)
			var distance = curve_point_distance(curve_to_smooth, i-1, i+1)
			
			# Get the distance to n-1 and n+1 which determines the scale of the in/out handles
			var distance_to_before = curve_point_distance(curve_to_smooth, i-1, i, false).length()
			var distance_to_after = curve_point_distance(curve_to_smooth, i+1, i, false).length()
			
			# Use the shortest of the two
			var shortest_distance_to = min(distance_to_before, distance_to_after)
			
			var local_scale = shortest_distance_to * in_out_scale
			
			curve_to_smooth.set_point_in(i, -distance * local_scale)
			curve_to_smooth.set_point_out(i, +distance * local_scale)

static func loop_next(array: Array, current_val):
	var current_i = array.find(current_val)
	var next_i = 0 if current_i >= (array.size() - 1) else current_i + 1
	return array[next_i]

static func get_index_to_insert_pos_after(curve: Curve3D, to: Vector3) -> int:
	var target_offset := curve.get_closest_offset(to)
	
	for i in range(curve.point_count):
		var this_offset = curve.get_closest_offset(curve.get_point_position(i))
		
		if this_offset > target_offset:
			return i
	
	return -1

static func get_closest_i_to_offset(curve: Curve3D, offset: float) -> int:
	var point_offsets = range(curve.point_count).map(func(i): return [i, curve.get_closest_offset(curve.get_point_position(i))])
	point_offsets.sort_custom(func(a,b): return a[1].distance_to(offset) < b[1].distance_to(offset))
	
	return point_offsets[0][0]
