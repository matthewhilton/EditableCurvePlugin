class_name EditableCurveContext extends Resource

var control_point_selected: EditableCurveControlPoint:
	set(v):
		control_point_selected = v
		print("[EditableCurveContext] Index ", v.get_curve_index() if v else "null", " selected")
		selected_control_point_changed.emit()

signal selected_control_point_changed

var known_points: Array[EditableCurveControlPoint]
var controls_active := true
