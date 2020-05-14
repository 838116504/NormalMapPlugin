tool
extends TextureRect

signal pressed

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT && !event.pressed:
		emit_signal("pressed")
