tool
extends Label

signal pressed

var press := false

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				press = true
			elif press:
				press = false
				emit_signal("pressed")
