tool
extends Control

var mainPanel

onready var vbox = $bg/scrollCon/vbox
onready var scrollCon = $bg/scrollCon
onready var sizeLabel = $sizeHbox/Panel/sizeLabel

func _on_Label2_set_texture(texPath):
	var tex = load(texPath)
	sizeLabel.text = "%s x %s" % [ tex.get_size().x, tex.get_size().y ]
	if mainPanel:
		mainPanel.on_set_project(texPath)

func add_item(data):
	data.get_node("nameBg").set_drag_forwarding(self)
	vbox.add_child(data)
	vbox.move_child(data, 0)

func can_drop_data(position, data):
	if not data is Node || not is_a_parent_of(data):
		return false

	var vboxLocalPos = vbox.get_global_rect().position - get_global_rect().position
	var y = position.y - vboxLocalPos.y + scrollCon.scroll_vertical
	if position.y < vboxLocalPos.y:
		scrollCon.scroll_vertical += position.y - vboxLocalPos.y
	elif position.y > vboxLocalPos.y + vbox.rect_size.y:
		scrollCon.scroll_vertical += position.y - (vboxLocalPos.y + vbox.rect_size.y)
	
	return true

func drop_data(position, data):
	var vboxLocalPos = vbox.get_global_rect().position - get_global_rect().position
	var y = position.y - vboxLocalPos.y + scrollCon.scroll_vertical
	var newId = get_child_count() - 1
	if y <= 0:
		newId = 0
	else:
		for i in get_child_count():
			if y < get_child(i).rect_position.y + get_child(i).rect_size.y:
				newId = i
				break
	if newId == data.get_index():
		return
	newId = vbox.get_child_count() - newId
	mainPanel.on_drag_list_node(data, newId)

func can_drop_data_fw(position, data, from):
	if not data is Node || not is_a_parent_of(data):
		return false
	return true

func drop_data_fw(position, data, from):
	drop_data(from.get_global_rect().position + position - get_global_rect().position, data)
#	var vboxLocalPos = vbox.get_global_rect().position - from.get_global_rect().position
#	var y = position.y - vboxLocalPos.y + scrollCon.scroll_vertical
#
#	var newId = get_child_count() - 1
#	if y <= 0:
#		newId = 0
#	else:
#		for i in get_child_count():
#			if y < get_child(i).rect_position.y:
#				newId = i
#				break
#	if newId == data.get_index():
#		return
#	newId = vbox.get_child_count() - newId
#	mainPanel.on_drag_list_node(data, newId)

func get_drag_data_fw(position, from):
	print("get_drag_data_fw")
	var preview = preload("dragPreview.tscn").instance()
	preview.get_node("Label").text = from.get_node("nameLabel").text
	set_drag_preview(preview)
	return from.get_parent()

func _on_exportBtn_pressed():
	mainPanel.export_normal_map()
