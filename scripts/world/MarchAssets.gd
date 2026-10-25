class_name MarchAssets
extends RefCounted
## Shared, normalized creator meshes. Collision stays owned by gameplay.
static var cache: Dictionary = {}
static var figure_materials: Dictionary = {}
static func collect(node: Node3D, transform: Transform3D, parts: Array) -> void:
	var local := transform * node.transform
	if node is MeshInstance3D: parts.append({"mesh": node.mesh, "transform": local})
	for child in node.get_children():
		if child is Node3D: collect(child, local, parts)
static func mesh(path: String, footprint: Vector3) -> ArrayMesh:
	if path=="weapons/sword_1handed.gltf": return preload("res://scripts/world/DetailedWeapons.gd").sword(footprint)
	var key := path + str(footprint)
	if cache.has(key): return cache[key]
	var scene: Node3D = load("res://assets/art/" + path).instantiate()
	var parts: Array = []
	collect(scene, Transform3D.IDENTITY, parts)
	var bounds := AABB()
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if bounds.size.length() == 0 else bounds.merge(box)
	var factor := minf(footprint.x / bounds.size.x, minf(footprint.y / bounds.size.y, footprint.z / bounds.size.z))
	var normalization := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * factor), Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor)
	var combined := ArrayMesh.new()
	for part in parts:
		for surface in part.mesh.get_surface_count():
			var tool := SurfaceTool.new()
			tool.append_from(part.mesh, surface, normalization * part.transform)
			tool.set_material(part.mesh.surface_get_material(surface))
			tool.commit(combined)
	scene.free()
	cache[key] = combined
	return combined
static func place(parent: Node3D, path: String, position: Vector3, footprint: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh(path, footprint)
	instance.position = position
	instance.visibility_range_end = 300
	instance.visibility_range_end_margin = 40
	parent.add_child(instance)
	return instance
static func character(parent: Node3D, armored: bool, armed: bool, tint: Color = Color("8a897c")) -> Node3D:
	return load("res://scripts/world/DetailedFigure.gd").build(parent,armored,armed,tint)
