extends Control
## Original vector illustration for the title screen; scales to any viewport.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(1920, 1080))
	draw_rect(Rect2(0, 0, 1920, 1080), Color("172e30"))
	for i in 240:
		var t := i / 239.0
		draw_rect(Rect2(700, i * 4, 1220, 5), Color("709da0").lerp(Color("efd6a6"), t))
	draw_circle(Vector2(1540, 260), 89, Color("f3ddb0"))
	for layer in 3:
		var points := PackedVector2Array([Vector2(700, 1080), Vector2(700, 570 + layer * 120)])
		for i in 17: points.append(Vector2(700 + i * 80, 480 + layer * 130 - sin(i * 1.8 + layer * 0.7) * (105 - layer * 15)))
		points.append(Vector2(1920, 1080))
		draw_colored_polygon(points, [Color("648b87"), Color("426b64"), Color("284d42")][layer])
	# The keep and road lead into the same frontier depicted in the campaign.
	draw_colored_polygon(PackedVector2Array([Vector2(960,1080), Vector2(1440,660), Vector2(1485,660), Vector2(1300,1080)]), Color("a99b72"))
	for i in 3:
		var x := 1390.0 + i * 65
		draw_rect(Rect2(x, 550 - (i % 2) * 50, 51, 135 + (i % 2) * 50), Color("c3b99b"))
		for tooth in 3: draw_rect(Rect2(x + tooth * 19, 538 - (i % 2) * 50, 13, 16), Color("d2c7a6"))
		for window in 2: draw_rect(Rect2(x + 20, 575 + window * 45, 10, 20), Color("324f48"))
	for i in 21:
		var x := 820.0 + i * 58
		var y := 830.0 + sin(i * 2.3) * 110
		var h := 80.0 + fmod(i * 31.0, 100.0)
		draw_rect(Rect2(x - 4, y - h * 0.4, 8, h * 0.55), Color("2e4334"))
		draw_colored_polygon(PackedVector2Array([Vector2(x,y-h), Vector2(x-40,y), Vector2(x+40,y)]), Color("193d32"))
	draw_rect(Rect2(0, 0, 780, 1080), Color("132b29"))
	draw_line(Vector2(780, 0), Vector2(780, 1080), Color("b7a171"), 2)
	for i in 6: draw_circle(Vector2(780, 90 + i * 180), 4, Color("d1b983"))
