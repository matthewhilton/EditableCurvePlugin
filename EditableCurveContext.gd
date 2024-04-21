class_name EditableCurveContext extends Resource

var control_point_selected: EditableCurveControlPoint:
	set(v):
		control_point_selected = v
		print("[EditableCurveContext] Index ", v.child_index if v else "null", " selected")
		selected_control_point_changed.emit()

signal selected_control_point_changed
