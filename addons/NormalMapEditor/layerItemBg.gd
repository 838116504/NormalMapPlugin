tool
extends ColorRect

signal pressed
signal right_pressed

var lPress := false
var rPress := false

var selectColor := Color(0.5, 0.5, 0.5, 1.0)
var unselectColor := Color(1.0, 1.0, 1.0, 1.0)

func _gui_input(event):
	#print("layer item bg input!")
	if event is InputEventMouseButton:
		accept_event()
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				lPress = true
			elif lPress:
				lPress = false
				if Rect2(Vector2.ZERO, rect_size).has_point(event.position):
					emit_signal("pressed")
					#print("left pressed")
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				rPress = true
			elif rPress:
				rPress = false
				if Rect2(Vector2.ZERO, rect_size).has_point(event.position):
					emit_signal("right_pressed")
					#print("right pressed")

func select():
	#color = selectColor
	self_modulate.a = 1.0
	#print("layerItemBg selected")

func unselect():
	#color = unselectColor
	self_modulate.a = 0.0

func is_selecting() -> bool:
	#return color == selectColor
	return self_modulate.a == 1.0

func _notification(what):
	match what:
		NOTIFICATION_THEME_CHANGED, NOTIFICATION_ENTER_TREE:
			var fc = get_color("font_color", "LineEdit")
			color = fc.from_hsv(fmod(fc.h + 0.5, 1.0), 0.5, 0.5)
#			var isSelecting = is_selecting()
#			selectColor = fc.from_hsv(fmod(fc.h + 0.5, 1.0), fc.s, fc.v)
#			var sBox = get_stylebox("panel", "Panel")
#			if sBox is StyleBoxFlat:
#				unselectColor = sBox.bg_color
#				print("bg color = ", str(sBox.bg_color))
#				print("border color = ", str(sBox.border_color))
#			else:
#				print("[layerItemBg::_notification] Panel stylebox is not styleBoxFlat!")
#
#			if isSelecting:
#				select()
#			else:
#				unselect()
#
#func get_drag_data(p_pos):
#	return get_parent()
