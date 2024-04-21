extends Node3D

func _input(event):
	if event.is_action_pressed("add_control_point"):
		var cam: Camera3D = $Camera3D
		var pos = cam.global_position - cam.global_basis.z * 2.0
		$EditableCurve.add_point_at_end_of_curve(pos)
