tool
extends Control

signal pressed

var mouseIn := false
var press := false

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			press = true
		else:
			if press:
				if mouseIn:
					emit_signal("pressed")
				press = false

func _on_self_mouse_entered():
	mouseIn = true
	$whiteRect.show()


func _on_self_mouse_exited():
	mouseIn = false
	$whiteRect.hide()
