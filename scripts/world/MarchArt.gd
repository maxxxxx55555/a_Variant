class_name MarchArt
extends RefCounted

static var house_templates: Dictionary = {}

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.92
	if glow > 0:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = glow
	return result

static func shape(parent: Node3D, mesh: Mesh, position: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = position
	instance.rotation = rotation
	instance.visibility_range_end = 280
	instance.visibility_range_end_margin = 35
	parent.add_child(instance)
	return instance

static func box(parent: Node3D, position: Vector3, size: Vector3, color: Color, solid: bool = false) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var result := shape(parent, mesh, position, color)
	if solid:
		var body := StaticBody3D.new()
		body.position = position
		body.set_meta("surface", "wood" if color.r > color.g else "stone")
		parent.add_child(body)
		var collider := CollisionShape3D.new()
		var collision := BoxShape3D.new()
		collision.size = size
		collider.shape = collision
		body.add_child(collider)
	return result

static func humanoid(parent: Node3D, _color: Color, armored: bool = false, armed: bool = true) -> Node3D:
	return MarchAssets.character(parent, armored, armed, _color)

static func animate_walk(visual:Node3D,_phase:float,strength:float,movement_speed:float=-1.0) -> void:
	var player:AnimationPlayer=visual.get_meta("animation_player",null)
	if not is_instance_valid(player):return
	if player.current_animation=="Attack" and player.is_playing():return
	var speed:float=0.96 if movement_speed<0 else movement_speed
	var clip:="Idle"
	if strength>0.03 and speed>0.03:
		clip="Running_A" if speed>4.2 else "Jogging_A" if speed>2.2 else "Walking_A"
	if player.current_animation!=clip:player.play(clip,0.18)
	# Reference speeds from the licensed source's in-place foot excursion.
	var reference:float={"Walking_A":0.96,"Jogging_A":2.51,"Running_A":3.29}.get(clip,1.0)
	player.speed_scale=clampf(speed/reference,0.1,2.5) if clip!="Idle" else 1.0

static func animate_attack(visual: Node3D) -> void:
	if is_instance_valid(visual) and visual.has_method("attack"): visual.attack()

static func market(parent: Node3D, position: Vector3, _tint: Color) -> void:
	RealWorldArt.market(parent,position)

static func well(parent: Node3D, position: Vector3) -> void:
	RealWorldArt.well(parent,position)

static func house(parent: Node3D, position: Vector3, tint: Color, building: String = "") -> Node3D:
	var house_root := Node3D.new()
	house_root.position = position
	house_root.set_meta("authored_asset", true)
	parent.add_child(house_root)
	var variant := ("home_a" if int(tint.r*100)%2==0 else "home_b") if building.is_empty() else building
	RealWorldArt.house(house_root,variant)
	var body := StaticBody3D.new()
	body.position.y = 1.7
	body.set_meta("surface", "wood")
	house_root.add_child(body)
	var collision := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = Vector3(4.2,3.4,5.5)
	collision.shape = collision_shape
	body.add_child(collision)
	return house_root

static func label(parent: Node3D, title: String, position: Vector3, color: Color = Color("e7d4a9")) -> Label3D:
	var label_node:Label3D=load("res://scripts/world/MarchWorldLabel.gd").new()
	label_node.text = title
	label_node.font = load("res://assets/fonts/GolosText.ttf")
	label_node.position = position
	label_node.font_size = 36
	label_node.pixel_size = 0.008
	label_node.modulate = color
	label_node.outline_size = 9
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.visibility_range_end = 45
	parent.add_child(label_node)
	return label_node

static func localized_label(parent:Node3D,key:String,position:Vector3,suffix:String="") -> Label3D:
	var sign:Label3D=label(parent,"",position)
	sign.set_meta("locale_key",key)
	sign.set_meta("locale_suffix",suffix)
	sign.call("refresh_copy")
	return sign
