tool
extends Polygon2D

const VertexHandler = preload("vertexHandler.tscn")

signal vertex_selected(id, dragVec)
signal vertex_drag(id)
signal vertex_deleted(id)

var showBorder:bool = false
var showHandler := false
var handlers:Array = []
var dragId:int = -1
var dragHandler := Sprite.new()
var selectBind := []

func _ready():
	dragHandler.texture = get_parent().get_icon("KeyBezier", "EditorIcons")
	dragHandler.hide()
	add_child(dragHandler)
	move_child(dragHandler, 0)
	color.a = 0.0

func add_select_bind(p_target):
	if not p_target.has_method("bind_select") || not p_target.has_method("bind_unselect") || selectBind.find(p_target) >= 0:
		return
	selectBind.push_back(p_target)
#	for i in handlers.size():
#		handlers[i].selectBind.push_back(p_target)

func get_handler(p_handlerId:int):
	return handlers[p_handlerId]

func set_points(p_points):
	if handlers.size() > p_points.size():
		for i in range(p_points.size(), handlers.size()):
			handlers[i].queue_free()
		handlers.resize(p_points.size())
	elif handlers.size() < p_points.size():
		var from = handlers.size()
		handlers.resize(p_points.size())
		for i in range(from, p_points.size()):
			handlers[i] = create_handler()
	
	for i in handlers.size():
		handlers[i].rect_position = p_points[i]
	polygon = p_points
	if showBorder:
		update()

func create_handler():
	var ret = VertexHandler.instance()
	ret.visible = showHandler
	ret.connect("pressed", self, "on_handler_pressed", [ret])
	ret.connect("drag", self, "on_handler_drag", [ret])
	ret.connect("released", self, "on_handler_released", [ret])
	ret.connect("right_pressed", self, "on_handler_right_pressed", [ret])
	ret.selectBind = selectBind
	add_child(ret)
	return ret

func on_handler_pressed(p_handler):
	var id = handlers.find(p_handler)
	if id < 0:
		print("[polygonShowNode::on_handler_pressed] Can not find the handler id!")
		return
	dragHandler.position = handlers[id].rect_position
	dragId = id
	dragHandler.show()

func on_handler_released(p_handler):
	var id = handlers.find(p_handler)
	if id < 0:
		print("[polygonShowNode::on_handler_pressed] Can not find the handler id!")
		return
	var dragVec = Vector2.ZERO
	if dragId >= 0:
		dragVec = handlers[id].rect_position - dragHandler.position
	emit_signal("vertex_selected", id, dragVec)
	dragId = -1
	dragHandler.hide()

func on_handler_drag(p_handler):
	var id = handlers.find(p_handler)
	if id < 0:
		print("[polygonShowNode::on_handler_pressed] Can not find the handler id!")
		return
	polygon[id] = handlers[id].rect_position
	if showBorder:
		update()
	emit_signal("vertex_drag", id)

func on_handler_right_pressed(p_handler):
	var id = handlers.find(p_handler)
	if id < 0:
		print("[polygonShowNode::on_handler_pressed] Can not find the handler id!")
		return
	
	emit_signal("vertex_deleted", id)

func insert_point(p_id:int, p_pos:Vector2):
	var newHandler = create_handler()
	newHandler.rect_position = p_pos
	handlers.insert(p_id, newHandler)
	polygon.insert(p_id, p_pos)

func move_point(p_id:int, p_to:Vector2):
	handlers[p_id].rect_position = p_to
	polygon[p_id] = p_to
	if showBorder:
		update()

func delete_point(p_id:int):
	var handler = handlers[p_id]
	handlers.remove(p_id)
	handler.queue_free()
	polygon.remove(p_id)

func show_border():
	showBorder = true
	update()

func hide_border():
	showBorder = false
	update()

func _draw():
	if showBorder:
		for i in polygon.size() - 1:
			draw_line(polygon[i], polygon[i + 1], Color(0.1, 0.1, 0.1, 1.0))
		draw_line(polygon[polygon.size() - 1], polygon[0], Color(0.1, 0.1, 0.1, 1.0))
		if dragId >= 0:
			if dragId > 0:
				draw_line(polygon[dragId - 1], polygon[dragId], Color(0.1, 0.1, 0.1, 1.0))
			else:
				draw_line(polygon[polygon.size() - 1], polygon[dragId], Color(0.1, 0.1, 0.1, 1.0))
			if dragId < polygon.size() - 1:
				draw_line(polygon[dragId + 1], polygon[dragId], Color(0.1, 0.1, 0.1, 1.0))
			else:
				draw_line(polygon[0], polygon[dragId], Color(0.1, 0.1, 0.1, 1.0))

func show_handlers():
	if showHandler:
		return
	showHandler = true
	for i in handlers.size():
		handlers[i].show()

func hide_handlers():
	if !showHandler:
		return
	showHandler = false
	for i in handlers.size():
		handlers[i].hide()
