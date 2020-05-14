tool
extends Control

signal pressed
signal drag
signal released
signal right_pressed

var selectBind := []

func select(p_mainPanel):
	$btn.selected = true
	p_mainPanel.show_pos_tool()
	for i in selectBind.size():
		selectBind[i].bind_select(p_mainPanel)

func unselect(p_mainPanel):
	$btn.selected = false
	p_mainPanel.hide_pos_tool()
	for i in selectBind.size():
		selectBind[i].bind_unselect(p_mainPanel)

func get_x():
	return rect_position.x

func get_y():
	return rect_position.y

func set_x(p_x):
	rect_position.x = p_x

func set_y(p_y):
	rect_position.y = p_y
	
func get_pos():
	return rect_position

func set_pos(p_pos):
	rect_position = p_pos

func _on_btn_pressed():
	emit_signal("pressed")

func _on_btn_drag():
	emit_signal("drag")

func _on_btn_released():
	emit_signal("released")


func _on_btn_right_pressed():
	emit_signal("right_pressed")
