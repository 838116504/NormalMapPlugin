tool
extends Control

const PolygonRenderNode = preload("polygonRenderNode.gd")
const PolygonShowNode = preload("polygonShowNode.gd")
const LayerItem = preload("layerItem.tscn")
const singleNormalShader = preload("singleNormalShader.shader")
const CreatePolygonMode = preload("createPolygonMode.gd")

# 可視眼︰ GuiVisibilityVisible
# 隱藏眼︰ GuiVisibilityHidden
# 頂点︰ KeyBezier
# 拖拽頂点︰ KeyBezierHandle
# hover頂点︰ KeyHover
# 选擇頂点︰ KeySelected
# 選擇工具︰ ToolSelect
# 透明图︰ Checkerboard、 GuiMiniCheckerboard
# 圓形拖拽︰ GuiSliderGrabber
# hover圓形拖拽︰ GuiSliderGrabberHl
# 加頂点︰ EditorHandleAdd
# 下拉按鈕︰ GuiDropdown， GuiOptionArrow


const CONFIG_FILENAME = "config.cfg"

enum { MODE_NONE = 0, MODE_CREATE_POLYGON }

var modes
var mode
var selectedMode = null
var selectedItemId:int = -1
var selectedHandlerId:int = -1
var sourcePath:String
var source:Texture
var items:Array
var handlers:Array
var lightId:int
var iconMaterial:ShaderMaterial
var selectIconMaterial:ShaderMaterial
var version := 0
var showNormal := false
var undoRedo := UndoRedo.new()

onready var renderNodeParent = $resultView
onready var showNodeParent = $vbox/Panel/centerCon/bg/img
onready var view = $vbox/Panel
onready var resultView = $resultView
onready var sourceBg = $vbox/Panel/centerCon/bg
onready var sourceImg = $vbox/Panel/centerCon/bg/img
onready var askSavePop = $askSavePop
onready var createPolygonPop = $createPolygonPop
onready var editNormalPop = $editNormalPop
onready var toolSelect = $vbox/hbox/select
onready var toolRect = $vbox/hbox/rect
onready var toolPolygon = $vbox/hbox/polygon
onready var toolMagic = $vbox/hbox/magic
onready var toolShowToggle = $vbox/hbox/showToggle
onready var toolXLabel = $vbox/hbox/xLabel
onready var toolXEdit = $vbox/hbox/xEdit
onready var toolYLabel = $vbox/hbox/yLabel
onready var toolYEdit = $vbox/hbox/yEdit
onready var toolPosDir = $vbox/hbox/posDir
onready var toolEnable = $vbox/hbox/enableCheck
onready var toolWLabel = $vbox/hbox/wLabel
onready var toolWEdit = $vbox/hbox/wEdit
onready var toolHLabel = $vbox/hbox/hLabel
onready var toolHEdit = $vbox/hbox/hEdit
onready var toolZLabel = $vbox/hbox/zLabel
onready var toolZEdit = $vbox/hbox/zEdit
onready var light = $vbox/Panel/centerCon/bg/img/light
onready var toolRotationDraw = $vbox/hbox/rotationHbox/rotationDraw
onready var toolRotation = $vbox/hbox/rotationHbox
onready var rotPopupPanel = $vbox/hbox/rotationHbox/templateOptBtn/rotPopupPanel
onready var toolNormalDraw = $vbox/hbox/normalHbox/normalDraw
onready var toolNormalTypeOptBtn = $vbox/hbox/normalTypeOptBtn
onready var toolNormal = $vbox/hbox/normalHbox
onready var templatePopupPanel = $vbox/hbox/normalHbox/templateOptBtn/PopupPanel
onready var toolEmbossCheckBox = $vbox/hbox/embossCheckBox
onready var toolEmbossEdit = $vbox/hbox/embossEdit
onready var toolBumpCheckBox = $vbox/hbox/bumpCheckBox
onready var toolBumpHeightEdit = $vbox/hbox/bumpHeightEdit
onready var toolBlurLabel = $vbox/hbox/blurLabel
onready var toolBlurEdit = $vbox/hbox/blurEdit
onready var toolBumpLabel = $vbox/hbox/bumpLabel
onready var toolBumpEdit = $vbox/hbox/bumpEdit
var layerDock
var editorFileSystem:EditorFileSystem

enum { DIR_LT = 0, DIR_L, DIR_LB, DIR_T, DIR_C, DIR_B, DIR_RT, DIR_R, DIR_RB }
enum { ITEM_TYPE_RECT, ITEM_TYPE_POLYGON }

class dummy:
	func _init():
		pass

class Item:
	var type
	var data
	
	func save_data(configFile:ConfigFile, section:String):
		configFile.set_value(section, "type", type)
		data.save_data(configFile, section)

	func load_data(configFile:ConfigFile, section:String, sourceTex):
		type = configFile.get_value(section, "type")
		match type:
			ITEM_TYPE_RECT:
				data = RectItem.new()
				data.load_data(configFile, section)
			ITEM_TYPE_POLYGON:
				data = PolygonItem.new(sourceTex)
				data.load_data(configFile, section)

class RectItem:
	var size:Vector2
	var rot := Quat(Vector3.ZERO)
	var normal := Vector3(0, 0, 1)
	var renderNode
	var showNode
	var listNode
	var mainPanel
	
	func _init():
		renderNode = Polygon2D.new()
		renderNode.material.shader = singleNormalShader
		renderNode.material.set_shader_param("normal", normal)
		showNode = PolygonShowNode.instance()
		showNode.color = Color(0.0, 0.0, 0.8, 0.4)
		listNode = LayerItem.instance()
		listNode.item = self
		if listNode.is_inside_tree():
			listNode.set_icon(listNode.get_icon("CollisionShape2D", "EditorIcons"))
		else:
			listNode.iconName = "CollisionShape2D"
		listNode.set_item_name("item")
		
	func set_name(p_name):
		listNode.set_item_name(p_name)
	
	func get_name():
		return listNode.get_item_name()
		
	func set_visible(p_visible):
		renderNode.visible = p_visible
		#showNode.visible = p_visible
		listNode.set_item_visible(p_visible)
	
	func get_visible():
		return renderNode.visible

