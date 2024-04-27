class_name EditableCurveData extends Curve3DWithHooks

@export var _internal_width_store: Array[float] = []

func _init():
	add_point_called.connect(_on_add_point_called)
	remove_point_called.connect(_on_remove_point_called)
	super._init()

func _on_add_point_called(position: Vector3, in_vec: Vector3, out_vec: Vector3, index: int):
	# Add to end.
	if index == -1:
		_internal_width_store.append(1.0)
		return
	
	# Else insert before.
	_internal_width_store.insert(index, 1.0)
	
func _on_remove_point_called(idx: int):
	_internal_width_store.remove_at(idx)

func set_point_width(idx: int, width: float):
	_internal_width_store[idx] = width

func get_point_width(idx: int) -> float:
	return _internal_width_store[idx];

func sample_width_at_offset(offset: float) -> float:
	var i_prev = -1
	var i_next = -1
	
	var offset_prev = -1;
	var offset_next = -1;
	
	for i in range(_internal_curve.point_count):
		var this_i_offset = _internal_curve.get_closest_offset(_internal_curve.get_point_position(i))
		
		if is_equal_approx(this_i_offset, offset):
			return _internal_width_store[i]
		
		if this_i_offset < offset:
			i_prev = i
			offset_prev = this_i_offset
		
		if this_i_offset > offset:
			i_next = i
			offset_next = this_i_offset
		
		if i_prev != -1 && i_next != -1:
			break
	
	if i_prev == -1 && i_next == -1:
		# If reached here, it means we got no matches.
		# Just return default.
		return 1.0
	
	assert(offset_prev < offset)
	assert(offset_next > offset)
	assert(abs(i_prev - i_next) == 1)

	var percentage = (offset - offset_prev) / (offset_next - offset_prev)
	
	assert(percentage >= 0.0)
	assert(percentage <= 1.0)
	
	var prev_width = _internal_width_store[i_prev]
	var next_width = _internal_width_store[i_next]
	var val = lerp(prev_width, next_width, percentage)
	
	#print(offset, " was between ", i_prev, " and ", i_next, " widths: ", prev_width, " -> ", next_width, " val: ", val)
	
	return val
