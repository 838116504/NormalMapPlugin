tool
extends WindowDialog

const SECTION = "CreateRectPop"

onready var editNormalPop = get_node("../editNormalPop")
onready var sizeVbox = $vbox/hbox/vbox/sizeHbox/sizeVbox
onready var rotIcon = $vbox/hbox/vbox/rotHbox/hbox/rotModifyBtn/rotDraw
onready var rotVbox = $vbox/hbox/vbox/rotHbox/rotVbox
onready var normalTypeOptBtn = $vbox/hbox/vbox2/normalTypeHbox/OptBtn
onready var normal = $vbox/hbox/vbox2/normalHbox/vbox/normalVbox
onready var normalIcon = $vbox/hbox/vbox2/normalHbox/vbox/hbox/modifyBtn/normalDraw
onready var templatePanel = $vbox/hbox/vbox2/normalHbox/templatePanel
onready var embossCheckBox = $vbox/hbox/vbox2/embossHbox/embossCheckBox
onready var embossHSlider = $vbox/hbox/vbox2/embossHbox/embossHSlider
onready var bumpCheckBox = $vbox/hbox/vbox2/bumpHeightHbox/bumpCheckBox
onready var bumpHeightHSlider = $vbox/hbox/vbox2/bumpHeightHbox/bumpHeightHSlider
onready var blurSpinBox = $vbox/hbox/vbox2/blurHbox/SpinBox
onready var bumpSpinBox = $vbox/hbox/vbox2/bumpHbox/SpinBox

func _ready():
	var parent = find_parent("mainPanel")
	if parent != null && get_tree().has_group("normalMapScreen") && parent == get_tree().get_nodes_in_group("normalMapScreen")[0]:
		add_to_group("config")
	templatePanel.add_pop_menu_opt("set rot", self, "on_templatePanel_select_rot")

func _exit_tree():
	if is_in_group("config"):
		remove_from_group("config")

func load_data(cfg:ConfigFile):
	if cfg.has_section(SECTION):
		rotVbox.set_quat(cfg.get_value(SECTION, "rot", Quat(Vector3.ZERO)))
		sizeVbox.set_vector(cfg.get_value(SECTION, "size", Vector2(10, 10)))
		set_normal_type(cfg.get_value(SECTION, "normal_type", 0))
		normal.set_quat(cfg.get_value(SECTION, "normal", Quat(Vector3.ZERO)))
		embossCheckBox.pressed = cfg.get_value(SECTION, "use_emboss", true)
		embossHSlider.value = cfg.get_value(SECTION, "emboss", 0.1)
		bumpCheckBox.pressed = cfg.get_value(SECTION, "use_bump_height", true)
		bumpHeightHSlider.value = cfg.get_value(SECTION, "bump_height", 0.3)
		blurSpinBox.value = cfg.get_value(SECTION, "blur", 5)
		bumpSpinBox.value = cfg.get_value(SECTION, "bump", 60)

func save_data(cfg:ConfigFile):
	cfg.set_value(SECTION, "rot", rotVbox.get_quat())
	cfg.set_value(SECTION, "size", sizeVbox.get_vector())
	cfg.set_value(SECTION, "normal_type", normalTypeOptBtn.get_selected_id())
	cfg.set_value(SECTION, "normal", normal.get_quat())
	cfg.set_value(SECTION, "use_emboss", embossCheckBox.pressed)
	cfg.set_value(SECTION, "emboss", embossHSlider.value)
	cfg.set_value(SECTION, "use_bump_height", bumpCheckBox.pressed)
	cfg.set_value(SECTION, "bump_height", bumpHeightHSlider.value)
	cfg.set_value(SECTION, "blur", blurSpinBox.value)
	cfg.set_value(SECTION, "bump", bumpSpinBox.value)

func get_normal_type():
	return normalTypeOptBtn.get_selected_id()

func get_normal_data():
	if get_normal_type() == 0:
		return normal.get_normal()
	else:
		return [embossHSlider.value, bumpHeightHSlider.value, \
				blurSpinBox.value, bumpSpinBox.value, \
				bumpCheckBox.pressed, embossCheckBox.pressed ]

func get_pos():
	return $vbox/hbox/vbox/PosHbox/posVbox.get_vector()

