tool
extends Panel

export(float) var minValue = -100000000.0 setget set_min_value
export(float) var maxValue = 100000000.0 setget set_max_value
export(float) var value = 0 setget set_value
export(float) var step = 0.001 setget set_step
export(bool) var showSlider = true setget set_show_slider

signal value_changed

#var slider
var lineEdit := preload("floatEdit.gd").new()
var grabberPos := Vector2.ZERO
var grabberTex:Texture = null
var grabberNormalTex:Texture
var grabberHoverTex:Texture
var mouseIn := false
enum { PRESS_NONE, PRESS_TEXT, PRESS_GRABBER, PRESS_SLIDER }
var press = PRESS_NONE

func _enter_tree():
	grabberPos.y = rect_size.y - 3
	update_grabber_pos()

func _ready():
	connect("mouse_entered", self, "_on_self_mouse_entered")
	connect("mouse_exited", self, "_on_self_mouse_exited")
	connect("resized", self, "_on_self_resized")
	if !lineEdit.get_parent():
		lineEdit.connect("text_entered", self, "_on_lineEdit_text_entered")
		lineEdit.connect("focus_exited", self, "_on_lineEdit_modal_closed")
		lineEdit.connect("modal_closed", self, "_on_lineEdit_modal_closed")
		lineEdit.set_as_toplevel(true)
		lineEdit.hide()
		add_child(lineEdit)

func _get_minimum_size():
	return lineEdit.get_minimum_size()

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if !event.pressed:
			if press == PRESS_NONE:
				return
			if showSlider:
				if is_on_grabber(event.position):
					press = PRESS_NONE
					return
				elif press == PRESS_SLIDER && get_slider_rect().has_point(event.position):
					set_value_by_x(event.position.x)
					press = PRESS_NONE
					return
			
			if mouseIn && press != PRESS_GRABBER:
				lineEdit.rect_position = get_global_rect().position
				lineEdit.rect_size = get_global_rect().size
				lineEdit.text = str(value)
				lineEdit.show_modal()
				lineEdit.grab_focus()
				lineEdit.select_all()
			press = PRESS_NONE
		else:
			#print("pressed")
			if is_on_grabber(event.position):
				press = PRESS_GRABBER
			elif get_slider_rect().has_point(event.position):
				press = PRESS_SLIDER
			else:
				press = PRESS_TEXT
	elif event is InputEventMouseMotion:
		if press == PRESS_GRABBER:
			set_value_by_x(event.position.x)
		if is_on_grabber(event.position):
			if grabberTex != grabberHoverTex:
				grabberTex = grabberHoverTex
				update()
		else:
			if grabberTex != grabberNormalTex:
				grabberTex = grabberNormalTex
				update()

func is_on_grabber(p_point):
	if grabberTex:
		return (p_point - grabberPos).length() <= grabberTex.get_size().x/2
	else:
		return (p_point - grabberPos).length() <= 0.5

func set_value_by_x(p_x):
	var sRect = get_slider_rect()
	p_x = clamp(p_x, sRect.position.x, sRect.position.x + sRect.size.x)
	var ratio = (p_x - sRect.position.x) / sRect.size.x
	set_value((maxValue - minValue) * ratio + minValue)

func get_slider_rect() -> Rect2:
	return Rect2(4, rect_size.y - 3, rect_size.x - 8, 1)

func _on_lineEdit_text_entered(p_text):
	_on_lineEdit_modal_closed()

func _on_lineEdit_modal_closed():
	#print("modal closed")
	lineEdit.release_focus()
	lineEdit.hide()
	set_value(lineEdit.text.to_float())

func _on_self_mouse_entered():
	mouseIn = true

func _on_self_mouse_exited():
	mouseIn = false
	grabberTex = null
	update()

func _on_self_resized():
	grabberPos.y = rect_size.y - 3
	update_grabber_pos()
	update()

func get_value() ->float:
	return value

func update_grabber_pos():
	var ratio = (value - minValue) / (maxValue - minValue)
	var sRect = get_slider_rect()
	grabberPos.x = ratio * sRect.size.x + sRect.position.x

