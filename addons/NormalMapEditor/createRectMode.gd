tool
extends Reference

const hoverColor := Color(65.0/255.0, 65.0/255.0, 65.0/255.0)

var owner
var drawEdgeNode = null
var originalPos = null
var mouseIn := false

func enter(p_screen, exitData = null):
	owner = p_screen
	originalPos = null
	mouseIn = false
	owner.toolRect.material = owner.selectIconMaterial
	owner.view.connect("mouse_entered", self, "on_view_mouse_entered")
	owner.view.connect("mouse_exited", self, "on_view_mouse_exited")
	owner.unselect()

func exit():
	owner.toolRect.material = owner.iconMaterial
	
	if drawEdgeNode != null:
		drawEdgeNode.queue_free()
		drawEdgeNode = null
	
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
			var size = pos - originalPos
			if abs(size.x) > 1 && abs(size.y) > 1:
				owner.createRectPop.set_my_size(size)
			owner.createRectPop.set_pos(originalPos)
			if drawEdgeNode != null:
				drawEdgeNode.queue_free()
				drawEdgeNode = null
			originalPos = null
			owner.createRectPop.popup_centered()
	elif event is InputEventMouseMotion:
		if originalPos != null:
			if drawEdgeNode == null:
				create_draw_node()
			redraw()

func create_draw_node():
	drawEdgeNode = Control.new()
	drawEdgeNode.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawEdgeNode.focus_mode = Control.FOCUS_NONE
	drawEdgeNode.rect_size = Vector2.ZERO
	owner.sourceImg.add_child(drawEdgeNode)
	drawEdgeNode.connect("draw", self, "on_drawEdgeNode_draw")

func on_drawEdgeNode_draw():
	redraw()

func redraw():
	if drawEdgeNode == null:
		return
	VisualServer.canvas_item_clear(drawEdgeNode.get_canvas_item())
	
	if originalPos != null:
		var nextPos = owner.sourceImg.get_local_mouse_position()
		var points = [ originalPos, Vector2(nextPos.x, originalPos.y), nextPos, Vector2(originalPos.x, nextPos.y) ]
		VisualServer.canvas_item_add_polyline(drawEdgeNode.get_canvas_item(), points, [hoverColor])

