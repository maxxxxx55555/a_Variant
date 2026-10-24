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

static func humanoid(parent: Node3D, color: Color, armored: bool = false, armed: bool = true) -> Node3D:
	var visual := Node3D.new()
	visual.name = "MarchFigure"
	parent.add_child(visual)
	var torso := CylinderMesh.new()
	torso.top_radius = 0.29
	torso.bottom_radius = 0.34
	torso.height = 0.7
	torso.radial_segments = 6
	var coat := shape(visual, torso, Vector3(0, 0.98, 0), color)
	coat.scale.z = 0.65
	box(visual, Vector3(0, 0.69, 0), Vector3(0.64, 0.09, 0.4), Color("44382a"))
	box(visual, Vector3(0, 0.69, -0.22), Vector3(0.12, 0.09, 0.04), Color("c4a46a"))
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.name = "LegLeft" if side < 0 else "LegRight"
		leg.position = Vector3(side * 0.17, 0.62, 0)
		visual.add_child(leg)
		box(leg, Vector3(0, -0.29, 0), Vector3(0.21, 0.55, 0.23), Color("403f39"))
		box(leg, Vector3(0, -0.54, -0.06), Vector3(0.24, 0.18, 0.35), Color("342c27"))
		var arm := Node3D.new()
		arm.name = "ArmLeft" if side < 0 else "ArmRight"
		arm.position = Vector3(side * 0.4, 1.26, 0)
		visual.add_child(arm)
		box(arm, Vector3(0, -0.2, 0), Vector3(0.2, 0.43, 0.23), color.darkened(0.12))
		box(arm, Vector3(0, -0.48, 0), Vector3(0.16, 0.15, 0.18), Color("bc9474"))
	var head := SphereMesh.new()
	head.radius = 0.21
	head.height = 0.43
	head.radial_segments = 8
	head.rings = 4
	shape(visual, head, Vector3(0, 1.6, 0), Color("bc9474"))
	box(visual, Vector3(0, 1.78, 0.025), Vector3(0.36, 0.12, 0.33), Color("51422f"))
	for side in [-1, 1]: box(visual, Vector3(side * 0.08, 1.63, -0.186), Vector3(0.045, 0.045, 0.025), Color("303532"))
	if armored:
		box(visual, Vector3(0, 1.77, 0), Vector3(0.46, 0.2, 0.43), Color("717b7d"))
		box(visual, Vector3(-0.48, 1.0, -0.19), Vector3(0.07, 0.67, 0.48), color.darkened(0.1))
	if armed:
		var hand := visual.get_node("ArmRight") as Node3D
		box(hand, Vector3(0, -0.26, -0.3), Vector3(0.065, 0.76, 0.09), Color("b7bcb6"))
		box(hand, Vector3(0, -0.52, -0.3), Vector3(0.27, 0.065, 0.1), Color("9f824d"))
	return visual

static func animate_walk(visual: Node3D, phase: float, strength: float) -> void:
	for limb in ["LegLeft", "LegRight", "ArmLeft", "ArmRight"]:
		var pivot := visual.get_node_or_null(limb) as Node3D
		if pivot:
			var direction := -1.0 if limb in ["LegLeft", "ArmRight"] else 1.0
			pivot.rotation.x = sin(phase) * strength * direction

static func market(parent: Node3D, position: Vector3, tint: Color) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	box(root, Vector3(0, 0.8, 0), Vector3(3.5, 0.15, 1.2), Color("6a553b"))
	for side in [-1, 1]: box(root, Vector3(side * 1.55, 1.35, 0.4), Vector3(0.12, 2.7, 0.12), Color("594a35"))
	box(root, Vector3(0, 2.7, 0), Vector3(3.9, 0.1, 1.8), tint)
	for index in 4:
		box(root, Vector3(index * 0.75 - 1.12, 1, 0), Vector3(0.6, 0.3, 0.6), Color("b6a16d").darkened(index * 0.05))

static func well(parent: Node3D, position: Vector3) -> void:
	var rim := CylinderMesh.new()
	rim.top_radius = 0.9
	rim.bottom_radius = 1
	rim.height = 0.65
	rim.radial_segments = 10
	shape(parent, rim, position + Vector3(0, 0.32, 0), Color("7f887a"))
	var water := CylinderMesh.new()
	water.top_radius = 0.68
	water.bottom_radius = 0.68
	water.height = 0.02
	water.radial_segments = 10
	shape(parent, water, position + Vector3(0, 0.66, 0), Color("344e51"))
	for side in [-1, 1]: box(parent, position + Vector3(side * 0.9, 1.25, 0), Vector3(0.14, 2.5, 0.14), Color("5c4e3b"))
	box(parent, position + Vector3(0, 2.35, 0), Vector3(2.4, 0.16, 1.7), Color("5b665d"))

