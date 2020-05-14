tool
extends Control

enum { DIR_LT = 0, DIR_L, DIR_LB, DIR_T, DIR_C, DIR_B, DIR_RT, DIR_R, DIR_RB }
var dir = DIR_LT
var pressDir = -1

signal dir_changed(newDir)

func get_dir():
	return dir

func set_dir(p_dir):
	dir = p_dir
	update()

func get_dir_from_local_pos(p_pos):
	var w = (rect_size.x - 8) / 3
	var h = (rect_size.y - 8) / 3
	var x1 = 1
	var x2 = x1 + w
	var x3 = x2 + 2
	var x4 = x3 + w
	var x5 = x4 + 2
	var x6 = x5 + w
	var y1 = 1
	var y2 = y1 + h
	var y3 = y2 + 2
	var y4 = y3 + h
	var y5 = y4 + 2
	var y6 = y5 + h
	if p_pos.x < x1 || p_pos.y < y1 || p_pos.x > x6 || p_pos.y > y6:
		return -1
	if p_pos.x > x2 && p_pos.x < x3:
		return -1
	if p_pos.y > y2 && p_pos.y < y3:
		return -1
	if p_pos.x > x4 && p_pos.x < x5:
		return -1
	if p_pos.y > y4 && p_pos.y < y5:
		return -1
	
	if p_pos.x < x2:
		if p_pos.y < y2:
			return DIR_LT
		elif p_pos.y < y4:
			return DIR_L
		else:
			return DIR_LB
	elif p_pos.x < x4:
		if p_pos.y < y2:
			return DIR_T
		elif p_pos.y < y4:
			return DIR_C
		else:
			return DIR_B
	else:
		if p_pos.y < y2:
			return DIR_RT
		elif p_pos.y < y4:
			return DIR_R
		else:
			return DIR_RB

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				pressDir = get_dir_from_local_pos(event.position)
			elif pressDir >= 0:
				var dir = get_dir_from_local_pos(event.position)
				if dir == pressDir:
					emit_signal("dir_changed", dir)
				pressDir = 0

func _draw():
	var w = (rect_size.x - 8) / 3
	var h = (rect_size.y - 8) / 3
	var fc = get_color("font_color", "LineEdit")
	draw_rect(Rect2(1, 1, w, h), fc, false)
	draw_rect(Rect2(1+w+2, 1, w, h), fc, false)
	draw_rect(Rect2(1+w+2+w+2, 1, w, h), fc, false)
	draw_rect(Rect2(1, 1+h+2, w, h), fc, false)
	draw_rect(Rect2(1+w+2, 1+h+2, w, h), fc, false)
	draw_rect(Rect2(1+w+2+w+2, 1+h+2, w, h), fc, false)
	draw_rect(Rect2(1, 1+h+2+h+2, w, h), fc, false)
	draw_rect(Rect2(1+w+2, 1+h+2+h+2, w, h), fc, false)
	draw_rect(Rect2(1+w+2+w+2, 1+h+2+h+2, w, h), fc, false)
	match dir:
		DIR_LT:
			draw_rect(Rect2(1, 1, w, h), fc)
		DIR_T:
			draw_rect(Rect2(1+w+2, 1, w, h), fc)
		DIR_RT:
			draw_rect(Rect2(1+w+2+w+2, 1, w, h), fc)
		DIR_L:
			draw_rect(Rect2(1, 1+h+2, w, h), fc)
		DIR_C:
			draw_rect(Rect2(1+w+2, 1+h+2, w, h), fc)
		DIR_R:
			draw_rect(Rect2(1+w+2+w+2, 1+h+2, w, h), fc)
		DIR_LB:
			draw_rect(Rect2(1, 1+h+2+h+2, w, h), fc)
		DIR_B:
			draw_rect(Rect2(1+w+2, 1+h+2+h+2, w, h), fc)
		DIR_RB:
			draw_rect(Rect2(1+w+2+w+2, 1+h+2+h+2, w, h), fc)
