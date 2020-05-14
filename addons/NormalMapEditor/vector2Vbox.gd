tool
extends VBoxContainer

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			var base = get_color("accent_color", "Editor")
			var labels = [ $xHbox/xLabel, $yHbox/yLabel ]
			for i in 2:
				var c = base
				c = c.from_hsv(float(i) / 3.0 + 0.05, base.s * 0.75, base.v)
				labels[i].set("custom_colors/font_color", c)
			update()

func _draw():
	draw_rect(Rect2($xHbox/xLabel.get_global_rect().position - get_global_rect().position, $xHbox/xLabel.get_global_rect().size), get_color("dark_color_3", "Editor"))
	draw_rect(Rect2($yHbox/yLabel.get_global_rect().position - get_global_rect().position, $yHbox/yLabel.get_global_rect().size), get_color("dark_color_3", "Editor"))


func get_vector() -> Vector2:
	return Vector2($xHbox/LineEdit.value, $yHbox/LineEdit.value)


func set_vector(p_vec:Vector2):
	$xHbox/LineEdit.value = p_vec.x
	$yHbox/LineEdit.value = p_vec.y