func set_value(p_value:float):
	set_value_without_signal(p_value)
	emit_signal("value_changed")

func set_value_without_signal(p_value:float):
	var temp = clamp(p_value, minValue, maxValue)
	
	if step > 0:
		temp = round(temp / step) * step
	
	if value == temp:
		return
	
	#print("value: ", temp)
	value = temp
	update_grabber_pos()
	update()

#func _on_self_float_entered(newString):
#	_on_self_float_changed(newString.to_String())
#	print("entered")
#
#
#func _on_self_float_changed(newFloat):
#	var temp = set_value(newFloat)
#	if temp != newFloat:
#		emit_signal("limit_float_changed", temp)

func set_min_value(p_value:float):
	p_value = min(p_value, maxValue - step)
	if minValue == p_value:
		return
	
	minValue = p_value
	if value < minValue:
		value = minValue
		emit_signal("value_changed")
	update_grabber_pos()
	update()

func set_max_value(p_value:float):
	p_value = max(p_value, minValue + step)
	if maxValue == p_value:
		return
	
	maxValue = p_value
	if value > maxValue:
		value = maxValue
		emit_signal("value_changed")
	update_grabber_pos()
	update()


func set_step(p_value:float):
	if step == p_value:
		return
	
	step = p_value
	var temp = round(value / step) * step
	if temp != value:
		value = temp
		emit_signal("value_changed")
		update_grabber_pos()
		update()

func set_show_slider(p_value:bool):
	if p_value == showSlider:
		return
	
	showSlider = p_value
	update()

#func _on_slider_value_changed(value):
#	_on_self_float_changed(value)

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			update_slider_theme()

func _draw():
	var fc = get_color("font_color", "LineEdit")
	draw_string(get_font("font", "LineEdit"), Vector2(8, rect_size.y - 8), str(value), fc, rect_size.x - 16)
	if showSlider:
		draw_rect(get_slider_rect(), Color(fc.r, fc.g, fc.b, 0.2))
		if grabberTex != null:
			draw_texture(grabberTex, grabberPos - grabberTex.get_size() / 2)
		else:
			var w = 4
			if grabberPos.x + 2 > rect_size.x - 4:
				w = rect_size.x - 4 - grabberPos.x + 2
			elif grabberPos.x - 2 < 4:
				w = 4 - grabberPos.x + 2
			draw_rect(Rect2(max(grabberPos.x - 2, 4), rect_size.y - 3, w, 1), Color(fc.r, fc.g, fc.b, 0.9))

func update_slider_theme():
	#set("custom_colors/font_color_uneditable", get_color("font_color", "LineEdit"))
	if not is_inside_tree():
		return
	
	grabberNormalTex = get_icon("GuiSliderGrabber", "EditorIcons")
	grabberHoverTex = get_icon("GuiSliderGrabberHl", "EditorIcons")
	update()
#	var fc := get_color("font_color", "LineEdit")
#	var disabledIconImg = Image.new()
#	disabledIconImg.create(4, 1, false, Image.FORMAT_RGBA8)
#	disabledIconImg.fill(Color(fc.r, fc.g, fc.b, 0.9))
#	var disabledIcon = ImageTexture.new()
#	disabledIcon.create_from_image(disabledIconImg, Texture.FLAG_FILTER)
#	slider.set("custom_icons/grabber_disabled", disabledIcon)
#	slider.set("custom_icons/grabber_highlight", get_icon("GuiSliderGrabberHl", "EditorIcons"))
#	slider.set("custom_icons/grabber", get_icon("GuiSliderGrabber", "EditorIcons"))
#	var sliderBg := StyleBoxFlat.new()
#	sliderBg.bg_color = Color(fc.r, fc.g, fc.b, 0.2)
#	sliderBg.expand_margin_top = 1
#	slider.set("custom_styles/slider", sliderBg)
#	slider.margin_top = -10.0
#	slider.margin_bottom = 6.0
	






