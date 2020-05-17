tool
extends WindowDialog

onready var normalEdit = $vbox/hbox/leftVbox/vector3Vbox
onready var normalDraw = $vbox/hbox/leftVbox/Panel/normal
onready var localDirOptBtn = $vbox/hbox/rightVbox/localHbox/dirOptBtn
onready var localDegEdit = $vbox/hbox/rightVbox/localHbox/degEdit
onready var globalDirOptBtn = $vbox/hbox/rightVbox/globalHbox/dirOptBtn
onready var globalDegEdit = $vbox/hbox/rightVbox/globalHbox/degEdit

var quat := Quat(Vector3(0, 0, 0))
enum { NONE, MODIFY, MODIFY_SAVE }
var choosed := NONE
var pressQuat = null

func _ready():
	normalEdit.set_quat(quat)
	normalDraw.set_quat(quat)
	#print(str((Quat(Vector3(0, 0, 1).normalized(), deg2rad(60)) * Quat(Vector3(deg2rad(60), deg2rad(0), deg2rad(45))).get_euler())))

func set_euler(p_euler:Vector3):
	set_quat(Quat(p_euler))

func set_quat(p_quat:Quat):
	quat = p_quat
	if is_inside_tree():
		normalEdit.set_quat(quat)
		normalDraw.set_quat(quat)

func set_normal(p_normal:Vector3):
	set_quat(Quat(p_normal.cross(Vector3(0, 0, 1)).normalized(), p_normal.angle_to(Vector3(0, 0, 1))))

func get_euler() -> Vector3:
	return quat.get_euler()

func get_quat() -> Quat:
	return quat

func get_normal() -> Vector3:
	return quat.xform(Vector3(0, 0, 1))

func _on_vector3Vbox_value_changed():
	var vec = normalEdit.get_euler()
	quat = Quat(vec)
	if is_inside_tree():
		normalDraw.set_quat(quat)
	#print(str(normalEdit.get_euler()))



func _on_localRotateBtn_pressed():
	var axis:Vector3
	match localDirOptBtn.get_selected_id():
		0:
			axis = quat.xform(Vector3(1, 0, 0))
		1:
			axis = quat.xform(Vector3(0, 1, 0))
		2:
			axis = quat.xform(Vector3(0, 0, 1))
	set_quat(Quat(axis.normalized(), deg2rad(localDegEdit.value)) * quat)




func _on_globalRotateBtn_pressed():
	var axis:Vector3
	match globalDirOptBtn.get_selected_id():
		0:
			axis = Vector3(1, 0, 0)
		1:
			axis = Vector3(0, 1, 0)
		2:
			axis = Vector3(0, 0, 1)
	set_quat(Quat(axis.normalized(), deg2rad(globalDegEdit.value)) * quat)


func _on_modifyBtn_pressed():
	choosed = MODIFY
	hide()


func _on_self_about_to_show():
	choosed = NONE


func _on_modifySaveBtn_pressed():
	choosed = MODIFY_SAVE
	hide()


func _on_normal_drag(press_pos, relative):
	if pressQuat == null:
		pressQuat = get_quat()
	
	var d = get_local_mouse_position() - press_pos
	set_quat(Quat(Vector3(0.0, 1.0, 0.0), d.x / (normalDraw.rect_size.x * 0.6) * PI) * Quat(Vector3(1.0, 0.0, 0.0), -d.y / (normalDraw.rect_size.y * 0.6) * PI) * pressQuat)


func _on_normal_pressed():
	pressQuat = null
