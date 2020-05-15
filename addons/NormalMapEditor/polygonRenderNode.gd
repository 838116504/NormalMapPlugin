tool
extends Polygon2D

const singleNormalShader = preload("singleNormalShader.shader")
#const normalMapShader = preload("normalMapShader.shader")

# 向量类型
enum { NT_SINGLE, NT_AUTO }
var type
var data				# NT_SINGLE时是法線方向, NT_AUTO是数組 格式 = [ emboss_height, bump_height, blur, bump, with_distance, with_emboss ]
var sourceTex			# 原來的图片
var pos := Vector2.ZERO

func _init():
	type = NT_SINGLE
	material = ShaderMaterial.new()
	material.shader = singleNormalShader

func _ready():
	update()

func set_pos(p_pos):
	for i in polygon.size():
		polygon[i] += p_pos - pos
	pos = p_pos

func update():
	if not is_inside_tree():
		return
	if type == NT_AUTO:
		if get_child_count() == 0:
			if sourceTex == null:
				return
			var autoNormal = preload("autoNormal.tscn").instance()
			#var v = visible
			#hide()
			autoNormal.set_param(sourceTex, data)
			add_child(autoNormal)
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			yield(get_tree(), "idle_frame")
			texture = ImageTexture.new()
			texture.create_from_image(autoNormal.get_texture().get_data())
			#print("texture size: ", texture.get_size())
#			var array = []
#			array.resize(polygon.size())
#			for i in polygon.size():
#				array[i] = Vector2(polygon[i].x, polygon[i].y)
#			uv = PoolVector2Array(array)
#			for i in uv.size():
#				print("uv[%s] = %s" % [ str(i), str(uv[i])])
			remove_child(autoNormal)
			autoNormal.queue_free()
		else:
			get_child(0).set_param(sourceTex, data)

func set_normal_data(p_type, p_data):
	match p_type:
		NT_SINGLE:
			if type != p_type:
				material = ShaderMaterial.new()
				material.shader = singleNormalShader
				material.set_shader_param("normal", data)
			data = p_data
		NT_AUTO:
			if type != p_type:
				material = null
#			for i in p_data.size():
#				print("auto data[%s] = %s" % [str(i), str(p_data[i])])
			data = p_data.duplicate()
	type = p_type
	
	update()

func set_points(p_points):
	polygon = p_points
	for i in polygon.size():
		polygon[i] += pos

func insert_point(p_id:int, p_pos:Vector2):
	if p_id < 0 || p_id > polygon.size():
		return
	
	polygon.insert(p_id, p_pos + pos)


func move_point(p_id:int, p_to:Vector2):
	if p_id < 0 || p_id > polygon.size():
		return
	
	polygon[p_id] = p_to + pos

func delete_point(p_id:int):
	if p_id < 0 || p_id > polygon.size():
		return
	
	polygon.remove(p_id)
