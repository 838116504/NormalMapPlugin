tool
extends TextureRect

signal pressed
signal drag
signal released
signal right_pressed

var hasLPressed := false
var hasRPressed := false
var selected := false setget set_selected
var mouseIn := false

func set_selected(p_value):
	if selected == p_value:
		return
	selected = p_value
	if hasLPressed:
		return
	
	if selected:
		texture = get_icon("KeyBezierSelected", "EditorIcons")
	elif mouseIn:
		texture = get_icon("KeyHover", "EditorIcons")
	else:
		texture = get_icon("KeyBezier", "EditorIcons")

func _ready():
	if selected:
		texture = get_icon("KeyBezierSelected", "EditorIcons")
	else:
		texture = get_icon("KeyBezier", "EditorIcons")
	margin_left = -texture.get_size().x / 2
	margin_right = texture.get_size().x / 2
	margin_top = -texture.get_size().y / 2
	margin_bottom = texture.get_size().y / 2

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if !event.pressed:
				if !hasLPressed:
					return
				hasLPressed = false
				if selected:
					texture = get_icon("KeyBezierSelected", "EditorIcons")
				elif mouseIn:
					texture = get_icon("KeyHover", "EditorIcons")
				else:
					texture = get_icon("KeyBezier", "EditorIcons")
				emit_signal("released")
			else:
				hasLPressed = true
				texture = get_icon("KeyBezierHandle", "EditorIcons")
				emit_signal("pressed")
		elif event.button_index == BUTTON_RIGHT:
			if !event.pressed:
				if !hasRPressed:
					return false
				hasRPressed = false
				emit_signal("right_pressed")
			else:
				hasRPressed = true
		accept_event()
	elif event is InputEventMouseMotion:
		if !hasLPressed:
			return
		get_parent().rect_position += event.relative
		emit_signal("drag")
		accept_event()


func _on_btn_mouse_entered():
	mouseIn = true
	texture = get_icon("KeyHover", "EditorIcons")
	#print("Vertex handler mouse in!")


func _on_btn_mouse_exited():
	mouseIn = false
	if selected:
		texture = get_icon("KeyBezierSelected", "EditorIcons")
	else:
		texture = get_icon("KeyBezier", "EditorIcons")
	#print("Vertex handler mouse out!")
