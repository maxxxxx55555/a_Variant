extends Node3D

const SLASH_DURATION: float = 0.32

var blade: Node3D
var slash: float = 0.0
var recoil: float = 0.0
var weapon_kind: String = ""
var current_path: String = ""

func _ready() -> void:
	position = Vector3(0.43, -0.52, -0.82)
	scale = Vector3.ONE * 0.72
	blade = Node3D.new()
	add_child(blade)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.equipment_updated.connect(refresh)
	refresh()

func refresh() -> void:
	visible = GameState.equipment.weapon != null
	if not visible:
		current_path = ""
		return
	var weapon:Dictionary=GameState.equipment.weapon
	var path:String=weapon.get("resource_path","")
	if path == current_path: return
	current_path = path
	weapon_kind = "sword"
	for kind:String in ["bow", "axe", "spear", "mace", "dagger"]:
		if kind in path: weapon_kind = kind
	for child:Node in blade.get_children(): child.free()
	var authored:Dictionary[String,String] = {"sword":"sword_1handed", "axe":"axe_1handed", "dagger":"dagger"}
	if authored.has(weapon_kind):
		var length:float= 0.64 if weapon_kind == "dagger" else 1.15
		var model:MeshInstance3D= MarchAssets.place(blade, "weapons/" + authored[weapon_kind] + ".gltf", Vector3(0,-0.35,0), Vector3(0.32,length,0.12))
		var steel_material:StandardMaterial3D= StandardMaterial3D.new()
		steel_material.albedo_color = Color("85949b")
		steel_material.metallic = 0.88
		steel_material.roughness = 0.28
		if weapon_kind!="sword":
			model.material_override = steel_material
			# The generated mesh is attached to its parent; no separate handle is needed here.
			@warning_ignore("return_value_discarded")
			RealWorldArt.box(blade,Vector3(0,-0.24,0),Vector3(0.055,0.22,0.06),"wood")
		return
	var steel:Color= Color("b6c2c5")
	var wood:Color= Color("6d4c31")
	var brass:Color= Color("a68d55")
	if weapon_kind == "bow":
		for side:int in [-1, 1]:
			var limb:Node3D= MarchArt.box(blade, Vector3(0.05, side * 0.27, 0), Vector3(0.06, 0.6, 0.07), wood)
			limb.rotation.z = side * 0.25
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(-0.02, 0, 0), Vector3(0.008, 1.1, 0.008), Color("d8ceb0"))
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0, -0.15), Vector3(0.02, 0.02, 0.75), wood)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0, -0.55), Vector3(0.05, 0.05, 0.12), steel)
	elif weapon_kind == "axe":
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0.12, 0), Vector3(0.07, 0.95, 0.08), wood)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0.09, 0.5, 0), Vector3(0.38, 0.32, 0.075), steel)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0.28, 0.5, 0), Vector3(0.05, 0.4, 0.04), Color("e1e6e4"))
	elif weapon_kind == "mace":
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0.12, 0), Vector3(0.08, 0.85, 0.08), wood)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0.5, 0), Vector3(0.22, 0.28, 0.22), steel)
		for i:int in 4:
			var tooth:Node3D= MarchArt.box(blade, Vector3(0, 0.5, 0), Vector3(0.32, 0.23, 0.04), steel)
			tooth.rotation.y = i * PI / 4
	elif weapon_kind == "spear":
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0.08, 0), Vector3(0.055, 1.6, 0.055), wood)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, 0.96, 0), Vector3(0.08, 0.38, 0.025), steel)
	else:
		var length:float= 0.45 if weapon_kind == "dagger" else 0.85
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, length * 0.5 - 0.12, 0), Vector3(0.055, length, 0.1), steel)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, -0.1, 0), Vector3(0.3, 0.055, 0.16), brass)
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(blade, Vector3(0, -0.25, 0), Vector3(0.08, 0.3, 0.08), wood)
	# The generated mesh is attached to its parent; no separate handle is needed here.
	@warning_ignore("return_value_discarded")
	MarchArt.box(blade, Vector3(0.04, -0.29, 0.09), Vector3(0.14, 0.17, 0.2), Color("b38c69"))

func attack() -> void:
	slash = SLASH_DURATION

func hit() -> void:
	recoil = 1.0

func _process(delta: float) -> void:
	slash = maxf(0, slash - delta)
	recoil = maxf(0, recoil - delta * 6.0)
	var progress:float= 1.0 - slash / SLASH_DURATION
	var arc:float= 0.0
	if slash > 0.0:
		if progress < 0.18:
			arc = -0.3 * (progress / 0.18)
		else:
			var strike:float= clampf((progress - 0.18) / 0.62, 0.0, 1.0)
			arc = lerpf(-0.3, 1.0, ease(strike, -2.6))
			if progress > 0.8:
				arc = lerpf(arc, 0.0, (progress - 0.8) / 0.2)
	arc = maxf(-0.4, arc + recoil * 0.16)
	blade.rotation = Vector3(-arc * 1.2, arc * -0.8, -arc * 0.7)
	if weapon_kind == "bow":
		blade.rotation = Vector3.ZERO
		blade.position.z = maxf(0.0, arc) * 0.16 + recoil * 0.05
	else:
		blade.position.z = recoil * 0.035
	if Input.is_action_pressed("block"):
		blade.rotation = Vector3(-0.3, 0, 0.9)
