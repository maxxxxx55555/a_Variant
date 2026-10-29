extends Control

var target: Vector3 = Vector3.ZERO
var active: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(_delta: float) -> void:
	if active:
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, 27.0, Color(0.03, 0.05, 0.06, 0.55))
	draw_arc(center, 27.0, 0.0, TAU, 36, Color(0.72, 0.66, 0.45, 0.75), 2.0)
	draw_line(center + Vector2(0, -30), center + Vector2(0, -24), Color(0.78, 0.82, 0.84, 0.7), 2.0)
	if not active:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var actor: Node3D = players[0] as Node3D
	if not is_instance_valid(actor):
		return
	var delta: Vector3 = target - actor.global_position
	var yaw: float = actor.rotation.y
	var right: float = delta.x * cos(yaw) - delta.z * sin(yaw)
	var forward: float = -delta.x * sin(yaw) - delta.z * cos(yaw)
	var angle: float = atan2(right, forward)
	draw_set_transform(center, angle, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(11, 13), Vector2(0, 6), Vector2(-11, 13)]), Color("e7d5a4"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