#	func get_handler(p_handlerId):
#		return showNode.get_handler(p_handlerId)
	func is_own(p_node) -> bool:
		if p_node == showNode || p_node == listNode || p_node == renderNode:
			return true
		return false
		
	func set_dir_pos(p_dir, p_pos):
		var rect2 = Rect2(renderNode.polygon[0])
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
	
		match p_dir:
			DIR_LT:
				set_pos(p_pos - rect2.position)
			DIR_L:
				set_pos(p_pos - Vector2(rect2.position.x, (rect2.position.y + rect2.end.y) / 2))
			DIR_LB:
				set_pos(p_pos - Vector2(rect2.position.x, rect2.end.y))
			DIR_T:
				set_pos(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, rect2.position.y))
			DIR_C:
				set_pos(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, (rect2.position.y + rect2.end.y) / 2))
			DIR_B:
				set_pos(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, rect2.end.y))
			DIR_RT:
				set_pos(p_pos - Vector2(rect2.end.x, rect2.position.y))
			DIR_R:
				set_pos(p_pos - Vector2(rect2.end.x, (rect2.position.y + rect2.end.y) / 2))
			DIR_RB:
				set_pos(p_pos - rect2.end)
	
	func get_dir_pos(p_dir):
		var rect2 = Rect2(renderNode.polygon[0])
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
		
		match p_dir:
			DIR_LT:
				return get_pos() + rect2.position
			DIR_L:
				return get_pos() + Vector2(rect2.position.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_LB:
				return get_pos() + Vector2(rect2.position.x, rect2.end.y)
			DIR_T:
				return get_pos() + Vector2((rect2.position.x + rect2.end.x) / 2, rect2.position.y)
			DIR_C:
				return get_pos() + Vector2((rect2.position.x + rect2.end.x) / 2, (rect2.position.y + rect2.end.y) / 2)
			DIR_B:
				return get_pos() + Vector2((rect2.position.x + rect2.end.x) / 2, rect2.end.y)
			DIR_RT:
				return get_pos() + Vector2(rect2.end.x, rect2.position.y)
			DIR_R:
				return get_pos() + Vector2(rect2.end.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_RB:
				return get_pos() + rect2.end
	
	func set_item_id(p_newId):
		if renderNode.get_parent():
			renderNode.get_parent().move_child(renderNode, p_newId)
		if showNode.get_parent():
			showNode.get_parent().move_child(showNode, p_newId)
		if listNode.get_parent():
			listNode.get_parent().move_child(listNode, listNode.get_parent().get_child_count() - p_newId)
	
	func select(p_mainPanel):
		showNode.show_border()
		showNode.color.a = 0.4
		#showNode.show_handlers()
		p_mainPanel.show_pos_tool()
		p_mainPanel.show_size_tool()
		p_mainPanel.show_rotation_tool()
		p_mainPanel.show_normal_tool()
		listNode.select()
	
	func unselect(p_mainPanel):
		showNode.hide_border()
		showNode.color.a = 0.0
		#showNode.hide_handlers()
		p_mainPanel.hide_pos_tool()
		p_mainPanel.hide_size_tool()
		p_mainPanel.hide_rotation_tool()
		p_mainPanel.hide_normal_tool()
		listNode.unselect()
	
	func destroy():
		if showNode:
			showNode.queue_free()
			showNode = null
		if renderNode:
			renderNode.queue_free()
			renderNode = null
		if listNode:
			listNode.queue_free()
			listNode = null
	
	func set_rot_size(p_rot:Quat, p_size:Vector2):
		rot = p_rot
		size = p_size
#		var quat:Quat
#		if p_normal == Vector3(0, 0, 1):
#			quat = Quat(Vector3.ZERO)
#		var cross = p_normal.cross(Vector3(0, 0, 1)).normalized()
#		var cross2 = Vector3(0, 0, 1).cross(cross).normalized()
#		if p_normal.dot(cross2) >= 0:
#			quat = Quat(cross, -p_normal.angle_to(Vector3(0, 0, 1)))
#		else:
#			quat = Quat(cross, p_normal.angle_to(Vector3(0, 0, 1)))
		var points = []
		points.resize(4)
		points[0] = Vector2.ZERO
		var temp = rot.xform(Vector3(size.x, 0, 0))
		points[1] = Vector2(temp.x, temp.y)
		temp = rot.xform(Vector3(size.x, size.y, 0))
		points[2] = Vector2(temp.x, temp.y)
		temp = rot.xform(Vector3(0, size.y, 0))
		points[3] = Vector2(temp.x, temp.y)
		
		renderNode.polygon = points
		showNode.set_points(points)
	
	func set_rot(p_rad:Quat):
		set_rot_size(p_rad, get_size())

	func set_size(p_size:Vector2):
		set_rot_size(get_rot(), p_size)
	
	func get_rot() -> Quat:
		return rot
	
	func set_normal(p_normal:Vector3):
		normal = p_normal
		renderNode.material.set_shader_param("normal", normal)
	
	func get_normal() -> Vector3:
		return normal
	
	func set_single_normal(p_vec:Vector3):
		set_normal(p_vec)
	
	func get_single_normal() -> Vector3:
		return get_normal()
	
	func get_size():
		return size
		
	func get_width():
		return size.x
	
	func get_height():
		return size.y
	
	func get_my_size():
		return size
	
	func set_width(p_width):
		set_size(Vector2(p_width, size.y))
	
	func set_height(p_height):
		set_size(Vector2(size.x, p_height))
	
	func set_my_size(p_size):
		set_size(p_size)
	
	func set_pos(p_pos):
		renderNode.position = p_pos
		showNode.position = p_pos
	
	func get_pos():
		return showNode.position
		
	func save_data(configFile:ConfigFile, section:String):
		configFile.set_value(section, "name", get_name())
		configFile.set_value(section, "pos", get_pos())
		configFile.set_value(section, "size", get_size())
		configFile.set_value(section, "rot", get_rot())
		configFile.set_value(section, "normal", get_normal())
		configFile.set_value(section, "visible", get_visible())
	
	func load_data(configFile:ConfigFile, section:String):
		set_name(configFile.get_value(section, "name", "item"))
		set_pos(configFile.get_value(section, "pos", Vector2.ZERO))
		set_rot_size(configFile.get_value(section, "rot", Quat(Vector3.ZERO)), configFile.get_value(section, "size", Vector2(10, 10)))
		set_normal(configFile.get_value(section, "normal", Vector3(0, 0, 1)))
		set_visible(configFile.get_value(section, "visible", true))


enum { USE_EMBOSS = 0, EMBOSS_HEIGHT, USE_BUMP, BUMP_HEIGHT, BUMP, BLUR }
# 向量类型
enum { NT_SINGLE = 0, NT_AUTO }

class PolygonItem:
	var renderNode
	var showNode
	var listNode
	var mainPanel
	
	func _init(p_sourceTex):
		renderNode = PolygonRenderNode.new()
		renderNode.sourceTex = p_sourceTex
		showNode = PolygonShowNode.new()
		showNode.color = Color(0.0, 0.0, 0.8, 0.4)
		showNode.add_select_bind(self)
		listNode = LayerItem.instance()
		listNode.item = self
		if listNode.is_inside_tree():
			listNode.set_icon(listNode.get_icon("CollisionPolygon2D", "EditorIcons"))
		else:
			listNode.iconName = "CollisionPolygon2D"
		listNode.set_item_name("item")
	
	func set_item_id(p_newId):
		if renderNode.get_parent():
			renderNode.get_parent().move_child(renderNode, p_newId)
		if showNode.get_parent():
			showNode.get_parent().move_child(showNode, p_newId)
		if listNode.get_parent():
			listNode.get_parent().move_child(listNode, listNode.get_parent().get_child_count() - p_newId)
	
	func select(p_mainPanel):
		showNode.show_border()
		showNode.show_handlers()
		showNode.color.a = 0.4
		p_mainPanel.show_pos_dir_tool()
		p_mainPanel.show_size_tool()
		p_mainPanel.show_normal_type_tool()
		listNode.select()
	
	func unselect(p_mainPanel):
		showNode.hide_border()
		showNode.hide_handlers()
		showNode.color.a = 0.0
		p_mainPanel.hide_pos_dir_tool()
		p_mainPanel.hide_size_tool()
		p_mainPanel.hide_normal_type_tool()
		listNode.unselect()
	
	
	func bind_select(p_mainPanel):
		showNode.show_border()
		showNode.show_handlers()
		showNode.color.a = 0.4
		listNode.select()
	
	func bind_unselect(p_mainPanel):
		showNode.hide_border()
		showNode.hide_handlers()
		showNode.color.a = 0.0
		listNode.unselect()
	
	func destroy():
		if showNode:
			showNode.queue_free()
			showNode = null
		if renderNode:
			renderNode.queue_free()
			renderNode = null
		if listNode:
			listNode.queue_free()
			listNode = null
	
	func set_single_normal(p_vec:Vector3):
		renderNode.set_normal_data(renderNode.NT_SINGLE, p_vec)
	
	func get_single_normal() -> Vector3:
		return get_normal_data()
	
	func set_auto_normal(emboss_height:float, bump_height:float, blur:int, bump:int, with_distance:bool, with_emboss:bool):
		renderNode.set_normal_data(renderNode.NT_AUTO, [emboss_height, bump_height, blur, bump, with_distance, with_emboss])
	
	func get_normal_type():
		return renderNode.type
	
	func get_normal_data():
		return renderNode.data
	
	func get_emboss() -> float:
		return renderNode.data[0]
	
	func set_emboss(p_emboss:float):
		set_auto_normal(p_emboss, renderNode.data[1], renderNode.data[2], renderNode.data[3], renderNode.data[4], renderNode.data[5])

	func get_bump_height() -> float:
		return renderNode.data[1]
	
	func set_bump_height(p_bumpHeight:float):
		set_auto_normal(renderNode.data[0], p_bumpHeight, renderNode.data[2], renderNode.data[3], renderNode.data[4], renderNode.data[5])
	
	func get_blur() -> float:
		return renderNode.data[2]
	
	func set_blur(p_blur:float):
		set_auto_normal(renderNode.data[0], renderNode.data[1], p_blur, renderNode.data[3], renderNode.data[4], renderNode.data[5])
	
	func get_bump() -> float:
		return renderNode.data[3]
	
	func set_bump(p_bump:float):
		set_auto_normal(renderNode.data[0], renderNode.data[1], renderNode.data[2], p_bump, renderNode.data[4], renderNode.data[5])
	
	func is_bump_enabled() -> bool:
		return renderNode.data[4]
	
	func set_bump_enabled(p_enabled:bool):
		set_auto_normal(renderNode.data[0], renderNode.data[1], renderNode.data[2], renderNode.data[3], p_enabled, renderNode.data[5])
	
	func is_emboss_enabled() -> bool:
		return renderNode.data[5]
	
	func set_emboss_enabled(p_enabled:bool):
		set_auto_normal(renderNode.data[0], renderNode.data[1], renderNode.data[2], renderNode.data[3], renderNode.data[4], p_enabled)
	
	func on_move_point(p_pointId:int, p_to:Vector2):
		showNode.move_point(p_pointId, p_to)
		renderNode.move_point(p_pointId, p_to)
	
	
	func on_delete_point(p_pointId:int):
		renderNode.delete_point(p_pointId)
		showNode.delete_point(p_pointId)
	
	func on_insert_point(p_pointId:int, p_pos:Vector2):
		showNode.insert_point(p_pointId, p_pos)
		renderNode.insert_point(p_pointId, p_pos)
	
	func move(p_offset):
		var points = get_points()
		for i in points.size():
			points[i] += p_offset
		set_points(points)
	
	func set_dir_pos(p_dir, p_pos):
		var rect2 = Rect2(renderNode.polygon[0], Vector2.ZERO)
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
		
		match p_dir:
			DIR_LT:
				move(p_pos - rect2.position)
			DIR_L:
				move(p_pos - Vector2(rect2.position.x, (rect2.position.y + rect2.end.y) / 2))
			DIR_LB:
				move(p_pos - Vector2(rect2.position.x, rect2.end.y))
			DIR_T:
				move(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, rect2.position.y))
			DIR_C:
				move(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, (rect2.position.y + rect2.end.y) / 2))
			DIR_B:
				move(p_pos - Vector2((rect2.position.x + rect2.end.x) / 2, rect2.end.y))
			DIR_RT:
				move(p_pos - Vector2(rect2.end.x, rect2.position.y))
			DIR_R:
				move(p_pos - Vector2(rect2.end.x, (rect2.position.y + rect2.end.y) / 2))
			DIR_RB:
				move(p_pos - rect2.end)
	
	func get_dir_pos(p_dir):
		var rect2 = Rect2(renderNode.polygon[0], Vector2.ZERO)
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
		
		match p_dir:
			DIR_LT:
				return rect2.position
			DIR_L:
				return Vector2(rect2.position.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_LB:
				return Vector2(rect2.position.x, rect2.end.y)
			DIR_T:
				return Vector2((rect2.position.x + rect2.end.x) / 2, rect2.position.y)
			DIR_C:
				return Vector2((rect2.position.x + rect2.end.x) / 2, (rect2.position.y + rect2.end.y) / 2)
			DIR_B:
				return Vector2((rect2.position.x + rect2.end.x) / 2, rect2.end.y)
			DIR_RT:
				return Vector2(rect2.end.x, rect2.position.y)
			DIR_R:
				return Vector2(rect2.end.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_RB:
				return rect2.end
			_:
				print("[mainPanel::get_dir_pos] Wrong dir: ", str(p_dir))
	
	func get_dir_size(p_dir):
		var rect2 = Rect2(renderNode.polygon[0], Vector2.ZERO)
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
		return rect2.size
	
	func set_dir_size(p_dir, p_size):
		var rect2 = Rect2(renderNode.polygon[0], Vector2.ZERO)
		for i in range(1, renderNode.polygon.size()):
			rect2 = rect2.expand(renderNode.polygon[i])
		
		var scale = p_size / rect2.size
		var pivot
		match p_dir:
			DIR_LT:
				pivot = rect2.position
			DIR_L:
				pivot = Vector2(rect2.position.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_LB:
				pivot = Vector2(rect2.position.x, rect2.end.y)
			DIR_T:
				pivot = Vector2((rect2.position.x + rect2.end.x) / 2, rect2.position.y)
			DIR_C:
				pivot = Vector2((rect2.position.x + rect2.end.x) / 2, (rect2.position.y + rect2.end.y) / 2)
			DIR_B:
				pivot = Vector2((rect2.position.x + rect2.end.x) / 2, rect2.end.y)
			DIR_RT:
				pivot = Vector2(rect2.end.x, rect2.position.y)
			DIR_R:
				pivot = Vector2(rect2.end.x, (rect2.position.y + rect2.end.y) / 2)
			DIR_RB:
				pivot = rect2.end
		var points = []
		points.resize(renderNode.polygon.size())
		for i in range(0, renderNode.polygon.size()):
			points[i] = pivot + (renderNode.polygon[i] - pivot) * scale
		set_points(points)
	
	func set_points(p_points):
		showNode.set_points(p_points)
		renderNode.polygon = p_points
	
	func get_points():
		return showNode.polygon
	
	func set_name(p_name):
		listNode.set_item_name(p_name)
	
	func get_name():
		return listNode.get_item_name()
		
	func set_visible(p_visible):
		renderNode.visible = p_visible
		#showNode.visible = p_visible
		listNode.set_item_visible(p_visible)
	
	func get_visible():
		return renderNode.visible

	func get_handler(p_handlerId):
		return showNode.get_handler(p_handlerId)

	func is_own(p_node) -> bool:
		if p_node == showNode || p_node == listNode || p_node == renderNode:
			return true
		return false
	
	func save_data(configFile:ConfigFile, section:String):
		configFile.set_value(section, "name", get_name())
		configFile.set_value(section, "points", get_points())
		configFile.set_value(section, "normalType", get_normal_type())
		match get_normal_type():
			renderNode.NT_SINGLE:
				configFile.set_value(section, "normal", get_normal_data())
			renderNode.NT_AUTO:
				configFile.set_value(section, "emboss_height", get_normal_data()[0])
				configFile.set_value(section, "bump_height", get_normal_data()[1])
				configFile.set_value(section, "blur", get_normal_data()[2])
				configFile.set_value(section, "bump", get_normal_data()[3])
				configFile.set_value(section, "with_distance", get_normal_data()[4])
				configFile.set_value(section, "with_emboss", get_normal_data()[5])
		configFile.set_value(section, "visible", get_visible())
		
	
	func load_data(configFile:ConfigFile, section:String):
		set_name(configFile.get_value(section, "name", "item"))
		set_points(configFile.get_value(section, "points", []))
		var normalType = configFile.get_value(section, "normalType", NT_SINGLE)
		match normalType:
			renderNode.NT_SINGLE:
				set_single_normal(configFile.get_value(section, "normal", Vector3(0, 0, 1)))
			renderNode.NT_AUTO:
				set_auto_normal(configFile.get_value(section, "emboss_height", 0.1), configFile.get_value(section, "bump_height", 0.3), \
						configFile.get_value(section, "blur", 5), configFile.get_value(section, "bump", 60), \
						configFile.get_value(section, "with_distance", true), configFile.get_value(section, "with_emboss", true))
		set_visible(configFile.get_value(section, "visible", true))

func _init():
	iconMaterial = preload("res://addons/NormalMapEditor/iconMaterial.tres")
	selectIconMaterial = preload("res://addons/NormalMapEditor/selectIconMaterial.tres")
	version = undoRedo.get_version()
	modes = [ dummy.new(), CreatePolygonMode.new()]
	mode = modes[MODE_NONE]
	selectedMode = mode

func _ready():
	sourceBg.texture = get_icon("GuiMiniCheckerboard", "EditorIcons")
	sourceImg.material.set_shader_param("normal_texture", resultView.get_texture())
	sourceImg.material.set_shader_param("normal_preview", false)
	handlers.push_back(light)
	lightId = handlers.size() - 1

# 設置要生成的法線图的紋理路徑
func on_set_project(path:String):
	if path == sourcePath:
		return
	
	if version != undoRedo.get_version():
		askSavePop.choosed = askSavePop.CHOOSED_CANCEL
		askSavePop.popup_centered()
		yield(askSavePop, "popup_hide")
		yield(get_tree(), "idle_frame")
		match askSavePop.choosed:
			askSavePop.CHOOSED_CANCEL:
				return
			askSavePop.CHOOSED_OK:
				save_project()
	undoRedo.clear_history()
	version = undoRedo.get_version()
	set_project(path)

func set_project(path:String):
	sourcePath = path
	source = load(sourcePath)
	clear_item()
	to_mode(modes[MODE_NONE])
	var dir = Directory.new()
	if dir.file_exists(sourcePath.get_basename() + ".nmp"):
		load_project(sourcePath.get_basename() + ".nmp")
	sourceBg.rect_min_size = source.get_size()
	sourceImg.texture = source
	renderNodeParent.size = source.get_size()
	sourceImg.material.set_shader_param("normal_texture", resultView.get_texture())
	view.grab_focus()
	view.grab_click_focus()

func load_project(path:String):
	var configFile = ConfigFile.new()
	configFile.load(path)
	clear_item()
	var itemCount = configFile.get_value("item", "count", 0)
	var section
	var tempItem
	for i in itemCount:
		section = str(i)
		tempItem = Item.new()
		tempItem.load_data(configFile, section, source)
		add_item(tempItem)


func save_project():
	if sourcePath == null || version == undoRedo.get_version():
		return
	var configFile = ConfigFile.new()
	configFile.set_value("item", "count", items.size())
	var section
	for i in items.size():
		section = str(i)
		items[i].save_data(configFile, section)
	configFile.save(sourcePath.get_basename() + ".nmp")
	print("Save project path: ", sourcePath.get_basename() + ".nmp")
	version = undoRedo.get_version()

func export_normal_map():
	if sourcePath == null:
		return
	var img := Image.new()
	img.copy_from(resultView.get_texture().get_data())
	img.convert(Image.FORMAT_RGBA8)
	var path = sourcePath.get_basename() + "_n.png"
	img.save_png(path)
	print("Export path: ", path)
	editorFileSystem.scan()

func get_config_file_path():
	return get_script().get_path().get_base_dir() + "/" + CONFIG_FILENAME

func load_config():
	if not is_inside_tree():
		print("[mainPanel::load_config] Can not load config outside tree!")
		return
	
	if not get_tree().has_group("config"):
		return
	
	var cfg = ConfigFile.new()
	if cfg.load(get_config_file_path()) == OK:
		var array = get_tree().get_nodes_in_group("config")
		#print("load config: ", str(array))
		for i in array.size():
			if array[i].has_method("load_data"):
				array[i].load_data(cfg)

func save_config():
	if not is_inside_tree():
		print("[mainPanel::save_config] Can not save config outside tree!")
		return
	
	if not get_tree().has_group("config"):
		return
	
	var cfg = ConfigFile.new()
	cfg.load(get_config_file_path())
	
	var array = get_tree().get_nodes_in_group("config")
	#print("save config: ", str(array))
	for i in array.size():
		if array[i].has_method("save_data"):
			array[i].save_data(cfg)
	
	cfg.save(get_config_file_path())

func clear_item():
	for i in items:
		if i.data.has_method("destroy"):
			i.data.destroy()
	items.clear()

func add_rect(p_pos:Vector2, p_pointData, p_normal:Vector3, p_name = "item", p_visible = true):
	var item = Item.new()
	item.type = ITEM_TYPE_RECT
	item.data = RectItem.new()
	item.data.set_pos(p_pos)
	item.data.set_rot_size(p_pointData[0], p_pointData[1])
	item.data.set_noraml(p_normal)
	item.data.set_name(p_name)
	item.data.set_visible(p_visible)
	#item.data.showNode.connect("vertex_selected", self, "on_item_vertex_selected", [item])
	#item.data.showNode.connect("vertex_drag", self, "on_item_vertex_drag", [item])
	add_item(item)

func add_polygon(p_points, p_normalType, p_normalData, p_name = "item", p_visible = true):
	var item = Item.new()
	item.type = ITEM_TYPE_POLYGON
	item.data = PolygonItem.new(source)
	match p_normalType:
		NT_SINGLE:
			item.data.set_single_normal(p_normalData)
		NT_AUTO:
			item.data.set_auto_normal(p_normalData[0], p_normalData[1], p_normalData[2], p_normalData[3], p_normalData[4], p_normalData[5])
	item.data.set_points(p_points)
	item.data.set_name(p_name)
	item.data.set_visible(p_visible)

	add_item(item)

func add_item(item):
	match item.type:
		ITEM_TYPE_POLYGON:
			item.data.showNode.connect("vertex_selected", self, "on_item_vertex_selected", [item])
			item.data.showNode.connect("vertex_deleted", self, "on_item_vertex_deleted", [item])
			item.data.listNode.connect("item_selected", self, "on_item_selected", [item])
			item.data.listNode.connect("item_name_changed", self, "on_item_name_changed", [item])
			item.data.listNode.connect("item_visibity_changed", self, "on_item_visibity_changed", [item])
		ITEM_TYPE_RECT:
			item.data.listNode.connect("item_selected", self, "on_item_selected", [item])
			item.data.listNode.connect("item_name_changed", self, "on_item_name_changed", [item])
			item.data.listNode.connect("item_visibity_changed", self, "on_item_visibity_changed", [item])
			#item.data.showNode.connect("vertex_drag", self, "on_item_vertex_drag", [item])
	items.push_back(item)
	renderNodeParent.add_child(item.data.renderNode)
	showNodeParent.add_child(item.data.showNode)
	
	layerDock.add_item(item.data.listNode)
	if mode != modes[MODE_NONE] && mode.has_method("add_item_process"):
		mode.add_item_process(item.data.showNode)

func delete_item(p_itemId):
	var i = items[p_itemId]
	if items[p_itemId].data.has_method("destroy"):
		items[p_itemId].data.destroy()
		print("destroy item")
	items.remove(p_itemId)
	

func move_item_point(p_itemId, p_vertId, p_pos):
	items[p_itemId].data.on_move_point(p_vertId, p_pos)

#func on_item_vertex_drag(vertId, item):
#	#item.data.renderNode.polygon[vertId] = item.showNode.polygon[vertId]
#	pass


func on_item_vertex_selected(vertId, dragVec, item):
	if dragVec != Vector2.ZERO:
		var id = items.find(item)
		if id >= 0:
			undoRedo.create_action("Drag item vertex")
			undoRedo.add_do_method(self, "move_item_point", id, vertId, item.data.showNode.polygon[vertId])
			undoRedo.add_undo_method(self, "move_item_point", id, vertId, item.data.renderNode.polygon[vertId])
			undoRedo.commit_action()
			print("Drag item vertex")
		else:
			print("[mainPanel::on_item_vertex_selected] Can not find item in items!")
	# 工具欄显示屬性修改
	var id = items.find(item)
	select(vertId, id)

func delete_item_point(p_itemId, p_vertId):
	items[p_itemId].data.on_delete_point(p_vertId)

func insert_item_point(p_itemId, p_vertId, p_pos):
	items[p_itemId].data.on_insert_point(p_vertId, p_pos)

func on_item_vertex_deleted(vertId, item):
	var id = items.find(item)
	if id >= 0:
		var isSelecting:bool = get_selected_obj() == item.data.get_handler(vertId)
		undoRedo.create_action("Delete item vertex")
		if isSelecting:
			unselect_do()
		undoRedo.add_do_method(self, "delete_item_point", id, vertId)
		undoRedo.add_undo_method(self, "insert_item_point", id, vertId, item.data.get_points[vertId])
		if isSelecting:
			unselect_undo()
		undoRedo.commit_action()
		print("Delete item vertex")
	else:
		print("[mainPanel::on_item_vertex_selected] Can not find item in items!")

func on_item_selected(item):
	view.grab_focus()
	var id = items.find(item)
	
	if id >= 0:
		if selectedItemId == id:
			unselect()
			return
		
		if mode != modes[MODE_NONE]:
			undoRedo.create_action("Toggle mode")
			undoRedo.add_do_method(self, "to_mode", modes[MODE_NONE])
			undoRedo.add_undo_method(self, "to_mode", mode)
			undoRedo.commit_action()
		select(-1, id)
	else:
		print("[mainPanel::on_item_selected] Can not find item in items!")

func set_item_name(p_itemId, p_newName):
	items[p_itemId].data.set_name(p_newName)

func on_item_name_changed(newName, item):
	view.grab_focus()
	var id = items.find(item)
	if id >= 0:
		undoRedo.create_action("Item rename")
		undoRedo.add_do_method(self, "set_item_name", id, newName)
		undoRedo.add_undo_method(self, "set_item_name", id, item.data.get_name())
		undoRedo.commit_action()
		print("Item rename")
	else:
		print("[mainPanel::on_item_name_changed] Can not find item in items!")

func set_item_visible(p_itemId:int, p_visible:bool):
	items[p_itemId].data.set_visible(p_visible)

func on_item_visibity_changed(visible, item):
	var id = items.find(item)
	if id >= 0:
		undoRedo.create_action("Set item visible")
		undoRedo.add_do_method(self, "set_item_visible", id, visible)
		undoRedo.add_undo_method(self, "set_item_visible", id, item.data.get_visible())
		undoRedo.commit_action()
		print("Set item visible")
	else:
		print("[mainPanel::on_item_visibity_changed] Can not find item in items!")

func on_drag_list_node(p_listNode, p_newId):
	for i in items.size():
		if items[i].data.is_own(p_listNode):
			undoRedo.create_action("Drag list item")
			undoRedo.add_do_method(self, "set_item_id", i, p_newId)
			undoRedo.add_undo_method(self, "set_item_id", p_newId, i)
			undoRedo.commit_action()
			print("Drag list item")
			return

func to_mode(p_mode):
	if mode != modes[MODE_NONE] && mode.has_method("exit"):
		mode.exit()
	mode = p_mode
	if mode != modes[MODE_NONE] && mode.has_method("enter"):
		mode.enter(self)

func _on_select_pressed():
	pass


func _on_rect_pressed():
	pass # Replace with function body.


func _on_polygon_pressed():
	if source == null:
		return
	
	undoRedo.create_action("Toggle mode")
	undoRedo.add_do_method(self, "to_mode", modes[MODE_CREATE_POLYGON])
	undoRedo.add_undo_method(self, "to_mode", mode)
	undoRedo.commit_action()
	print("Toggle mode")

func _on_magic_pressed():
	pass


func get_selected_obj():
	if selectedMode != modes[MODE_NONE] && selectedMode.has_method("get_selected_obj"):
		return selectedMode.get_selected_obj()
	if selectedItemId >= 0 && selectedItemId < items.size():
		if selectedHandlerId < 0:
			return items[selectedItemId].data
		else:
			return items[selectedItemId].data.get_handler(selectedHandlerId)
	if selectedHandlerId >= 0 && selectedHandlerId < handlers.size():
		return handlers[selectedHandlerId]
	return null

func selected_obj_select():
	var obj = get_selected_obj()
	if obj != null:
		obj.select(self)

func select(p_handlerId, p_itemId = -1, p_mode = modes[MODE_NONE]):
	if p_mode == modes[MODE_NONE] && selectedMode == modes[MODE_NONE] && p_itemId < 0 && selectedItemId < 0:
		selected_obj_unselect()
		set_select(p_handlerId, p_itemId, p_mode)
		if selectedHandlerId >= 0 && selectedHandlerId < handlers.size():
			handlers[selectedHandlerId].select(self)
		return
	
	undoRedo.create_action("Select")
	select_do(p_handlerId, p_itemId, p_mode)
	select_undo()
	undoRedo.commit_action()
	print("Select")

func set_select(p_handlerId:int, p_itemId:int, p_mode):
	selectedHandlerId = p_handlerId
	selectedItemId = p_itemId
	selectedMode = p_mode

func select_do(p_handlerId, p_itemId, p_mode):
	#print("select_do(", str(p_handlerId), ", ", str(p_itemId), ", ", str(p_mode), ")")
	undoRedo.add_do_method(self, "selected_obj_unselect")
	undoRedo.add_do_method(self, "set_select", p_handlerId, p_itemId, p_mode)
	undoRedo.add_do_method(self, "selected_obj_select")

func select_undo():
	#print("select_undo(", str(selectedHandlerId), ", ", str(selectedItemId), ", ", str(selectedMode), ")")
	undoRedo.add_undo_method(self, "selected_obj_unselect")
	undoRedo.add_undo_method(self, "set_select", selectedHandlerId, selectedItemId, selectedMode)
	undoRedo.add_undo_method(self, "selected_obj_select")
	
func selected_obj_unselect():
	var obj = get_selected_obj()
	if obj != null:
		obj.unselect(self)


func unselect():
	if selectedMode == modes[MODE_NONE] && selectedItemId < 0:
		selected_obj_unselect()
		set_select(-1, -1, modes[MODE_NONE])
		return
	
	undoRedo.create_action("Unselect")
	unselect_do()
	unselect_undo()
	undoRedo.commit_action()
	print("Unselect")

func unselect_do():
	#print("unselect_do(", str(-1), ", ", str(-1), ", ", str(modes[MODE_NONE]), ")")
	undoRedo.add_do_method(self, "selected_obj_unselect")
	undoRedo.add_do_method(self, "set_select", -1, -1, modes[MODE_NONE])

func unselect_undo():
	#print("unselect_undo(", str(selectedHandlerId), ", ", str(selectedItemId), ", ", str(selectedMode), ")")
	undoRedo.add_undo_method(self, "set_select", selectedHandlerId, selectedItemId, selectedMode)
	undoRedo.add_undo_method(self, "selected_obj_select")

func set_item_id(p_itemId, p_newId):
	items[p_itemId].data.set_item_id(p_newId)
	items.insert(p_newId, items[p_itemId])
	if p_itemId < p_newId:
		items.remove(p_itemId)
	else:
		items.remove(p_itemId + 1)

func delete_selected_item():
	var obj = get_selected_obj()
	if obj == null || selectedItemId < 0 || obj != items[selectedItemId].data:
		return
	
	undoRedo.create_action("Delete item")
	unselect_do()
	undoRedo.add_do_method(self, "delete_item", selectedItemId)
	match items[selectedItemId].type:
		ITEM_TYPE_POLYGON:
			undoRedo.add_undo_method(self, "add_polygon", obj.get_points(), obj.get_normal_type(), obj.get_normal_data(), obj.get_name(), obj.get_visible())
		ITEM_TYPE_RECT:
			var pointData = [ obj.get_rot(), obj.get_size() ]
			undoRedo.add_undo_method(self, "add_rect", obj.get_pos(), pointData, obj.get_normal(), obj.get_name(), obj.get_visible())
	undoRedo.add_undo_method(self, "set_item_id", items.size() - 1, selectedItemId)
	unselect_undo()
	undoRedo.commit_action()
	print("Delete item")

func _on_Panel_input(event):
	if source == null:
		return
	
	if event is InputEventKey:
		if event.scancode == KEY_Z && event.control && !event.alt:
			accept_event()
			if !event.pressed || event.echo:
				return
			if event.shift:
				if undoRedo.has_redo():
					undoRedo.redo()
					print("Redo")
			else:
				if undoRedo.has_undo():
					undoRedo.undo()
					print("Undo")
			return
		elif event.scancode == KEY_L && !event.control && !event.shift && !event.alt:
			accept_event()
			if !event.pressed || event.echo:
				return
			select(lightId)
			return
		elif event.scancode == KEY_DELETE && !event.control && !event.shift && !event.alt:
			if mode == modes[MODE_NONE]:
				accept_event()
				if !event.pressed || event.echo:
					return
				if selectedMode != modes[MODE_NONE] || selectedItemId < 0 || selectedHandlerId >= 0:
					return
				delete_selected_item()
				return
	
	if mode != modes[MODE_NONE] && mode.has_method("input"):
		mode.input(event)

func show_pos_dir_tool():
	toolXLabel.show()
	toolXEdit.show()
	toolYLabel.show()
	toolYEdit.show()
	toolPosDir.show()
	var obj = get_selected_obj()
	if obj != null:
		var pos = obj.get_dir_pos(toolPosDir.get_dir())
		var connectData = toolXEdit.get_signal_connection_list("value_changed")
		for i in connectData.size():
			toolXEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
		toolXEdit.value = pos.x
		for i in connectData.size():
			toolXEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
		connectData = toolYEdit.get_signal_connection_list("value_changed")
		for i in connectData.size():
			toolYEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
		toolYEdit.value = pos.y
		for i in connectData.size():
			toolYEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])

func hide_pos_dir_tool():
	toolXLabel.hide()
	toolXEdit.hide()
	toolYLabel.hide()
	toolYEdit.hide()
	toolPosDir.hide()

func show_pos_tool():
	toolXLabel.show()
	toolXEdit.show()
	toolYLabel.show()
	toolYEdit.show()

	var obj = get_selected_obj()
	if obj != null:
		var connectData = toolXEdit.get_signal_connection_list("value_changed")
		for i in connectData.size():
			toolXEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
		toolXEdit.value = obj.get_x()
		for i in connectData.size():
			toolXEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
		connectData = toolYEdit.get_signal_connection_list("value_changed")
		for i in connectData.size():
			toolYEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
		toolYEdit.value = obj.get_y()
		for i in connectData.size():
			toolYEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])

