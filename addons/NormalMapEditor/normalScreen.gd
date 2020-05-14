tool
extends EditorPlugin

const GROUP_NORMAL_MAP_SCREEN = "normalMapScreen"
const GROUP_NORMAL_MAP_PLUGIN = "normalMapPlugin"
const MainPanel = preload("mainPanel.tscn")
const LayerDock = preload("NormalMapDock.tscn")

var mainPanel
var layerDock
var themeName := ""

func _enter_tree():
	mainPanel = MainPanel.instance()
	mainPanel.visible = false
	mainPanel.add_to_group(GROUP_NORMAL_MAP_SCREEN)
	add_to_group(GROUP_NORMAL_MAP_PLUGIN)
	mainPanel.theme = get_editor_interface().get_base_control().theme
	get_editor_interface().get_editor_viewport().add_child(mainPanel)
	mainPanel.editorFileSystem = get_editor_interface().get_resource_filesystem()
	update_theme()

	#get_editor_interface().get_editor_settings().connect("settings_changed", self, "on_editor_settings_changed")
#	queue_save_layout()
	#make_visible(false)

func find_normal_map_dock():
	var dockTabs = get_dock_tabs()
	for i in dockTabs:
		for j in i.get_children():
			if j.get_name() == "NormalMap":
				return j
	return null

func is_dock_ready() -> bool:
	return get_editor_interface().get_base_control().get_child_count() >= 1 && \
			get_editor_interface().get_base_control().get_child(0).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(0).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(0).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0).get_child_count() >= 2 && \
			get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(1).get_child_count() >= 2

func get_dock_tabs():
	if !is_dock_ready():
		return []
	return [ get_left_UL_dock_tab(), get_left_BL_dock_tab(), get_left_UR_dock_tab(), get_left_BR_dock_tab(), \
	 get_right_UL_dock_tab(),  get_right_BL_dock_tab(),  get_right_UR_dock_tab(),  get_right_BR_dock_tab() ]

func get_left_UL_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(0).get_child(0)

func get_left_BL_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(0).get_child(1)

func get_left_UR_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(0).get_child(0)

func get_left_BR_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(0).get_child(1)

func get_right_UL_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0).get_child(0)

func get_right_BL_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0).get_child(1)

func get_right_UR_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(1).get_child(0)

func get_right_BR_dock_tab():
	return get_editor_interface().get_base_control().get_child(0).get_child(1).get_child(1).get_child(1).get_child(1).get_child(1).get_child(1)
	
func _exit_tree():
	#print("normalScreen exit tree!")
	if get_tree().has_group("templateRes"):
		var array = get_tree().get_nodes_in_group("templateRes")
		if array.size() > 0:
			array[0].save_templates()
			#print("Save templates")
			for i in array:
				i.queue_free()
	if mainPanel:
		mainPanel.save_config()
		mainPanel.remove_from_group(GROUP_NORMAL_MAP_SCREEN)
		mainPanel.queue_free()
	if layerDock:
		#if layerDock.visible:
		remove_control_from_docks(layerDock)
		layerDock.queue_free()
	remove_from_group(GROUP_NORMAL_MAP_PLUGIN)


func has_main_screen():
	return true

func make_visible(visible):
	if mainPanel:
		mainPanel.visible = visible
		
#	if layerDock && visible != layerDock.visible:
#		layerDock.visible = visible
#		if visible:
#			add_control_to_dock(DOCK_SLOT_LEFT_UR, layerDock)
#		else:
#			remove_control_from_docks(layerDock)

func get_plugin_name():
	return "Normal"

func get_plugin_icon():
	#print(str(get_editor_interface().get_base_control().theme.get_icon_list("EditorIcons")))
	update_plugin_icon()
	return get_editor_interface().get_base_control().get_icon("NormalMapPlugin", "EditorIcons")
	

func update_plugin_icon():
	if not get_editor_interface().get_base_control().theme.has_icon("NormalMapPlugin", "EditorIcons"):
		get_editor_interface().get_base_control().theme.set_icon("NormalMapPlugin", "EditorIcons", ImageTexture.new())
	
	var img = preload("iconNormalMap.svg").get_data()
	img.convert(Image.FORMAT_RGBA8)
	var data = img.get_data()
	var fc = get_editor_interface().get_base_control().get_color("font_color", "LineEdit")
	var fcA = [fc.r, fc.g, fc.b, fc.a]
	for i in range(0, data.size(), 4):
		if data[i + 3] == 0:
			continue
		for j in 4:
			data[i + j] = fcA[j] * data[i + j]
	img.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, data)
	var tex = get_editor_interface().get_base_control().get_icon("NormalMapPlugin", "EditorIcons")
	tex.create_from_image(img)
	#print("tex: ", str(tex))
	

func _notification(what):
	match what:
		Control.NOTIFICATION_THEME_CHANGED:
			update_plugin_icon()
			update_theme()

#func on_editor_settings_changed():
#	update_theme()


func get_window_layout(layout:ConfigFile):
#	var sections = layout.get_sections()
#	var find = false
#	for i in sections:
#		#print("[%s]" % i)
#		if i != "docks":
#			continue
#		for j in layout.get_section_keys(i):
#			var docks = layout.get_value(i, j, "").split(",", false)
#			for k in docks:
#				if k == "NormalMap":
#					find = true
#					break
#			if find:
#				break
#			#print("\t%s: %s" % [j, layout.get_value(i, j, "")])
#		break
	#layout.set_value(get_plugin_name(), "test", 1)
	
#	yield(get_tree().create_timer(4.0), "timeout")
#	yield(get_tree(), "idle_frame")
	
	#print("get window layout")
	pass

func set_window_layout(layout):
	#print("set_window_layout: ", str(layout.get_sections()))
	if layerDock == null:
		create_layer_dock()
	if mainPanel:
		mainPanel.load_config()
	else:
		print("[normalScreen::set_window_layout] mainPanel is null when load!")
	#print("set window layout")

func enable_plugin():
	layerDock = find_normal_map_dock()
	if !layerDock:
		create_layer_dock()
	if mainPanel:
		mainPanel.load_config()
	else:
		print("[normalScreen::enable_plugin] mainPanel is null when load!")
	#print("enable plugin")

func disable_plugin():
	queue_save_layout()
	
	#print("disable plugin")
	

func save_external_data():
	if mainPanel:
		mainPanel.save_project()

func create_layer_dock():
	layerDock = LayerDock.instance()
	mainPanel.layerDock = layerDock
	layerDock.theme = mainPanel.theme
	layerDock.mainPanel = mainPanel
	#layerDock.visible = false
	add_control_to_dock(DOCK_SLOT_LEFT_BR, layerDock)

func update_theme():
	if themeName == get_editor_interface().get_editor_settings().get_setting("interface/theme/preset"):
		return
	themeName = get_editor_interface().get_editor_settings().get_setting("interface/theme/preset")
	match themeName:
		_:
			set_icon_color(get_editor_interface().get_base_control().get_color("font_color", "LineEdit"), Color(35.0/255.0, 107.0/255.0, 230.0/255.0))

func set_icon_color(forward:Color, select:Color):
	mainPanel.iconMaterial.set_shader_param("forward", forward)
	mainPanel.selectIconMaterial.set_shader_param("select", select)
