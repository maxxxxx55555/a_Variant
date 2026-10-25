extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var view: Node3D = load("res://scripts/characters/WeaponView.gd").new()
	root.add_child(view)
	root.get_node("GameState").equipment.weapon={"resource_path":"res://data/weapons/iron_sword.tres"}
	view.refresh()
	var surfaces:=0
	var materials: Array = []
	for mesh in view.blade.find_children("*","MeshInstance3D",true,false):
		for index in mesh.mesh.get_surface_count():
			surfaces+=1
			var mat: Material=mesh.get_active_material(index)
			if mat not in materials: materials.append(mat)
	var ok: bool=surfaces>=3 and materials.size()>=3
	var model: MeshInstance3D=view.blade.get_child(0)
	var data: Array=model.mesh.surface_get_arrays(0)
	var normal: Vector3=data[Mesh.ARRAY_NORMAL][0]
	var point: Vector3=data[Mesh.ARRAY_VERTEX][0]
	ok=ok and normal.dot(Vector3(point.x,0,point.z))>0
	print("WEAPON DETAIL RESULT: ","PASS" if ok else "FAIL: steel, leather and fittings need distinct visible materials")
	quit(0 if ok else 1)
