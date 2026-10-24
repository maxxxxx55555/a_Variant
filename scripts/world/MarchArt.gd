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
	return MarchAssets.character(parent, armored, armed)

static func animate_walk(visual: Node3D, _phase: float, strength: float) -> void:
	var player: AnimationPlayer = visual.get_meta("animation_player", null)
	if not is_instance_valid(player): return
	var clip := "Walking_A" if strength > 0.03 else "Idle"
	if player.current_animation != clip: player.play(clip, 0.18)

static func market(parent: Node3D, position: Vector3, _tint: Color) -> void:
	MarchAssets.place(parent, "medieval/buildings/blue/building_market_blue.gltf", position, Vector3(4.5,4,3.5))

static func well(parent: Node3D, position: Vector3) -> void:
	MarchAssets.place(parent, "medieval/buildings/blue/building_well_blue.gltf", position, Vector3(2.4,3,2.4))

static func house(parent: Node3D, position: Vector3, tint: Color, building: String = "") -> Node3D:
	var house_root := Node3D.new()
	house_root.position = position
	house_root.set_meta("authored_asset", true)
	parent.add_child(house_root)
	var variant := "A" if int(tint.r * 100) % 2 == 0 else "B"
	var file := "building_home_" + variant + "_blue" if building.is_empty() else "building_" + building + "_blue"
	MarchAssets.place(house_root, "medieval/buildings/blue/" + file + ".gltf", Vector3.ZERO, Vector3(4.2,5.8,5.5))
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
	var label_node := Label3D.new()
	label_node.text = title
	label_node.position = position
	label_node.font_size = 48
	label_node.pixel_size = 0.008
	label_node.modulate = color
	label_node.outline_size = 9
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.visibility_range_end = 80
	parent.add_child(label_node)
	return label_node
