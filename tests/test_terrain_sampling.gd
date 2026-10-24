extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1, false)
	var terrain: Node3D = load("res://scripts/world/MarchTerrain.gd").new()
	root.add_child(terrain)
	terrain.generate()
	var mesh: ArrayMesh = terrain.get_child(0).mesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ok := true
	for pair in [Vector2(-127, 43), Vector2(920, -1280), Vector2(-1500, 1000), Vector2(0, 0)]:
		var gx: float = (pair.x + terrain.width * 0.5) / terrain.step
		var gz: float = (pair.y + terrain.width * 0.5) / terrain.step
		var ix := int(gx)
		var iz := int(gz)
		var u := gx - ix
		var v := gz - iz
		var a := vertices[iz * 129 + ix].y
		var b := vertices[iz * 129 + ix + 1].y
		var c := vertices[(iz + 1) * 129 + ix].y
		var d := vertices[(iz + 1) * 129 + ix + 1].y
		var expected := a + (b-a)*u + (c-a)*v if u+v <= 1 else d+(c-d)*(1-u)+(b-d)*(1-v)
		ok = ok and absf(terrain.ground_at(pair.x, pair.y) - expected) < 0.0001
	print("TERRAIN SAMPLING RESULT: ", "PASS" if ok else "FAIL")
	quit(0 if ok else 1)
