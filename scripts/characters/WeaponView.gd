extends Node3D

var blade: Node3D
var slash: float = 0.0
var weapon_kind: String = ""
var current_path: String = ""

func _ready() -> void:
	position = Vector3(0.43, -0.52, -0.82)
	scale = Vector3.ONE * 0.72
	blade = Node3D.new()
	add_child(blade)
	EventBus.equipment_updated.connect(refresh)
	refresh()

func refresh() -> void:
	visible = GameState.equipment.weapon != null
	if not visible:
		current_path = ""
		return
	var path: String = GameState.equipment.weapon.get("resource_path", "")
	if path == current_path: return
	current_path = path
	weapon_kind = "sword"
	for kind in ["bow", "axe", "spear", "mace", "dagger"]:
		if kind in path: weapon_kind = kind
	for child in blade.get_children(): child.free()
	var authored: Dictionary = {"sword":"sword_1handed", "axe":"axe_1handed", "dagger":"dagger"}
	if authored.has(weapon_kind):
		var length := 0.64 if weapon_kind == "dagger" else 1.15
		MarchAssets.place(blade, "weapons/" + authored[weapon_kind] + ".gltf", Vector3(0,-0.35,0), Vector3(0.45,length,0.18))
		return
	var steel := Color("b6c2c5")
	var wood := Color("6d4c31")
	var brass := Color("a68d55")
	if weapon_kind == "bow":
		for side in [-1, 1]:
			var limb := MarchArt.box(blade, Vector3(0.05, side * 0.27, 0), Vector3(0.06, 0.6, 0.07), wood)
			limb.rotation.z = side * 0.25
		MarchArt.box(blade, Vector3(-0.02, 0, 0), Vector3(0.008, 1.1, 0.008), Color("d8ceb0"))
		MarchArt.box(blade, Vector3(0, 0, -0.15), Vector3(0.02, 0.02, 0.75), wood)
		MarchArt.box(blade, Vector3(0, 0, -0.55), Vector3(0.05, 0.05, 0.12), steel)
	elif weapon_kind == "axe":
		MarchArt.box(blade, Vector3(0, 0.12, 0), Vector3(0.07, 0.95, 0.08), wood)
		MarchArt.box(blade, Vector3(0.09, 0.5, 0), Vector3(0.38, 0.32, 0.075), steel)
		MarchArt.box(blade, Vector3(0.28, 0.5, 0), Vector3(0.05, 0.4, 0.04), Color("e1e6e4"))
	elif weapon_kind == "mace":
		MarchArt.box(blade, Vector3(0, 0.12, 0), Vector3(0.08, 0.85, 0.08), wood)
		MarchArt.box(blade, Vector3(0, 0.5, 0), Vector3(0.22, 0.28, 0.22), steel)
		for i in 4:
			var tooth := MarchArt.box(blade, Vector3(0, 0.5, 0), Vector3(0.32, 0.23, 0.04), steel)
			tooth.rotation.y = i * PI / 4
	elif weapon_kind == "spear":
		MarchArt.box(blade, Vector3(0, 0.08, 0), Vector3(0.055, 1.6, 0.055), wood)
		MarchArt.box(blade, Vector3(0, 0.96, 0), Vector3(0.08, 0.38, 0.025), steel)
	else:
		var length := 0.45 if weapon_kind == "dagger" else 0.85
		MarchArt.box(blade, Vector3(0, length * 0.5 - 0.12, 0), Vector3(0.055, length, 0.1), steel)
		MarchArt.box(blade, Vector3(0, -0.1, 0), Vector3(0.3, 0.055, 0.16), brass)
		MarchArt.box(blade, Vector3(0, -0.25, 0), Vector3(0.08, 0.3, 0.08), wood)
	MarchArt.box(blade, Vector3(0.04, -0.29, 0.09), Vector3(0.14, 0.17, 0.2), Color("b38c69"))

func attack() -> void:
	slash = 0.32

func _process(delta: float) -> void:
	slash = maxf(0, slash - delta)
	var arc := sin(slash / 0.32 * PI)
	blade.rotation = Vector3(-arc * 1.2, arc * -0.8, -arc * 0.7)
	if weapon_kind == "bow":
		blade.rotation = Vector3.ZERO
		blade.position.z = arc * 0.16
	else:
		blade.position.z = 0
	if Input.is_action_pressed("block"):
		blade.rotation = Vector3(-0.3, 0, 0.9)
