tool
extends Reference

const VertexHandler = preload("res://addons/NormalMapEditor/vertexHandler.tscn")
const lineColor := Color(35.0/255.0, 107.0/255.0, 230.0/255.0)
const hoverColor := Color(65.0/255.0, 65.0/255.0, 65.0/255.0)

var owner
var creatingVertexs = []
var drawEdgeNode = null
var originalPos = null
var originalId = -1
var hasInsertIcon := false
var mouseIn := false

func enter(p_screen, exitData = null):
	owner = p_screen
	originalPos = null
	originalId = -1
	mouseIn = false
	owner.toolPolygon.material = owner.selectIconMaterial
	if exitData != null:
		unclose_polygon(exitData[0])
		if exitData.size() > 1:
			select_vertex_by_id(exitData[1])
	owner.view.connect("mouse_entered", self, "on_view_mouse_entered")
	owner.view.connect("mouse_exited", self, "on_view_mouse_exited")
	owner.unselect()

func exit():
	owner.toolPolygon.material = owner.iconMaterial
	clear_creating()

	if is_selected_creating_vertex():
		get_selected_obj().unselect(owner)
		owner.set_select(-1, -1, owner.modes[owner.MODE_NONE])
	
	if owner.view.is_connected("mouse_entered", self, "on_view_mouse_entered"):
		owner.view.disconnect("mouse_entered", self, "on_view_mouse_entered")
	if owner.view.is_connected("mouse_exited", self, "on_view_mouse_exited"):
		owner.view.disconnect("mouse_exited", self, "on_view_mouse_exited")

func get_exit_data():
	if creatingVertexs.size() <= 0:
		return null
	var ret = [creatingVertexs.duplicate()]
	if is_selected_creating_vertex():
		ret.append(owner.selectedHandlerId)
	return ret

func is_selected_creating_vertex() -> bool:
	return owner.selectedMode == self && owner.selectedItemId < 0 && owner.selectedHandlerId >= 0

func on_view_mouse_entered():
	mouseIn = true

func on_view_mouse_exited():
	mouseIn = false
	if hasInsertIcon:
		redraw()

func clear_creating():
#	owner.selected_obj_unselect()
#	owner.selectedHandlerId = -1
#	owner.selectedItemId = -1
#	owner.selectedMode = null
	drawEdgeNode.queue_free()
	drawEdgeNode = null
	for i in creatingVertexs.size():
		creatingVertexs[i].queue_free()
	creatingVertexs.resize(0)

func create_vertex(p_pos, p_id):
	var vertex = VertexHandler.instance()
	vertex.set_pos(p_pos)
	vertex.connect("pressed", self, "on_vertex_pressed", [vertex])
	#vertex.connect("drag", self, "on_vertex_drag", [creatingVertexs.size() - 1])
	vertex.connect("released", self, "on_vertex_released", [vertex])
	vertex.connect("item_rect_changed", self, "on_vertex_item_rect_changed")
	vertex.connect("right_pressed", self, "on_right_pressed", [vertex])
	creatingVertexs.insert(p_id, vertex)
	owner.sourceImg.add_child(vertex)
	return vertex

func add_vertex(p_pos):
	var vertex = create_vertex(p_pos, creatingVertexs.size())
	
	if drawEdgeNode == null:
		create_draw_node()
	else:
		VisualServer.canvas_item_add_line(drawEdgeNode.get_canvas_item(), vertex.get_pos(), creatingVertexs[creatingVertexs.size() - 2].get_pos(), lineColor)

	#owner.view.grab_focus()
	#owner.view.grab_click_focus()



func on_vertex_item_rect_changed():
	redraw()

func insert_vertex(p_id, p_pos):
	if p_id < 0:
		p_id = creatingVertexs.size() - p_id
	if p_id < 0 || p_id > creatingVertexs.size(): 
		p_id = creatingVertexs.size()
	var vertex = create_vertex(p_pos, p_id)
	
	if drawEdgeNode == null:
		create_draw_node()

	redraw()