func get_my_size():
	return sizeVbox.get_vector()

func get_rot():
	return rotVbox.get_quat()

func set_pos(p_pos:Vector2):
	$vbox/hbox/vbox/PosHbox/posVbox.set_vector(p_pos)

func set_my_size(p_size:Vector2):
	sizeVbox.set_vector(p_size)

func set_normal_type(p_type:int):
	match p_type:
		0:
			if not $vbox/hbox/vbox2/normalHbox.visible:
				$vbox/hbox/vbox2/normalHbox.show()
				$vbox/hbox/vbox2/embossHbox.hide()
				$vbox/hbox/vbox2/bumpHeightHbox.hide()
				$vbox/hbox/vbox2/blurHbox.hide()
				$vbox/hbox/vbox2/bumpHbox.hide()
		1:
			if $vbox/hbox/vbox2/normalHbox.visible:
				$vbox/hbox/vbox2/normalHbox.hide()
				$vbox/hbox/vbox2/embossHbox.show()
				$vbox/hbox/vbox2/bumpHeightHbox.show()
				$vbox/hbox/vbox2/blurHbox.show()
				$vbox/hbox/vbox2/bumpHbox.show()
		_:
			print("[createPolygonPop::set_normal_type] Wrong normal type!")
			return
	normalTypeOptBtn.select(p_type)

func set_single_normal(p_normal:Vector3):
	set_normal_type(0)
	normal.set_normal(p_normal)

func set_auto_normal(p_embossHeight:float, p_bumpHeight:float, p_blur:int, p_bump:int, p_useDistance:bool, p_useEmboss:bool):
	set_normal_type(1)
	embossHSlider.value = p_embossHeight
	embossCheckBox.pressed = p_useEmboss
	bumpHeightHSlider.value = p_bumpHeight
	bumpCheckBox.pressed = p_useDistance
	blurSpinBox.value = p_blur
	bumpSpinBox.value = p_bump


func _on_modifyBtn_pressed():
	editNormalPop.set_euler(normal.get_euler())
	editNormalPop.popup_centered()
	yield(editNormalPop, "popup_hide")
	yield(get_tree(), "idle_frame")
	if editNormalPop.choosed == editNormalPop.NONE:
		return
	normal.set_quat(editNormalPop.get_quat())
	if editNormalPop.choosed == editNormalPop.MODIFY_SAVE:
		templatePanel.add_template(editNormalPop.get_quat())
		#print("editNormalPop get normal", str(editNormalPop.get_normal()))



func _on_normalVbox_value_changed():
	normalIcon.set_quat(normal.get_quat())


func _on_self_about_to_show():
	templatePanel.update_template()


func _on_OptBtn_item_selected(id):
	match id:
		0:
			$vbox/hbox/vbox2/embossHbox.hide()
			$vbox/hbox/vbox2/bumpHeightHbox.hide()
			$vbox/hbox/vbox2/blurHbox.hide()
			$vbox/hbox/vbox2/bumpHbox.hide()
			$vbox/hbox/vbox2/normalHbox.show()
		1:
			$vbox/hbox/vbox2/normalHbox.hide()
			$vbox/hbox/vbox2/embossHbox.show()
			$vbox/hbox/vbox2/bumpHeightHbox.show()
			$vbox/hbox/vbox2/blurHbox.show()
			$vbox/hbox/vbox2/bumpHbox.show()


func _on_templatePanel_select_quat(quat):
	normal.set_quat(quat)

func on_templatePanel_select_rot(quat):
	rotVbox.set_quat(quat)


func _on_rotModifyBtn_pressed():
	editNormalPop.set_euler(rotVbox.get_euler())
	editNormalPop.popup_centered()
	yield(editNormalPop, "popup_hide")
	yield(get_tree(), "idle_frame")
	if editNormalPop.choosed == editNormalPop.NONE:
		return
	rotVbox.set_quat(editNormalPop.get_quat())
	if editNormalPop.choosed == editNormalPop.MODIFY_SAVE:
		templatePanel.add_template(editNormalPop.get_quat())


func _on_rotVbox_value_changed():
	rotIcon.set_quat(rotVbox.get_quat())
