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
static func character(parent: Node3D, armored: bool, armed: bool) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "MarchFigure"
	parent.add_child(wrapper)
	var path := "Knight" if armored else "Rogue"
	var model: Node3D = load("res://assets/art/characters/" + path + ".glb").instantiate()
	model.scale = Vector3.ONE * 0.80
	# KayKit faces +Z; gameplay actors face -Z.
	model.rotation.y = PI
	wrapper.add_child(model)
	for part in model.find_children("*", "MeshInstance3D", true, false):
		for surface in part.mesh.get_surface_count():
			var original: Material = part.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var key: String=original.resource_path+str(armored)
				if not figure_materials.has(key):
					var fabric := ShaderMaterial.new()
					fabric.shader = preload("res://scripts/world/ClothedFigure.gdshader")
					fabric.set_shader_parameter("palette",original.albedo_texture)
					fabric.set_shader_parameter("armored",armored)
					figure_materials[key]=fabric
				part.set_surface_override_material(surface,figure_materials[key])
		var equipment: bool = "Sword" in part.name or "Shield" in part.name or "Dagger" in part.name or "Crossbow" in part.name or "Staff" in part.name or "Wand" in part.name
		if equipment: part.visible = armed and (part.name == "1H_Sword" if armored else part.name == "Dagger")
		part.visibility_range_end = 160
		part.visibility_range_end_margin = 25
	for skeleton in model.find_children("*","Skeleton3D",true,false):
		skeleton.add_child(preload("res://scripts/world/AdultProportions.gd").new())
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player:
		for clip in ["Idle", "Walking_A"]:
			if player.has_animation(clip): player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		player.play("Idle")
		wrapper.set_meta("animation_player", player)
	return wrapper