static func house(parent: Node3D, position: Vector3, tint: Color) -> Node3D:
	var house_root := Node3D.new()
	house_root.position = position
	parent.add_child(house_root)
	var key := tint.to_html()
	if house_templates.has(key):
		for data in house_templates[key]:
			var mesh := MeshInstance3D.new()
			mesh.mesh = data.mesh
			mesh.material_override = data.material
			mesh.visibility_range_end = 280
			mesh.visibility_range_end_margin = 35
			house_root.add_child(mesh)
		var body := StaticBody3D.new()
		body.position.y = 1.7
		body.set_meta("surface", "wood")
		house_root.add_child(body)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.2, 3.4, 5.5)
		collision.shape = shape
		body.add_child(collision)
		return house_root
	box(house_root, Vector3(0, 1.7, 0), Vector3(4.2, 3.4, 5.5), tint, true)
	var roof := PrismMesh.new()
	roof.size = Vector3(5, 2.1, 6.3)
	shape(house_root, roof, Vector3(0, 4.1, 0), Color("5c4942"))
	for side in [-1, 1]:
		box(house_root, Vector3(side * 2, 1.65, -2.79), Vector3(0.16, 3.5, 0.14), Color("43392d"))
		var window := box(house_root, Vector3(side * 1.2, 2, -2.82), Vector3(0.6, 0.85, 0.07), Color("deb878")) as MeshInstance3D
		window.material_override = material(Color("deb878"), 0.3)
	box(house_root, Vector3(0, 1.0, -2.83), Vector3(0.95, 2, 0.12), Color("51402e"))
	# Both approaches have readable doors, windows and timber framing.
	for side in [-1, 1]:
		box(house_root, Vector3(side * 2, 1.65, 2.79), Vector3(0.16, 3.5, 0.14), Color("43392d"))
		box(house_root, Vector3(side * 1.2, 2, 2.82), Vector3(0.6, 0.85, 0.07), Color("b5ba9e"))
		box(house_root, Vector3(side * 1.2, 2, 2.88), Vector3(0.07, 0.9, 0.06), Color("4b4434"))
	box(house_root, Vector3(0, 1, 2.83), Vector3(0.95, 2, 0.12), Color("51402e"))
	box(house_root, Vector3(0, 0.22, 0), Vector3(4.35, 0.44, 5.65), Color("7a7e6c"))
	for height in [0.8, 2.8]: box(house_root, Vector3(0, height, 2.82), Vector3(4.2, 0.12, 0.12), Color("594b36"))
	box(house_root, Vector3(1.1, 4.9, 0.8), Vector3(0.65, 2, 0.65), Color("777268"))
	# Joined timber, shutters, stone courses and roof battens give buildings
	# readable construction detail. Meshes are merged below to keep towns cheap.
	for front in [-1, 1]:
		var z: float = front * 2.91
		for height in [0.8, 2.8, 3.35]:
			box(house_root, Vector3(0, height, z), Vector3(4.25, 0.13, 0.13), Color("493b2c"))
		for side in [-1, 1]:
			for offset in [-0.4, 0.4]:
				box(house_root, Vector3(side * 1.2 + offset, 2, z), Vector3(0.18, 0.95, 0.12), Color("486256"))
			box(house_root, Vector3(side * 1.2, 2, z + front * 0.015), Vector3(0.65, 0.07, 0.08), Color("463b2d"))
			box(house_root, Vector3(side * 1.2, 2, z + front * 0.015), Vector3(0.06, 0.9, 0.08), Color("463b2d"))
			var beam := box(house_root, Vector3(side * 1.0, 3.94, front * 2.8), Vector3(2.6, 0.13, 0.13), Color("493b2c"))
			beam.rotation.z = side * -0.61
		for plank in 5:
			box(house_root, Vector3(plank * 0.18 - 0.36, 1.0, z + front * 0.025), Vector3(0.025, 1.9, 0.03), Color("382d24"))
		box(house_root, Vector3(0.29, 1, z + front * 0.09), Vector3(0.09, 0.1, 0.05), Color("d1b276"))
		box(house_root, Vector3(0, 0.12, front * 3.15), Vector3(1.5, 0.24, 0.6), Color("86847a"))
		for brick in 7:
			box(house_root, Vector3(brick * 0.61 - 1.83, 0.24, front * 2.88), Vector3(0.55, 0.27, 0.08), Color("a09b85").darkened((brick % 3) * 0.08))
	for side in [-1, 1]:
		for height in [0.8, 2.8]: box(house_root, Vector3(side * 2.14, height, 0), Vector3(0.12, 0.12, 5.5), Color("594b36"))
		for index in 6:
			var batten := box(house_root, Vector3(side * 1.25, 4.1, index * 1.1 - 2.75), Vector3(3.0, 0.065, 0.08), Color("76594a"))
			batten.rotation.z = side * -0.61
	merge_static_meshes(house_root)
	var template: Array = []
	for child in house_root.get_children():
		if child is MeshInstance3D: template.append({"mesh": child.mesh, "material": child.material_override})
	house_templates[key] = template
	return house_root

static func merge_static_meshes(parent: Node3D) -> void:
	var groups: Dictionary = {}
	for child in parent.get_children():
		if child is not MeshInstance3D: continue
		var mat: StandardMaterial3D = child.material_override
		var key := mat.albedo_color.to_html() + str(mat.emission_enabled)
		if not groups.has(key): groups[key] = {"tool": SurfaceTool.new(), "material": mat}
		groups[key].tool.append_from(child.mesh, 0, child.transform)
		child.free()
	for data in groups.values():
		var combined := MeshInstance3D.new()
		combined.mesh = data.tool.commit()
		combined.material_override = data.material
		combined.visibility_range_end = 280
		combined.visibility_range_end_margin = 35
		parent.add_child(combined)

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
