tool
extends Reference

const hoverColor := Color(65.0/255.0, 65.0/255.0, 65.0/255.0)

var owner
var originalPos = null
var mouseIn := false

func enter(p_screen, exitData = null):
	owner = p_screen
	originalPos = null
	mouseIn = false
	owner.toolSelect.material = owner.selectIconMaterial
	var blue = Color(0, 0, 0.8)
	for i in owner.items.size():
		if owner.items[i].data.has_method("set_show_color"):
			owner.items[i].data.set_show_color(blue.from_hsv(i*0.04, blue.s, blue.v, 0.4))

	owner.view.connect("mouse_entered", self, "on_view_mouse_entered")
	owner.view.connect("mouse_exited", self, "on_view_mouse_exited")
	owner.unselect()

func exit():
	owner.toolSelect.material = owner.iconMaterial
	var blue = Color(0, 0, 0.8, 0.0)
	for i in owner.items.size():
		if owner.items[i].data.has_method("set_show_color"):
			owner.items[i].data.set_show_color(blue)
	if owner.view.is_connected("mouse_entered", self, "on_view_mouse_entered"):
		owner.view.disconnect("mouse_entered", self, "on_view_mouse_entered")
	if owner.view.is_connected("mouse_exited", self, "on_view_mouse_exited"):
		owner.view.disconnect("mouse_exited", self, "on_view_mouse_exited")

func on_view_mouse_entered():
	mouseIn = true

func on_view_mouse_exited():
	mouseIn = false

func input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			originalPos = owner.sourceImg.get_local_mouse_position()
		elif originalPos != null:
			var pos = owner.sourceImg.get_local_mouse_position()
			var i = owner.items.size() - 1
			while i >= 0:
				if (Geometry.is_point_in_polygon(pos, owner.items[i].data.get_points())):
					owner.to_mode(owner.modes[owner.MODE_NONE])
					owner.select(-1, i)
					break
				i -= 1
			originalPos = null