func hide_pos_tool():
	toolXLabel.hide()
	toolXEdit.hide()
	toolYLabel.hide()
	toolYEdit.hide()


func show_z_tool():
	toolZLabel.show()
	toolZEdit.show()
	var obj = get_selected_obj()
	if obj != null:
		var connectData = toolZEdit.get_signal_connection_list("value_changed")
		for i in connectData.size():
			toolZEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
		toolZEdit.value = obj.get_z()
		for i in connectData.size():
			toolZEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])

func hide_z_tool():
	toolZLabel.hide()
	toolZEdit.hide()

func show_size_tool():
	toolWLabel.show()
	toolWEdit.show()
	toolHLabel.show()
	toolHEdit.show()
	var obj = get_selected_obj()
	if obj != null:
		if toolPosDir.visible:
			var size = obj.get_dir_size(toolPosDir.get_dir())
			var connectData = toolWEdit.get_signal_connection_list("value_changed")
			for i in connectData.size():
				toolWEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
			toolWEdit.value = size.x
			for i in connectData.size():
				toolWEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
			connectData = toolHEdit.get_signal_connection_list("value_changed")
			for i in connectData.size():
				toolHEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
			toolHEdit.value = size.y
			for i in connectData.size():
				toolHEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
		else:
			var connectData = toolWEdit.get_signal_connection_list("value_changed")
			for i in connectData.size():
				toolWEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
			toolWEdit.value = obj.get_width()
			for i in connectData.size():
				toolWEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
			connectData = toolHEdit.get_signal_connection_list("value_changed")
			for i in connectData.size():
				toolHEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
			toolHEdit.value = obj.get_height()
			for i in connectData.size():
				toolHEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])

