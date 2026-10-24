class_name MarchArt
extends RefCounted

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

static func humanoid(parent: Node3D, color: Color, armored: bool = false) -> Node3D:
	var visual := Node3D.new()
	visual.name = "MarchFigure"
	parent.add_child(visual)
	box(visual, Vector3(0, 1.02, 0), Vector3(0.62, 0.65, 0.34), color)
	box(visual, Vector3(0, 0.62, 0), Vector3(0.65, 0.22, 0.38), color.darkened(0.2))
	for side in [-1, 1]:
		box(visual, Vector3(side * 0.17, 0.29, 0), Vector3(0.22, 0.6, 0.24), Color("403f39"))
		box(visual, Vector3(side * 0.43, 0.95, 0), Vector3(0.2, 0.6, 0.23), color.darkened(0.12))
		box(visual, Vector3(side * 0.17, 0.08, -0.06), Vector3(0.24, 0.18, 0.35), Color("342c27"))
	var head := SphereMesh.new()
	head.radius = 0.21
	head.height = 0.43
	head.radial_segments = 8
	head.rings = 4
	shape(visual, head, Vector3(0, 1.6, 0), Color("bc9474"))
	if armored:
		box(visual, Vector3(0, 1.77, 0), Vector3(0.46, 0.2, 0.43), Color("717b7d"))
		box(visual, Vector3(-0.48, 1.0, -0.19), Vector3(0.07, 0.67, 0.48), color.darkened(0.1))
	box(visual, Vector3(0.46, 1.0, -0.38), Vector3(0.065, 0.76, 0.09), Color("b7bcb6"))
	box(visual, Vector3(0.46, 0.65, -0.38), Vector3(0.27, 0.065, 0.1), Color("9f824d"))
	return visual

static func house(parent: Node3D, position: Vector3, tint: Color) -> Node3D:
	var house_root := Node3D.new()
	house_root.position = position
	parent.add_child(house_root)
	box(house_root, Vector3(0, 1.7, 0), Vector3(4.2, 3.4, 5.5), tint, true)
	var roof := PrismMesh.new()
	roof.size = Vector3(5, 2.1, 6.3)
	shape(house_root, roof, Vector3(0, 4.1, 0), Color("5c4942"))
	for side in [-1, 1]:
		box(house_root, Vector3(side * 2, 1.65, -2.79), Vector3(0.16, 3.5, 0.14), Color("43392d"))
		var window := box(house_root, Vector3(side * 1.2, 2, -2.82), Vector3(0.6, 0.85, 0.07), Color("deb878")) as MeshInstance3D
		window.material_override = material(Color("deb878"), 0.3)
	box(house_root, Vector3(0, 1.0, -2.83), Vector3(0.95, 2, 0.12), Color("51402e"))
	box(house_root, Vector3(1.1, 4.9, 0.8), Vector3(0.65, 2, 0.65), Color("777268"))
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
