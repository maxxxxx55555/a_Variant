class_name MarchAssets
extends RefCounted
## Shared, normalized creator meshes. Collision stays owned by gameplay.
static var cache: Dictionary = {}
static var figure_materials: Dictionary = {}
static func collect(node: Node3D, transform: Transform3D, parts: Array) -> void:
	var local:Transform3D= transform * node.transform
	if node is MeshInstance3D: parts.append({"mesh": (node as MeshInstance3D).mesh, "transform": local})
	for child:Node in node.get_children():
		if child is Node3D: collect(child as Node3D, local, parts)
static func mesh(path: String, footprint: Vector3) -> ArrayMesh:
	if path=="weapons/sword_1handed.gltf": return preload("res://scripts/world/DetailedWeapons.gd").sword(footprint)
	var key:String= path + str(footprint)
	if cache.has(key): return cache[key]
	var scene_resource:PackedScene=load("res://assets/art/"+path) as PackedScene
	var scene:Node3D=scene_resource.instantiate()
	var parts: Array = []
	collect(scene, Transform3D.IDENTITY, parts)
	var bounds:AABB= AABB()
	for part:Dictionary in parts:
		var part_mesh:Mesh=part.mesh
		var part_transform:Transform3D=part.transform
		var box: AABB = part_transform*part_mesh.get_aabb()
		bounds = box if bounds.size.length() == 0 else bounds.merge(box)
	var factor:float= minf(footprint.x / bounds.size.x, minf(footprint.y / bounds.size.y, footprint.z / bounds.size.z))
	var normalization:Transform3D= Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * factor), Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor)
	var combined:ArrayMesh= ArrayMesh.new()
	for part:Dictionary in parts:
		var part_mesh:Mesh=part.mesh
		var part_transform:Transform3D=part.transform
		for surface:int in part_mesh.get_surface_count():
			var tool:SurfaceTool= SurfaceTool.new()
			tool.append_from(part_mesh,surface,normalization*part_transform)
			tool.set_material(part_mesh.surface_get_material(surface))
			# SurfaceTool appends to the explicit destination mesh supplied here.
			@warning_ignore("return_value_discarded")
			tool.commit(combined)
	scene.free()
	cache[key] = combined
	return combined
static func place(parent: Node3D, path: String, position: Vector3, footprint: Vector3) -> MeshInstance3D:
	var instance:MeshInstance3D= MeshInstance3D.new()
	instance.mesh = mesh(path, footprint)
	instance.position = position
	instance.visibility_range_end = 300
	instance.visibility_range_end_margin = 40
	parent.add_child(instance)
	return instance
static func character(parent: Node3D, armored: bool, armed: bool, tint: Color = Color("8a897c")) -> Node3D:
	# Runtime loading breaks the DetailedFigure -> MarchAssets weapon-factory dependency.
	@warning_ignore("unsafe_method_access")
	return load("res://scripts/world/DetailedFigure.gd").build(parent,armored,armed,tint)
