extends SceneTree
func _initialize() -> void: call_deferred("run")
func bounds(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var total := AABB()
	var world := transform * node.transform
	if node is MeshInstance3D: total = world * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var box := bounds(child, world)
			if box.size.length() > 0: total = box if total.size.length() == 0 else total.merge(box)
	return total
func run() -> void:
	for path in ["medieval/buildings/blue/building_home_A_blue.gltf", "medieval/buildings/blue/building_tavern_blue.gltf", "medieval/decoration/nature/tree_single_A.gltf", "medieval/decoration/nature/tree_single_B.gltf", "medieval/decoration/props/tent.gltf", "characters/Knight.glb"]:
		var model: Node3D = load("res://assets/art/"+path).instantiate()
		print(path, " ", bounds(model), " meshes ", model.find_children("*", "MeshInstance3D", true, false).size())
		if path.ends_with("Knight.glb"):
			for mesh in model.find_children("*", "MeshInstance3D", true, false): print(mesh.name, " ", mesh.visible)
		model.free()
	quit()
