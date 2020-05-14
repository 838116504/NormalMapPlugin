tool
extends TextureRect

export(Texture) var normal_texture
export(Texture) var drag_texture
export(Texture) var selected_texture
export(Texture) var hover_texture
export(Texture) var disabled_texture
export(NodePath) var mainPanel

signal pressed
signal drag
signal released

var hasPressed := false
var disabled := false
var selected := false setget set_selected
var mouseIn := false

func select(p_mainPanel):
	set_selected(true)
	p_mainPanel.show_pos_tool()
	p_mainPanel.show_z_tool()
	p_mainPanel.show_size_tool()
	p_mainPanel.show_enable_tool()

func unselect(p_mainPanel):
	set_selected(false)
	p_mainPanel.hide_pos_tool()
	p_mainPanel.hide_z_tool()
	p_mainPanel.hide_size_tool()
	p_mainPanel.hide_enable_tool()

func is_disabled():
	return disabled

func set_disabled(p_value):
	if disabled == p_value:
		return
	
	disabled = p_value
	$Light2D.enabled = !disabled

func get_width():
	return $Light2D.scale.x * $Light2D.texture.get_size().x

func get_height():
	return $Light2D.scale.y * $Light2D.texture.get_size().y

func set_width(p_width):
	$Light2D.scale.x = p_width / $Light2D.texture.get_size().x

func set_height(p_height):
	$Light2D.scale.y = p_height / $Light2D.texture.get_size().y


func get_my_size():
	return Vector2(get_width(), get_height())

func set_my_size(p_size):
	set_width(p_size.x)
	set_height(p_size.y)

func get_z():
	return $Light2D.range_height

func set_z(p_z):
	$Light2D.range_height = p_z

func get_x() -> float:
	return rect_position.x

func get_y() -> float:
	return rect_position.y

func set_x(p_x:float):
	rect_position.x = p_x

func set_y(p_y:float):
	rect_position.y = p_y

func update_texture():
	if hasPressed:
		texture = drag_texture
	elif selected:
		texture = selected_texture
	elif mouseIn:
		texture = hover_texture
	elif disabled:
		texture = disabled_texture
	else:
		texture = normal_texture
	$Light2D.position = texture.get_size() / 2

func set_selected(p_value):
	if selected == p_value:
		return
	selected = p_value
	if hasPressed:
		return
	
	update_texture()

func _ready():
	if selected:
		texture = selected_texture
	else:
		texture = normal_texture
	$Light2D.position = texture.get_size() / 2

func _gui_input(event):
	if event is InputEventMouseButton:
		if !event.pressed:
			if !hasPressed:
				return
			hasPressed = false
			update_texture()
			emit_signal("released")
		else:
			if (event.position - rect_size / 2).length() > 13:
				return 
			hasPressed = true
			update_texture()
			emit_signal("pressed")
		accept_event()
	elif event is InputEventMouseMotion:
		if !hasPressed:
			return
		rect_position += event.relative
		emit_signal("drag")
		accept_event()


func _on_btn_mouse_entered():
	mouseIn = true
	update_texture()
	#print("Vertex handler mouse in!")


func _on_btn_mouse_exited():
	mouseIn = false
	update_texture()
	#print("Vertex handler mouse out!")
