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
	owner.toolMagic.material = owner.selectIconMaterial
	owner.show_scope_tool()
	owner.view.connect("mouse_entered", self, "on_view_mouse_entered")
	owner.view.connect("mouse_exited", self, "on_view_mouse_exited")
	owner.unselect()

func exit():
	owner.toolMagic.material = owner.iconMaterial
	owner.hide_scope_tool()
	
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
			var img = owner.source.get_data()
			var rect2 = Rect2(Vector2.ZERO, img.get_size())
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if not rect2.has_point(pos):
				return
			
			img.lock()
			var checked := {}
			var needCheck := [ pos ]
			var color:Color = img.get_pixelv(pos)
			var scope := int(owner.toolScopeEdit.value)
			var nextPos
			var nearPos := [ Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1) ]
			var polygons := []
			var edges := [[ Vector2(-0.5, -0.5), Vector2(-0.5, 0.5) ], [ Vector2(0.5, -0.5), Vector2(0.5, 0.5) ], [ Vector2(-0.5, -0.5), Vector2(0.5, -0.5) ], [ Vector2(-0.5, 0.5), Vector2(0.5, 0.5) ]]
			var points
			var find
			
			while needCheck.size() > 0:
				for i in nearPos.size():
					nextPos = needCheck[0] + nearPos[i]
					if rect2.has_point(nextPos) && get_color_difference(img.get_pixelv(nextPos), color) <= scope:
						if not checked.has(nextPos) && needCheck.find(nextPos) < 0:
							needCheck.push_back(nextPos)
					else:
						# 外圍頂点
						points = [ edges[i][0] + needCheck[0], edges[i][1] + needCheck[0] ]
						find = false
						for j in points.size():
							for k in polygons.size():
								if polygons[k][0] == points[j]:
									find = true
									polygons[k].push_front(points[(j + 1) & 1])
									if (polygons[k][0] - polygons[k][1]).normalized() == (polygons[k][1] - polygons[k][2]).normalized():
										polygons[k].remove(1)
									break
								elif polygons[k].back() == points[j]:
									find = true
									polygons[k].push_back(points[(j + 1) & 1])
									if (polygons[k].back() - polygons[k][polygons[k].size()-2]).normalized() == (polygons[k][polygons[k].size()-2] - polygons[k][polygons[k].size()-3]).normalized():
										polygons[k].remove(polygons[k].size()-2)
									break
							if find:
								break
						if !find:
							polygons.push_back(points)

				checked[needCheck[0]] = true
				needCheck.pop_front()
			img.unlock()
			# 
			# 合并边
			var curId = 0
			var compId
			while curId < polygons.size():
				compId = 0
				while compId < polygons.size():
					if compId == curId:
						compId += 1
						continue
					if mix_polygon(polygons[curId], polygons[compId]):
						if curId > compId:
							curId -= 1
						polygons.remove(compId)
					else:
						compId += 1
				
				curId += 1

			# 合并多边形
			var result = polygons[0]
			for i in range(1, polygons.size()):
				result = Geometry.merge_polygons_2d(result, polygons[i])[0]
			if result.size() < 3:
				return
			originalPos = null
			owner.createPolygonPop.set_points(result)
#			for i in polygons.size():
#				owner.createPolygonPop.set_points(polygons[i])
#				owner._on_createPolygonPop_CreateBtn_pressed()
			owner.createPolygonPop.popup_centered()

func get_color_difference(p_a:Color, p_b:Color) -> int:
	return int(abs(p_a.r8 - p_b.r8) + abs(p_a.g8 - p_b.g8) + abs(p_a.b8 - p_b.b8))

func mix_polygon(p_a:Array, p_b:Array) -> bool:
	var ret := false
	if p_a.front() == p_b.front():
		p_a.invert()
		ret = true
	elif p_a.back() == p_b.back():
		p_b.invert()
		ret = true
	elif p_a.front() == p_b.back():
		p_a.invert()
		p_b.invert()
		ret = true
	elif p_a.back() == p_b.front():
		ret = true
	
	if not ret:
		return false

	p_b.pop_front()
	if p_b.size() > 1 && (p_a.back() - p_b.front()).normalized() == (p_b.front() - p_b[1]).normalized():
		p_b.pop_front()
	if (p_b.front() - p_a.back()).normalized() == (p_a.back() - p_a[p_a.size() - 2]).normalized():
		p_a.pop_back()
	for i in p_b.size():
		p_a.push_back(p_b[i])

	return true

