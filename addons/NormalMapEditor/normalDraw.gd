tool
extends Control

signal pressed

const HX := 0.05
const HY := 1.0/3.0 + 0.05
const HZ := 2.0/3.0 + 0.05

export(float) var arrow_len = 16

var quat := Quat(Vector3.ZERO)
var press := false


func _ready():
	update()

func _gui_input(event):
	if event is InputEventMouseButton && event.button_index == BUTTON_LEFT:
		if event.pressed:
			press = true
		else:
			if press:
				press = false
				emit_signal("pressed")

func set_normal(p_n:Vector3):
	if p_n == Vector3(0, 0, 1):
		quat = Quat(Vector3.ZERO)
		return
	var cross = p_n.cross(Vector3(0, 0, 1)).normalized()
	var cross2 = Vector3(0, 0, 1).cross(cross).normalized()
	if p_n.dot(cross2) >= 0:
		quat = Quat(cross, -p_n.angle_to(Vector3(0, 0, 1)))
	else:
		quat = Quat(cross, p_n.angle_to(Vector3(0, 0, 1)))
	update()

func get_normal() -> Vector3:
	return quat.xform(Vector3(0, 0, 1))

func get_quat():
	return quat

func set_quat(p_quat:Quat):
	quat = p_quat
	#print("euler: ", str(quat.get_euler()))
	update()

func set_euler(p_euler:Vector3):
	quat = Quat(p_euler)
	update()

func _draw():
	if quat == null:
		print("quat is null")
		return
	var radius = min(rect_size.x, rect_size.y) / 2
	var halfSize = radius * 0.6
	
	var center = rect_size / 2
	var points = [Vector2(-halfSize, -halfSize), Vector2(halfSize, -halfSize), Vector2(halfSize, halfSize), Vector2(-halfSize, halfSize)]
	var temp
	for i in points.size():
		temp = quat.xform(Vector3(points[i].x, points[i].y, 0))
		points[i] = Vector2(temp.x, temp.y) + center
	
	var fc = get_color("font_color", "LineEdit")
	# 背面画不同色
	if !Geometry.is_polygon_clockwise(points):
		fc = fc.from_hsv(fc.h, fc.s, fmod(fc.v + 0.5, 1.0))
	
	draw_polygon(points, [fc])
	
	var base = get_color("accent_color", "Editor")
	var arrowLen = radius * 0.8
	var normalVec = quat.xform(Vector3(0, 0, 1)).normalized()
	var targetVec = Vector2(normalVec.x * arrowLen, normalVec.y * arrowLen)
	draw_arrow(center, center + targetVec, base.from_hsv(HZ, base.s * 0.75, base.v), arrowLen)
	
	normalVec = quat.xform(Vector3(0, 1, 0)).normalized()
	targetVec = Vector2(normalVec.x * arrowLen, normalVec.y * arrowLen)
	draw_arrow(center, center + targetVec, base.from_hsv(HY, base.s * 0.75, base.v), arrowLen)
	
	normalVec = quat.xform(Vector3(1, 0, 0)).normalized()
	targetVec = Vector2(normalVec.x * arrowLen, normalVec.y * arrowLen)
	draw_arrow(center, center + targetVec, base.from_hsv(HX, base.s * 0.75, base.v), arrowLen)

func draw_arrow(p_from:Vector2, p_to:Vector2, p_color:Color, arrowLen:float):
	if p_from == p_to:
		draw_circle(p_to, 2.0, p_color)
		return
	var tf = p_from - p_to
	var length = tf.length() / arrowLen * arrow_len
	draw_line(p_from, p_to, p_color)
	draw_line(p_to, p_to + tf.rotated(PI/6).normalized() * length, p_color)
	draw_line(p_to, p_to + tf.rotated(-PI/6).normalized() * length, p_color)
