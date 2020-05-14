tool
extends Panel

signal value_changed

func _on_vector3Vbox_resized():
	rect_size = $vector3Vbox.rect_size


func _on_LineEdit_value_changed():
	emit_signal("value_changed")

func get_normal():
	return Quat(get_euler()).xform(Vector3(0, 0, 1))

func set_normal(p_n:Vector3):
	var cross = p_n.cross(Vector3(0, 0, 1)).normalized()
	var cross2 = Vector3(0, 0, 1).cross(cross).normalized()
	if p_n.dot(cross2) >= 0:
		set_quat(Quat(cross, -p_n.angle_to(Vector3(0, 0, 1))))
	else:
		set_quat(Quat(cross, p_n.angle_to(Vector3(0, 0, 1))))

func get_euler() -> Vector3:
	return Vector3(deg2rad($vector3Vbox/xHbox/LineEdit.get_value()), deg2rad($vector3Vbox/yHbox/LineEdit.get_value()), deg2rad($vector3Vbox/zHbox/LineEdit.get_value()))

func set_quat(p_quat:Quat):
	set_euler(p_quat.get_euler())

func get_quat() -> Quat:
	return Quat(get_euler())

func set_euler(p_vec:Vector3):
	#print("p_vec: ", str(rad2deg(p_vec.x)), ", ", str(rad2deg(p_vec.y)), ", ", str(rad2deg(p_vec.z)))
	$vector3Vbox/xHbox/LineEdit.set_value(rad2deg(p_vec.x))
	$vector3Vbox/yHbox/LineEdit.set_value(rad2deg(p_vec.y))
	$vector3Vbox/zHbox/LineEdit.set_value(rad2deg(p_vec.z))
