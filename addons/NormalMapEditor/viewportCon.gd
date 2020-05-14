tool
extends ViewportContainer

func _gui_input(event):
	if event is InputEventMouse:
		event.position = $Viewport.get_mouse_position()
		$Viewport.input(event)
