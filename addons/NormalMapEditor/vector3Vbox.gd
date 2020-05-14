tool
extends VBoxContainer

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			var base = get_color("accent_color", "Editor")
			var labels = [ $xHbox/xLabel, $yHbox/yLabel, $zHbox/zLabel ]
			for i in 3:
				var c = base
				c = c.from_hsv(float(i) / 3.0 + 0.05, base.s * 0.75, base.v)
				labels[i].set("custom_colors/font_color", c)
			update()

func _draw():
	var labels = [ $xHbox/xLabel, $yHbox/yLabel, $zHbox/zLabel ]
	for i in 3:
		draw_rect(Rect2(labels[i].get_global_rect().position - get_global_rect().position, labels[i].get_global_rect().size), get_color("dark_color_3", "Editor"))