func remove_vertex(p_id):
	if p_id < 0:
		return
	var vertex = creatingVertexs[p_id]
	creatingVertexs.remove(p_id)
	vertex.queue_free()
	redraw()
#	owner.view.grab_focus()
#	owner.view.grab_click_focus()

func get_selected_obj():
	if owner.selectedItemId < 0:
		if owner.selectedHandlerId < 0:
			return null
		else:
			return creatingVertexs[owner.selectedHandlerId]
	else:
		return owner.items[owner.selectedItemId]


#func add_select_undo():
#	var selectedId = -1
#	selectedId = creatingVertexs.find(owner.selectedHandler)
#	if selectedId >= 0:
#		owner.undoRedo.add_undo_method(self, "select_vertex_by_id", selectedId)
#	else:
#		owner.undoRedo.add_undo_method(owner, "select_handler", owner.selectedHandler)

func input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if creatingVertexs.size() > 0 || event.control:
			if event.pressed:
#				if owner.get_selected_obj() != null:
##					owner.undoRedo.create_action("Unselect vertex")
#					owner.unselect()
##					owner.undoRedo.add_do_method(owner, "unselect")
##					owner.undoRedo.commit_action()
				return
			var linePos = get_line_pos()
			if linePos != null:
				owner.undoRedo.create_action("Insert vertex")
				owner.undoRedo.add_do_method(self, "insert_vertex", linePos[1], linePos[0])
				owner.select_do(linePos[1], -1, self)
				owner.select_undo()
				owner.undoRedo.add_undo_method(self, "remove_vertex", linePos[1])
				owner.undoRedo.commit_action()
				print("Insert vertex")
				return
				
			#add_vertex(owner.sourceImg.get_local_mouse_position())
			owner.undoRedo.create_action("Add vertex")
			owner.undoRedo.add_do_method(self, "add_vertex", owner.sourceImg.get_local_mouse_position())
			owner.select_do(creatingVertexs.size(), -1, self)
			owner.select_undo()
			owner.undoRedo.add_undo_method(self, "remove_vertex", creatingVertexs.size())
			owner.undoRedo.commit_action()
			print("Add vertex")
		else:
			if event.pressed:
				originalPos = owner.sourceImg.get_local_mouse_position()
				originalId = -1
			elif originalPos != null:
				var pos = owner.sourceImg.get_local_mouse_position()
				var radius = (originalPos - pos).length()
				if radius > 1:
					owner.createPolygonPop.set_radius(radius)
				owner.createPolygonPop.set_pos(originalPos)
				if drawEdgeNode != null:
					drawEdgeNode.queue_free()
					drawEdgeNode = null
				originalPos = null
				owner.createPolygonPop.popup_centered()
	elif event is InputEventMouseMotion:
		if creatingVertexs.size() == 0 && originalPos != null:
			if drawEdgeNode == null:
				create_draw_node()
			redraw()
		elif creatingVertexs.size() > 1:
			redraw()
	elif event is InputEventKey && event.pressed && !event.echo:
		if event.scancode == KEY_DELETE:
			owner.accept_event()
			var selectedObj = owner.get_selected_obj()
			if selectedObj != null:
				if is_selected_creating_vertex():
					owner.undoRedo.create_action("Delete Vertex")
					owner.unselect_do()
					#owner.undoRedo.add_do_method(owner, "unselect")
					owner.undoRedo.add_do_method(self, "remove_vertex", owner.selectedHandlerId)
					owner.undoRedo.add_undo_method(self, "insert_vertex", owner.selectedHandlerId, creatingVertexs[owner.selectedHandlerId].get_pos())
					#owner.undoRedo.add_undo_method(self, "select_vertex_by_id", owner.selectedHandlerId)
					owner.unselect_undo()
					owner.undoRedo.commit_action()
					print("Delete vertex")
			elif creatingVertexs.size() > 0:
				var points = []
				for i in creatingVertexs.size():
					points.push_back(creatingVertexs[i].get_pos())
				owner.undoRedo.create_action("Delete Vertexs")
				owner.unselect_do()
				owner.undoRedo.add_do_method(self, "clear_creating")
				owner.undoRedo.add_undo_method(self, "unclose_polygon", points)
				owner.unselect_undo()
				owner.undoRedo.commit_action()
				print("Delete vertexs")

