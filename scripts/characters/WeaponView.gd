extends Node3D

var blade: Node3D
var slash: float = 0.0

func _ready() -> void:
	position = Vector3(0.38, -0.42, -0.65)
	blade = Node3D.new()
	add_child(blade)
	MarchArt.box(blade, Vector3(0, 0.28, 0), Vector3(0.055, 0.85, 0.1), Color("b6c2c5"))
	MarchArt.box(blade, Vector3(0, -0.1, 0), Vector3(0.3, 0.055, 0.16), Color("a68d55"))
	MarchArt.box(blade, Vector3(0, -0.25, 0), Vector3(0.08, 0.3, 0.08), Color("52412e"))
	MarchArt.box(blade, Vector3(0.04, -0.29, 0.09), Vector3(0.14, 0.17, 0.2), Color("b38c69"))
	EventBus.equipment_updated.connect(refresh)
	refresh()

func refresh() -> void:
	visible = GameState.equipment.weapon != null

func attack() -> void:
	slash = 0.32

func _process(delta: float) -> void:
	slash = maxf(0, slash - delta)
	var arc := sin(slash / 0.32 * PI)
	blade.rotation = Vector3(-arc * 1.2, arc * -0.8, -arc * 0.7)
	if Input.is_action_pressed("block"):
		blade.rotation = Vector3(-0.3, 0, 0.9)
