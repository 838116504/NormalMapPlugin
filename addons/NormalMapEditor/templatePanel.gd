tool
extends Panel

onready var scrollContainer = $ScrollContainer
onready var gridContainer = $ScrollContainer/GridContainer
const Template = preload("template.tscn")

#signal select_normal(normal)
signal select_quat(quat)

# 每个选項key为选項id，值为[調用对象，調用方法名, 文字 ]，調用方法会傳入該模板的四元数
var popMenuOpts = {}

func update_template():
	var templateRes = get_template_res()
	var templateCount = 0
	var quats = templateRes.get_quats()
	for i in quats.size():
		if quats[i] == null:
			continue
		templateCount += 1
	var temp
	if templateCount > gridContainer.get_child_count():
		for i in templateCount - gridContainer.get_child_count():
			temp = Template.instance()
			temp.connect("pressed", self, "_on_template_pressed", [temp])
			temp.connect("removed", self, "_on_template_removed", [temp])
			if popMenuOpts.size() > 0:
				temp.connect("custom_selected", self, "on_template_custom_selected", [temp])
				for i in popMenuOpts.keys():
					temp.add_popup_menu_option(popMenuOpts[i][2], i)
			gridContainer.add_child(temp)
	elif templateCount < gridContainer.get_child_count():
		for i in gridContainer.get_child_count() - templateCount:
			temp = gridContainer.get_child(gridContainer.get_child_count() - 1)
			gridContainer.remove_child(temp)
			temp.queue_free()
	var i = 0
	for id in quats.size():
		if quats[id] == null:
			continue
		temp = gridContainer.get_child(i)
		temp.set_quat(quats[id])
		temp.id = id
		i += 1

func get_template_res():
	if get_tree().has_group("templateRes"):
		var array = get_tree().get_nodes_in_group("templateRes")
		return array[0]
	else:
		#print("created templates resource")
		if get_tree().has_group("normalMapScreen"):
			var ret = preload("templateRes.gd").new()
			get_tree().get_nodes_in_group("normalMapScreen")[0].add_child(ret)
			return ret
		return null

func add_template(p_quat:Quat):
	var temp = Template.instance()
	temp.set_quat(p_quat)
	temp.id = gridContainer.get_child_count()
	temp.connect("pressed", self, "_on_template_pressed", [temp])
	temp.connect("removed", self, "_on_template_removed", [temp])
	if popMenuOpts.size() > 0:
		temp.connect("custom_selected", self, "on_template_custom_selected", [temp])
		for i in popMenuOpts.keys():
			temp.add_popup_menu_option(popMenuOpts[i][2], i)
	
	gridContainer.add_child(temp)
	get_template_res().add_template(p_quat)
	#print("add template normal: ", str(p_normal))

func _on_template_pressed(p_template):
	#emit_signal("select_normal", p_template.get_normal())
	emit_signal("select_quat", p_template.get_quat())

func _on_template_removed(p_template):
	gridContainer.remove_child(p_template)
	for i in range(p_template.id, gridContainer.get_child_count()):
		gridContainer.get_child(i).id -= 1
	get_template_res().remove_template(p_template.id)
	p_template.queue_free()
	

func add_pop_menu_opt(p_text:String, p_obj, p_method:String):
	var id = popMenuOpts.size() + 1
	var child
	for i in gridContainer.get_child_count():
		child = gridContainer.get_child(i)
		child.add_popup_menu_option(p_text, id)
		if !child.is_connected("custom_selected", self, "on_template_custom_selected"):
			child.connect("custom_selected", self, "on_template_custom_selected", [ child ])
	popMenuOpts[id] = [ p_obj, p_method, p_text ]

func on_template_custom_selected(id, p_template):
	if popMenuOpts.has(id):
		popMenuOpts[id][0].call(popMenuOpts[id][1], p_template.get_quat())

func _on_ScrollContainer_resized():
	if gridContainer:
		gridContainer.columns = scrollContainer.rect_size.x / (32.0 + gridContainer.get("custom_constants/hseparation"))
