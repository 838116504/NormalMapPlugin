tool
extends Control

signal pressed
signal removed

onready var popupMenu = $PopupMenu

var leftPress := false
var rightPress := false
var mouseIn := false
var id = -1

func set_quat(p_quat:Quat):
	$draw.set_quat(p_quat)

func get_quat() -> Quat:
	return $draw.get_quat()

func set_normal(p_n:Vector3):
	$draw.set_normal(p_n)

func get_normal() -> Vector3:
	return $draw.get_normal()

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				leftPress = true
			else:
				if leftPress:
					if mouseIn:
						emit_signal("pressed")
					leftPress = false
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				rightPress = true
			else:
				if rightPress:
					if mouseIn:
						popupMenu.popup(Rect2(get_global_mouse_position(), popupMenu.rect_size))
					rightPress = false

func _on_PopupMenu_id_pressed(id):
	if id == 0:
		emit_signal("removed")


func _on_self_mouse_entered():
	mouseIn = true
	$whiteRect.show()


func _on_self_mouse_exited():
	mouseIn = false
	$whiteRect.hide()