func create_draw_node():
	drawEdgeNode = Control.new()
	drawEdgeNode.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawEdgeNode.focus_mode = Control.FOCUS_NONE
	drawEdgeNode.rect_size = Vector2.ZERO
	owner.sourceImg.add_child(drawEdgeNode)
	drawEdgeNode.connect("draw", self, "on_drawEdgeNode_draw")
#	drawEdgeNode.connect("focus_entered", self, "on_drawEdgeNode_focus_entered")
#	drawEdgeNode.connect("focus_exited", self, "on_drawEdgeNode_focus_exited")
#	drawEdgeNode.connect("mouse_entered", self, "on_drawEdgeNode_mouse_entered")
#	drawEdgeNode.connect("mouse_exited", self, "on_drawEdgeNode_mouse_exited")

func on_drawEdgeNode_draw():
	redraw()


func on_vertex_pressed(p_vertex):
	var id = creatingVertexs.find(p_vertex)
	if id < 0:
		print("[createPolygonMode::on_vertex_pressed] Can not find the vertex id!")
		return
	originalPos = creatingVertexs[id].get_pos()
	originalId = id


func redraw():
	if drawEdgeNode == null:
		return
	VisualServer.canvas_item_clear(drawEdgeNode.get_canvas_item())
	if creatingVertexs.size() == 0:
		if originalPos != null:
			VisualServer.canvas_item_clear(drawEdgeNode.get_canvas_item())
			VisualServer.canvas_item_add_circle(drawEdgeNode.get_canvas_item(), originalPos, (owner.sourceImg.get_local_mouse_position() - originalPos).length(), lineColor)
		return
	for i in creatingVertexs.size() - 1:
		if i == originalId || i + 1 == originalId:
			VisualServer.canvas_item_add_line(drawEdgeNode.get_canvas_item(), creatingVertexs[i].get_pos(), creatingVertexs[i + 1].get_pos(), hoverColor)
		else:
			VisualServer.canvas_item_add_line(drawEdgeNode.get_canvas_item(), creatingVertexs[i].get_pos(), creatingVertexs[i + 1].get_pos(), lineColor)

	# 拖拽中要重画原來位置的線
	if originalId >= 0:
		if originalId > 0:
			VisualServer.canvas_item_add_line(drawEdgeNode.get_canvas_item(), originalPos, creatingVertexs[originalId - 1].get_pos(), lineColor)

		if originalId < creatingVertexs.size() - 1:
			VisualServer.canvas_item_add_line(drawEdgeNode.get_canvas_item(), originalPos, creatingVertexs[originalId + 1].get_pos(), lineColor)
	
	if mouseIn:
		# 如果鼠标在線上就顯示加頂点图标
		var linePos = get_line_pos()
		if linePos != null:
			var icon = owner.get_icon("EditorHandleAdd", "EditorIcons")
			VisualServer.canvas_item_add_texture_rect(drawEdgeNode.get_canvas_item(), Rect2(linePos[0] - icon.get_size() / 2, icon.get_size()), icon)
			hasInsertIcon = true
		else:
			hasInsertIcon = false

# 如果鼠标位置不在線上就返回null，否則返回現在鼠标位置所在的線的位置和id
func get_line_pos():
	if creatingVertexs.size() < 2:
		return null
	
	var radius = owner.get_icon("EditorHandleAdd", "EditorIcons").get_size().x / 2
	var vec:Vector2
	var mousePos:Vector2 = owner.sourceImg.get_local_mouse_position()
	var newPos
	for i in creatingVertexs.size() - 1:
		vec = (creatingVertexs[i + 1].get_pos() - creatingVertexs[i].get_pos()).normalized()
		newPos = (mousePos - creatingVertexs[i].get_pos()).dot(vec)
		newPos = clamp(newPos, 0, (creatingVertexs[i + 1].get_pos() - creatingVertexs[i].get_pos()).length())
		newPos = vec * newPos
		newPos += creatingVertexs[i].get_pos()
		if (newPos - mousePos).length() <= radius:
			return [newPos, i + 1]
	return null

