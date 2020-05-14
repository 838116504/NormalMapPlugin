tool
extends Node

const SECTION = "template"
const FILENAME = "templates.cfg"

signal template_changed

var quats := []

func get_cfg_path():
	return .get_script().get_path().get_base_dir() + "/" + FILENAME

func _init():
	var configFile = ConfigFile.new()
	if configFile.load(get_cfg_path()) == OK:
		var count = configFile.get_value(SECTION, "count", 0)
		quats.resize(count)
		for i in count:
			quats[i] = configFile.get_value(SECTION, str(i))
#	set_path("templates")

func _ready():
	var parent = find_parent("mainPanel")
	if parent != null && get_tree().has_group("normalMapScreen") && parent == get_tree().get_nodes_in_group("normalMapScreen")[0]:
		add_to_group("templateRes")

func get_quats() -> Array:
	return quats

func add_template(p_quat:Quat):
	quats.push_back(p_quat)
	emit_signal("template_changed")

func remove_template(p_id:int):
	quats.remove(p_id)
	emit_signal("template_changed")

func save_templates():
	var configFile = ConfigFile.new()
	configFile.set_value(SECTION, "count", quats.size())
	for i in quats.size():
		configFile.set_value(SECTION, str(i), quats[i])
	configFile.save(get_cfg_path())
