tool
extends Panel

signal input(event)

func _gui_input(event):
	#grab_focus()
	#grab_click_focus()
	#print("focus owner: ", str(get_focus_owner()))
	emit_signal("input", event)

#func _on_img_gui_input(event):
#	_gui_input(event)
#
#
#func _on_bg_gui_input(event):
#	_gui_input(event)
#
#
#func _on_centerCon_gui_input(event):
#	_gui_input(event)


#func _on_Panel_focus_entered():
#	print("View getted focus!")
#
#func _on_Panel_focus_exited():
#	print("View lost focus!")
#
func _on_Panel_mouse_entered():
	grab_focus()
#	print("View mouse in!")
#
#func _on_Panel_mouse_exited():
#	print("View mouse out!")
#
#func _on_img_mouse_entered():
#	print("Img mouse out!")
#
#func _on_img_mouse_exited():
#	print("Img mouse out!")


func _on_centerCon_resized():
	$centerCon.rect_pivot_offset = $centerCon.rect_size / 2
