extends Control

signal town_selected(id: String)
var selected: String = "greenhaven"

func _ready() -> void:
	custom_minimum_size = Vector2(650, 480)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	CampaignSystem.changed.connect(queue_redraw)

func map_position(x: float, z: float) -> Vector2:
	return Vector2((x / 4000.0 + 0.5) * (size.x - 60) + 30, (z / 4000.0 + 0.5) * (size.y - 60) + 30)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("273438"))
	for index in 9:
		var point: float = index / 8.0
		draw_line(Vector2(point * size.x, 0), Vector2(point * size.x, size.y), Color(0.55, 0.6, 0.55, 0.1))
		draw_line(Vector2(0, point * size.y), Vector2(size.x, point * size.y), Color(0.55, 0.6, 0.55, 0.1))
	var previous := map_position(0, 0)
	for data in CampaignSystem.definition.towns:
		var point := map_position(data.x, data.z)
		draw_line(previous, point, Color("747561"), 2)
		previous = point
	for point in CampaignSystem.definition.points:
		if point.id in CampaignSystem.explored:
			draw_circle(map_position(point.x, point.z), 3, Color("a6b294"))
	for data in CampaignSystem.definition.towns:
		var point := map_position(data.x, data.z)
		var color := Color("d7bc81") if data.id in CampaignSystem.roads else Color("6e7c7d")
		draw_circle(point, 6, color)
		if data.id == selected:
			draw_arc(point, 10, 0, TAU, 24, Color("e7d5a4"), 2)
		draw_string(ThemeDB.fallback_font, point + Vector2(10, -8), LocalizationManager.get_string(data.name), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var position: Vector3 = players[0].global_position
		draw_circle(map_position(position.x, position.z), 4, Color("e7efed"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var nearest: float = 45
		for data in CampaignSystem.definition.towns:
			var distance: float = event.position.distance_to(map_position(data.x, data.z))
			if distance < nearest:
				selected = data.id
				nearest = distance
		town_selected.emit(selected)
		queue_redraw()
