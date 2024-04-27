class_name ControlPointControlScaleArrow extends ControlPointControl

@export var MIN_SCALE := Vector3.ONE
@export var scale_axis := Vector3.FORWARD

# Vector3, but nullable.
var last_drag_pos = null

func _init():
	type = TYPE.SCALE

func _ready():
	drag_end.connect(func(): last_drag_pos = null)

# Arrows only move linearly in the direction of their global Y basis vector.
func _get_movement_dir() -> Vector3:
	return global_basis.y

func _get_face_normal() -> Vector3:
	return global_basis.x

func _handle_drag_event(event: InputEvent):
	if !(event is InputEventMouseMotion):
		return
	
	# Make a plane of this node and raycast the drag pos.
	var plane = Plane(drag_start_normal, global_position)
	var cam := get_viewport().get_camera_3d()
	var normal = cam.project_ray_normal(event.position)
	var ray_hit = plane.intersects_ray(cam.global_position, normal)
	
	if !ray_hit:
		return
	
	# Make a fake curve3D along the movement dir.
	var curve := Curve3D.new()
	curve.add_point(global_position + _get_movement_dir() * 20)
	curve.add_point(global_position - _get_movement_dir() * 20)
	
	# Sample to snap to the linear axis.
	var drag_pos = curve.get_closest_point(ray_hit)
	drag_pos = to_local(drag_pos)
	
	if !last_drag_pos:
		last_drag_pos = drag_pos
		return
	
	# Calculate the diff from the previous frame.
	var diff = (drag_pos - last_drag_pos)
	last_drag_pos = drag_pos
	
	var scale_val = scale_axis * diff.y
	movement_scale.emit(scale_val)
	
	#print(diff)
	
	#var current_scale = get_parent().point_data.global_transform.basis.get_scale()
	#var change = _get_movement_dir() * diff
	#print("scale diff: ", diff, " change: ", change, " dir: ", _get_movement_dir())
	
	# TODO.
	
	# Convert the diff along the axis of the model, to the desired scale diff
	# TODO should be able to calculate this from the pose, but this works for now.
	#var maxaxis_i = diff.abs().max_axis_index()
	#var scale_delta = scale_axis * diff[maxaxis_i]
	#var current_scale = get_parent().curve_transform_tracker.scale
	#var new_scale = current_scale + scale_delta
	#
	## Ensure its always at least the MIN_SCALE
	#new_scale.x = max(new_scale.x, MIN_SCALE.x)
	#new_scale.y = max(new_scale.y, MIN_SCALE.y)
	#new_scale.z = max(new_scale.z, MIN_SCALE.z)
	#
	#movement_scale.emit(new_scale)
