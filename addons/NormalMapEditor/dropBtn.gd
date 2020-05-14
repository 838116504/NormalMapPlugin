tool
extends TextureRect

var press := false
var popupPanel

func _ready():
	popupPanel = get_child(0)

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			texture = get_icon("GuiDropdown", "EditorIcons")

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			press = true
		else:
			if press:
				press = false
				popupPanel.popup(Rect2(get_global_rect().position + rect_size + Vector2(-popupPanel.rect_min_size.x, 0), popupPanel.rect_min_size))