func hide_size_tool():
	toolWLabel.hide()
	toolWEdit.hide()
	toolHLabel.hide()
	toolHEdit.hide()

func show_enable_tool():
	toolEnable.show()
	var obj = get_selected_obj()
	if obj != null:
		var connectData = toolEnable.get_signal_connection_list("toggled")
		for i in connectData.size():
			toolEnable.disconnect("toggled", connectData[i]["target"], connectData[i]["method"])
		toolEnable.pressed = !obj.is_disabled()
		for i in connectData.size():
			toolEnable.connect("toggled", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
		

func hide_enable_tool():
	toolEnable.hide()

func show_rotation_tool():
	toolRotation.show()
	var obj = get_selected_obj()
	if obj != null:
		toolRotationDraw.set_quat(obj.get_rot())

func hide_rotation_tool():
	toolRotation.hide()

func show_normal_tool():
	toolNormal.show()
	var obj = get_selected_obj()
	if obj != null:
		toolNormalDraw.set_normal(obj.get_single_normal())

func hide_normal_tool():
	toolNormal.hide()

func show_auto_normal_tool():
	toolEmbossCheckBox.show()
	toolEmbossEdit.show()
	toolBumpCheckBox.show()
	toolBumpHeightEdit.show()
	toolBlurLabel.show()
	toolBlurEdit.show()
	toolBumpLabel.show()
	toolBumpEdit.show()
	var obj = get_selected_obj()
	var connectData = toolEmbossCheckBox.get_signal_connection_list("toggled")
	for i in connectData.size():
		toolEmbossCheckBox.disconnect("toggled", connectData[i]["target"], connectData[i]["method"])
	toolEmbossCheckBox.pressed = obj.is_emboss_enabled()
	for i in connectData.size():
		toolEmbossCheckBox.connect("toggled", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
	toolEmbossEdit.set_value_without_signal(obj.get_emboss())
	connectData = toolBumpCheckBox.get_signal_connection_list("toggled")
	for i in connectData.size():
		toolBumpCheckBox.disconnect("toggled", connectData[i]["target"], connectData[i]["method"])
	toolBumpCheckBox.pressed = obj.is_bump_enabled()
	for i in connectData.size():
		toolBumpCheckBox.connect("toggled", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
	toolBumpHeightEdit.set_value_without_signal(obj.get_bump_height())
	toolBlurEdit.set_value_without_signal(obj.get_blur())
	toolBumpEdit.set_value_without_signal(obj.get_bump())

func hide_auto_normal_tool():
	toolEmbossCheckBox.hide()
	toolEmbossEdit.hide()
	toolBumpCheckBox.hide()
	toolBumpHeightEdit.hide()
	toolBlurLabel.hide()
	toolBlurEdit.hide()
	toolBumpLabel.hide()
	toolBumpEdit.hide()

func show_normal_type_tool():
	toolNormalTypeOptBtn.show()
	var obj = get_selected_obj()
	if obj == null:
		print("[mainPanel::show_normal_type_tool] obj is null!")
		return
	var type = obj.get_normal_type()
	match type:
		NT_SINGLE:
			show_normal_tool()

		NT_AUTO:
			show_auto_normal_tool()


func hide_normal_type_tool():
	toolNormalTypeOptBtn.hide()
	var obj = get_selected_obj()
	if obj == null:
		print("[mainPanel::hide_normal_type_tool] obj is null!")
		return
	var type = obj.get_normal_type()
	match type:
		NT_SINGLE:
			hide_normal_tool()
		NT_AUTO:
			hide_auto_normal_tool()

func selected_obj_set_dir_pos(p_dir, p_pos):
	get_selected_obj().set_dir_pos(p_dir, p_pos)

func selected_obj_set_x(p_x):
	get_selected_obj().set_x(p_x)

func is_selected_main_handler():
	return selectedMode == modes[MODE_NONE] && selectedItemId < 0

func _on_xEdit_value_changed(value):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_x(value)
		return
	
	if toolPosDir.visible:
		var dirPos = obj.get_dir_pos(toolPosDir.dir)
		undoRedo.create_action("Set dir pos")
		undoRedo.add_do_method(self, "selected_obj_set_dir_pos", toolPosDir.dir, Vector2(value, dirPos.y))
		undoRedo.add_do_method(toolXEdit, "set_value", value)
		undoRedo.add_undo_method(self, "selected_obj_set_dir_pos", toolPosDir.dir, dirPos)
		undoRedo.add_undo_method(toolXEdit, "set_value", dirPos.x)
		undoRedo.commit_action()
		print("Set dir pos")
	else:
		undoRedo.create_action("Set x")
		undoRedo.add_do_method(self, "selected_obj_set_x", value)
		undoRedo.add_do_method(toolXEdit, "set_value", value)
		var x = obj.get_x()
		undoRedo.add_undo_method(self, "selected_obj_set_x", x)
		undoRedo.add_undo_method(toolXEdit, "set_value", x)
		undoRedo.commit_action()
		print("Set x")
	
func selected_obj_set_y(p_y):
	get_selected_obj().set_y(p_y)

func _on_yEdit_value_changed(value):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_y(value)
		return
	
	if toolPosDir.visible:
		var dirPos = obj.get_dir_pos(toolPosDir.dir)
		undoRedo.create_action("Set dir pos")
		undoRedo.add_do_method(self, "selected_obj_set_dir_pos", toolPosDir.dir, Vector2(dirPos.x, value))
		undoRedo.add_do_method(toolYEdit, "set_value", value)
		undoRedo.add_undo_method(self, "selected_obj_set_dir_pos", toolPosDir.dir, dirPos)
		undoRedo.add_undo_method(toolYEdit, "set_value", dirPos.y)
		undoRedo.commit_action()
		print("Set dir pos")
	else:
		undoRedo.create_action("Set y")
		undoRedo.add_do_method(self, "selected_obj_set_y", value)
		undoRedo.add_do_method(toolYEdit, "set_value", value)
		var y = obj.get_y()
		undoRedo.add_undo_method(self, "selected_obj_set_y", y)
		undoRedo.add_undo_method(toolYEdit, "set_value", y)
		undoRedo.commit_action()
		print("Set y")


func _on_createPolygonPop_CreateBtn_pressed():
	createPolygonPop.hide()
	undoRedo.create_action("Add polygon")
	undoRedo.add_do_method(self, "add_polygon", createPolygonPop.get_points(), createPolygonPop.get_normal_type(), createPolygonPop.get_normal_data())
	undoRedo.add_undo_method(self, "delete_item", items.size())
	undoRedo.commit_action()
	print("Add polygon")


func _on_mainScreen_visibility_changed():
	if visible && view != null:
		view.grab_focus()
		view.grab_click_focus()
		#print("focus owner", str(get_focus_owner()))


func _on_showToggle_pressed():
	showNormal = !showNormal
	sourceImg.material.set_shader_param("normal_preview", showNormal)
	if showNormal:
		toolShowToggle.texture = preload("showToggle_1.svg")
	else:
		toolShowToggle.texture = preload("showToggle_0.svg")


func _on_light_released():
	select(lightId)


func selected_obj_set_dir_size(p_dir, p_size):
	get_selected_obj().set_dir_size(p_dir, p_size)

func selected_obj_set_width(p_width):
	get_selected_obj().set_width(p_width)

func _on_wEdit_value_changed(value):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_width(value)
		return
	
	if toolPosDir.visible:
		undoRedo.create_action("Set dir size")
		var size = obj.get_dir_size(toolPosDir.get_dir())
		undoRedo.add_do_method(self, "selected_obj_set_dir_size", toolPosDir.get_dir(), Vector2(value, size.y))
		undoRedo.add_do_method(toolWEdit, "set_value", value)
		undoRedo.add_undo_method(self, "selected_obj_set_dir_size", toolPosDir.get_dir(), size)
		undoRedo.add_undo_method(toolWEdit, "set_value", size.x)
		undoRedo.commit_action()
		print("Set dir size")
	else:
		undoRedo.create_action("Set width")
		undoRedo.add_do_method(self, "selected_obj_set_width", value)
		undoRedo.add_do_method(toolWEdit, "set_value", value)
		var w = obj.get_width()
		undoRedo.add_undo_method(self, "selected_obj_set_width", w)
		undoRedo.add_undo_method(toolWEdit, "set_value", w)
		undoRedo.commit_action()
		print("Set width")

func selected_obj_set_height(p_height):
	get_selected_obj().set_height(p_height)

func _on_hEdit_value_changed(value):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_height(value)
		return
	
	if toolPosDir.visible:
		undoRedo.create_action("Set dir size")
		var size = obj.get_dir_size(toolPosDir.get_dir())
		undoRedo.add_do_method(self, "selected_obj_set_dir_size", toolPosDir.get_dir(), Vector2(size.x, value))
		undoRedo.add_do_method(toolHEdit, "set_value", value)
		undoRedo.add_undo_method(self, "selected_obj_set_dir_size", toolPosDir.get_dir(), size)
		undoRedo.add_undo_method(toolHEdit, "set_value", size.y)
		undoRedo.commit_action()
		print("Set dir size")
	else:
		undoRedo.create_action("Set height")
		undoRedo.add_do_method(self, "selected_obj_set_height", value)
		undoRedo.add_do_method(toolHEdit, "set_value", value)
		var h = obj.get_height()
		undoRedo.add_undo_method(self, "selected_obj_set_height", h)
		undoRedo.add_undo_method(toolHEdit, "set_value", h)
		undoRedo.commit_action()
		print("Set height")

func selected_obj_set_z(p_z):
	get_selected_obj().set_z(p_z)

func _on_zEdit_value_changed(value):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_z(value)
		return
	
	undoRedo.create_action("Set z")
	undoRedo.add_do_method(self, "selected_obj_set_z", value)
	undoRedo.add_do_method(toolZEdit, "set_value", value)
	var z = obj.get_z()
	undoRedo.add_undo_method(self, "selected_obj_set_z", z)
	undoRedo.add_undo_method(toolZEdit, "set_value", z)
	undoRedo.commit_action()
	print("Set z")

func selected_obj_set_disabled(p_disabled):
	get_selected_obj().set_disabled(p_disabled)

func _on_enableCheck_toggled(button_pressed):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_disabled(!button_pressed)
		return
	
	undoRedo.create_action("Set disabled")
	undoRedo.add_do_method(self, "selected_obj_set_disabled", !button_pressed)
	undoRedo.add_do_method(toolEnable, "set_pressed", button_pressed)
	undoRedo.add_undo_method(self, "selected_obj_set_disabled", button_pressed)
	undoRedo.add_undo_method(toolEnable, "set_pressed", !button_pressed)
	undoRedo.commit_action()
	print("Set disabled")

func selected_obj_set_normal(p_normal:Vector3):
	get_selected_obj().set_single_normal(p_normal)

# Vector3(0, 0, 1)方向开始旋轉
func quat2normal(p_quat) -> Vector3:
	return p_quat.xform(Vector3(0, 0, 1))

func _on_PopupPanel_select_quat(quat):
	var obj = get_selected_obj()
	var normal = quat2normal(quat)
	if is_selected_main_handler():
		obj.set_single_normal(normal)
		return
	
	undoRedo.create_action("Set normal")
	undoRedo.add_do_method(self, "selected_obj_set_normal", normal)
	undoRedo.add_do_method(toolNormalDraw, "set_quat", quat)
	var n = obj.get_single_normal()
	undoRedo.add_undo_method(self, "selected_obj_set_normal", n)
	undoRedo.add_undo_method(toolNormalDraw, "set_quat", quat)
	undoRedo.commit_action()
	print("Set normal")


func _on_normalDraw_pressed():
	# 彈出編輯法線窗口
	editNormalPop.set_quat(toolNormalDraw.get_quat())
	editNormalPop.popup_centered()
	yield(editNormalPop, "popup_hide")
	yield(get_tree(), "idle_frame")
	if editNormalPop.choosed == editNormalPop.NONE:
		return
	var quat = editNormalPop.get_quat()
	_on_PopupPanel_select_quat(quat)
	if editNormalPop.choosed == editNormalPop.MODIFY_SAVE:
		templatePopupPanel.add_template(quat)
		#print("editNormalPop get normal", str(editNormalPop.get_normal()))


func selected_obj_set_rot(p_rot:Quat):
	get_selected_obj().set_rot(p_rot)


func _on_rotPopupPanel_select_quat(quat):
	var obj = get_selected_obj()
	if is_selected_main_handler():
		obj.set_rot(quat)
		return
	
	undoRedo.create_action("Set rotation")
	undoRedo.add_do_method(self, "selected_obj_set_rot", quat)
	undoRedo.add_do_method(toolRotationDraw, "set_quat", quat)
	var last = obj.get_rot()
	undoRedo.add_undo_method(self, "selected_obj_set_rot", last)
	undoRedo.add_undo_method(toolRotationDraw, "set_quat", last)
	undoRedo.commit_action()
	print("Set rotation")

func _on_rotationDraw_pressed():
	# 彈出編輯法線窗口
	editNormalPop.set_quat(toolRotationDraw.get_quat())
	editNormalPop.popup_centered()
	yield(editNormalPop, "popup_hide")
	yield(get_tree(), "idle_frame")
	if editNormalPop.choosed == editNormalPop.NONE:
		return
	var quat = editNormalPop.get_quat()
	_on_rotPopupPanel_select_quat(quat)
	if editNormalPop.choosed == editNormalPop.MODIFY_SAVE:
		templatePopupPanel.add_template(quat)
		#print("editNormalPop get normal", str(editNormalPop.get_normal()))

func selected_obj_set_emboss_enabled(p_enabled:bool):
	get_selected_obj().set_emboss_enabled(p_enabled)

func _on_embossCheckBox_toggled(button_pressed):
	undoRedo.create_action("Set emboss enabled")
	undoRedo.add_do_method(self, "selected_obj_set_emboss_enabled", button_pressed)
	undoRedo.add_do_method(toolEmbossCheckBox, "set_pressed", button_pressed)
	undoRedo.add_undo_method(self, "selected_obj_set_emboss_enabled", !button_pressed)
	undoRedo.add_undo_method(toolEmbossCheckBox, "set_pressed", !button_pressed)
	undoRedo.commit_action()
	print("Set emboss enabled")

func selected_obj_set_emboss(p_value:float):
	get_selected_obj().set_emboss(p_value)

func _on_embossEdit_value_changed():
	var obj = get_selected_obj()
	
	undoRedo.create_action("Set emboss")
	undoRedo.add_do_method(self, "selected_obj_set_emboss", toolEmbossEdit.value)
	undoRedo.add_do_method(toolEmbossEdit, "set_value", toolEmbossEdit.value)
	var last = obj.get_emboss()
	undoRedo.add_undo_method(self, "selected_obj_set_emboss", last)
	undoRedo.add_undo_method(toolEmbossEdit, "set_value", last)
	undoRedo.commit_action()
	print("Set emboss")

func selected_obj_set_bump_enabled(p_enabled:bool):
	get_selected_obj().set_bump_enabled(p_enabled)

func _on_bumpCheckBox_toggled(button_pressed):
	undoRedo.create_action("Set bump enabled")
	undoRedo.add_do_method(self, "selected_obj_set_bump_enabled", button_pressed)
	undoRedo.add_do_method(toolBumpCheckBox, "set_pressed", button_pressed)
	undoRedo.add_undo_method(self, "selected_obj_set_bump_enabled", !button_pressed)
	undoRedo.add_undo_method(toolBumpCheckBox, "set_pressed", !button_pressed)
	undoRedo.commit_action()
	print("Set bump enabled")

func selected_obj_set_bump_height(p_value:float):
	get_selected_obj().set_bump_height(p_value)

func _on_bumpHeightEdit_value_changed():
	undoRedo.create_action("Set bump height")
	undoRedo.add_do_method(self, "selected_obj_set_bump_height", toolBumpHeightEdit.value)
	undoRedo.add_do_method(toolBumpHeightEdit, "set_value", toolBumpHeightEdit.value)
	var last = get_selected_obj().get_bump_height()
	undoRedo.add_undo_method(self, "selected_obj_set_bump_height", last)
	undoRedo.add_undo_method(toolBumpHeightEdit, "set_value", last)
	undoRedo.commit_action()
	print("Set bump height")

func selected_obj_set_blur(p_value:float):
	get_selected_obj().set_blur(p_value)

func _on_blurEdit_value_changed():
	undoRedo.create_action("Set blur")
	undoRedo.add_do_method(self, "selected_obj_set_blur", toolBlurEdit.value)
	undoRedo.add_do_method(toolBlurEdit, "set_value", toolBlurEdit.value)
	var last = get_selected_obj().get_blur()
	undoRedo.add_undo_method(self, "selected_obj_set_blur", last)
	undoRedo.add_undo_method(toolBlurEdit, "set_value", last)
	undoRedo.commit_action()
	print("Set blur")

func selected_obj_set_bump(p_value:float):
	get_selected_obj().set_bump(p_value)

func _on_bumpEdit_value_changed():
	undoRedo.create_action("Set bump")
	undoRedo.add_do_method(self, "selected_obj_set_bump", toolBumpEdit.value)
	undoRedo.add_do_method(toolBumpEdit, "set_value", toolBumpEdit.value)
	var last = get_selected_obj().get_bump()
	undoRedo.add_undo_method(self, "selected_obj_set_bump", last)
	undoRedo.add_undo_method(toolBumpEdit, "set_value", last)
	undoRedo.commit_action()
	print("Set bump")


func selected_obj_set_single_normal(p_normal:Vector3):
	get_selected_obj().set_single_normal(p_normal)

func selected_obj_set_auto_normal(p_data:Dictionary):#p_embossEnabled:bool, p_emboss:float, p_bumpEnabled:bool, p_bumpHeight:float, p_blur, p_bump):
#	for i in p_data.size():
#		print("data[%s] = %s" % [str(i), str(p_data[i])])
	get_selected_obj().set_auto_normal(p_data[1], p_data[3], p_data[4], p_data[5], p_data[2], p_data[0])
	#get_selected_obj().set_auto_normal(p_emboss, p_bumpHeight, p_blur, p_bump, p_bumpEnabled, p_embossEnabled)

func _on_normalTypeOptBtn_item_selected(id):
	match id:
		NT_SINGLE:
			undoRedo.create_action("Set normal type")
			undoRedo.add_do_method(self, "hide_normal_type_tool")
			undoRedo.add_do_method(self, "selected_obj_set_single_normal", toolNormalDraw.get_normal())
			undoRedo.add_do_method(self, "show_normal_type_tool")
			undoRedo.add_undo_method(self, "hide_normal_type_tool")
			undoRedo.add_undo_method(self, "selected_obj_set_auto_normal", { 0:toolEmbossCheckBox.pressed, \
					1:toolEmbossEdit.value, 2:toolBumpCheckBox.pressed, 3:toolBumpHeightEdit.value, 4:toolBlurEdit.value, 5:toolBumpEdit.value})
			undoRedo.add_undo_method(self, "show_normal_type_tool")
			undoRedo.commit_action()
			print("Set normal type")
		NT_AUTO:
			undoRedo.create_action("Set auto type")
			undoRedo.add_do_method(self, "hide_normal_type_tool")
			undoRedo.add_do_method(self, "selected_obj_set_auto_normal", { 0:toolEmbossCheckBox.pressed, \
					1:toolEmbossEdit.value, 2:toolBumpCheckBox.pressed, 3:toolBumpHeightEdit.value, 4:toolBlurEdit.value, 5:toolBumpEdit.value})
			undoRedo.add_do_method(self, "show_normal_type_tool")
			undoRedo.add_undo_method(self, "hide_normal_type_tool")
			undoRedo.add_undo_method(self, "selected_obj_set_single_normal", toolNormalDraw.get_normal())
			undoRedo.add_undo_method(self, "show_normal_type_tool")
			undoRedo.commit_action()
			print("Set auto type")

func _on_posDir_dir_changed(newDir):
	var obj = get_selected_obj()
	var pos = obj.get_dir_pos(newDir)
	toolPosDir.set_dir(newDir)
	var connectData = toolXEdit.get_signal_connection_list("value_changed")
	for i in connectData.size():
		toolXEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
	toolXEdit.value = pos.x
	for i in connectData.size():
		toolXEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
	connectData = toolYEdit.get_signal_connection_list("value_changed")
	for i in connectData.size():
		toolYEdit.disconnect("value_changed", connectData[i]["target"], connectData[i]["method"])
	toolYEdit.value = pos.y
	for i in connectData.size():
		toolYEdit.connect("value_changed", connectData[i]["target"], connectData[i]["method"], connectData[i]["binds"], connectData[i]["flags"])