#func on_vertex_drag(id):
#	if creatingVertexs.size() <= 1:
#		return
#	redraw()

func select_vertex_by_id(p_id):
	if creatingVertexs.size() == 0:
		print("[createPolygonMode::select_vertex_by_id] creatingVertexs.size() == 0")
		return
	if p_id < 0:
		p_id = creatingVertexs.size() - p_id
	if p_id < 0 || p_id >= creatingVertexs.size(): 
		p_id = creatingVertexs.size() - 1
	owner.select(p_id, null, self)

func close_polygon(p_points):
	clear_creating()
	
	owner.createPolygonPop.set_points(p_points)
	owner.createPolygonPop.popup_centered()
	

func unclose_polygon(p_points):
	for i in p_points.size():
		add_vertex(p_points[i])
#	if p_selectedId >= 0:
#		select_vertex_by_id(p_selectedId)

func drag_vertex(p_id, p_pos):
	creatingVertexs[p_id].set_pos(p_pos)
	redraw()

func on_vertex_released(p_vertex):
	var id = creatingVertexs.find(p_vertex)
	if id < 0:
		print("[createPolygonMode::on_vertex_released] Can not find the vertex id!")
		return
	if originalPos == creatingVertexs[id].get_pos() && creatingVertexs.size() > 2 && id == 0:
#		print("on_vertex_released(end) id: ", str(id))
		
#		var selectedId = -1
#		if owner.selectedHandler != null:
#			selectedId = creatingVertexs.find(owner.selectedHandler)
		var points = []
		for i in creatingVertexs.size():
			points.push_back(creatingVertexs[i].get_pos())
		
		owner.undoRedo.create_action("Close Polygon")
		owner.unselect_do()
		owner.undoRedo.add_do_method(self, "close_polygon", points)
		owner.undoRedo.add_undo_method(self, "unclose_polygon", points)
		owner.unselect_undo()
		owner.undoRedo.commit_action()
		print("Close Polygon")
	elif originalId == id:
#		owner.undoRedo.create_action("Select vertex")
		
#		owner.undoRedo.add_do_method(self, "select_vertex_by_id", id)
#		owner.undoRedo.add_undo_method(self, "select_vertex_by_id", selectedId)
#		owner.undoRedo.commit_action()
		if originalPos != creatingVertexs[id].get_pos():
			#print("on_vertex_released(drag) id: ", str(id))
			owner.undoRedo.create_action("Drag vertex")
			owner.select_do(id, -1, self)
			owner.undoRedo.add_do_method(self, "drag_vertex", id, creatingVertexs[id].get_pos())
			owner.undoRedo.add_undo_method(self, "drag_vertex", id, originalPos)
			owner.select_undo()
			owner.undoRedo.commit_action()
			print("Drag vertex")
		else:
			owner.select(id, null, self)

		
	originalPos = null
	originalId = -1
#	owner.view.grab_click_focus()
#	owner.view.grab_focus()
	#print("Focus owner: ", str(owner.get_focus_owner()))
	redraw()

func on_right_pressed(p_vertex):
	var id = creatingVertexs.find(p_vertex)
	if id < 0:
		print("[createPolygonMode::on_right_pressed] Can not find the vertex id!")
		return
	var isSelecting:bool = owner.get_selected_obj() == p_vertex
	owner.undoRedo.create_action("Delete Vertex")
	if isSelecting:
		owner.unselect_do()
	#owner.undoRedo.add_do_method(owner, "unselect")
	owner.undoRedo.add_do_method(self, "remove_vertex", id)
	owner.undoRedo.add_undo_method(self, "insert_vertex", id, p_vertex.get_pos())
	#owner.undoRedo.add_undo_method(self, "select_vertex_by_id", owner.selectedHandlerId)
	if isSelecting:
		owner.unselect_undo()
	owner.undoRedo.commit_action()
	print("Delete vertex")
