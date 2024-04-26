class_name ControlPointSize extends ControlPointControl

func _get_axis():
	return global_basis.x

func _handle_drag_event(event: InputEvent):
	if !(event is InputEventMouseMotion):
		return

	movement_scale.emit(_get_axis() * event.relative.y)
