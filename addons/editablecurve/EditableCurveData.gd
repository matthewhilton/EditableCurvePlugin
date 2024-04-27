class_name EditableCurveData extends Curve3DWithHooks

@export var _internal_scale_store: Array[Vector3] = []

func _init():
	add_point_called.connect(_on_add_point_called)
	remove_point_called.connect(_on_remove_point_called)
	super._init()

func _on_add_point_called(position: Vector3, in_vec: Vector3, out_vec: Vector3, index: int):
	# Add to end.
	if index == -1:
		_internal_scale_store.append(Vector3.ONE)
		return
	
	# Else insert before.
	_internal_scale_store.insert(index, Vector3.ONE)
	
func _on_remove_point_called(idx: int):
	_internal_scale_store.remove_at(idx)

func set_point_scale(idx: int, scale: Vector3):
	_internal_scale_store[idx] = scale

func get_point_scale(idx: int) -> Vector3:
	return _internal_scale_store[idx];

func sample_scale_at_offset(offset: float) -> Vector3:
	var i_prev = -1
	var i_next = -1
	
	var offset_prev = -1;
	var offset_next = -1;
	
	for i in range(_internal_curve.point_count):
		var this_i_offset = _internal_curve.get_closest_offset(_internal_curve.get_point_position(i))
		
		if is_equal_approx(this_i_offset, offset):
			return _internal_scale_store[i]
		
		if this_i_offset < offset:
			i_prev = i
			offset_prev = this_i_offset
		
		if this_i_offset > offset:
			i_next = i
			offset_next = this_i_offset
		
		if i_prev != -1 && i_next != -1:
			break
	
	assert(offset_prev < offset)
	assert(offset_next > offset)

	var percentage = (offset - offset_prev) / (offset_next - offset_prev)
	
	assert(percentage >= 0.0)
	assert(percentage <= 1.0)
	
	var result = _internal_scale_store[i_prev].lerp(_internal_scale_store[i_next], percentage)
	
	return result
