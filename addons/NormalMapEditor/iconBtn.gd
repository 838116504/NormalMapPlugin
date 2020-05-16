tool
extends TextureRect

export(String) var iconName setget set_icon_name

signal pressed

var press := false

func _init():
	material = ShaderMaterial.new()
	material.shader = preload("hoverShader.shader")
	if not is_connected("mouse_entered", self, "on_self_mouse_entered"):
		connect("mouse_entered", self, "on_self_mouse_entered")
	if not is_connected("mouse_exited", self, "on_self_mouse_exited"):
		connect("mouse_exited", self, "on_self_mouse_exited")

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				press = true
			elif press:
				press = false
				emit_signal("pressed")

func set_icon_name(p_value):
	iconName = p_value
	if is_inside_tree():
		texture = get_icon(iconName, "EditorIcons")

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			if iconName:
				texture = get_icon(iconName, "EditorIcons")

func on_self_mouse_entered():
	material.set_shader_param("isHover", true)

func on_self_mouse_exited():
	material.set_shader_param("isHover", false)
