extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	var first := MarchArt.house(stage, Vector3(0,0,0), Color("9d9276"))
	var second := MarchArt.house(stage, Vector3(20,0,0), Color("9d9276"))
	var meshes_a := first.find_children("*", "MeshInstance3D", false, false)
	var meshes_b := second.find_children("*", "MeshInstance3D", false, false)
	var reused: bool = meshes_a[0].mesh == meshes_b[0].mesh
	var bodies := second.find_children("*", "StaticBody3D", false, false)
	var shape: BoxShape3D = bodies[0].get_child(0).shape
	var collision_ok: bool = bodies.size() == 1 and shape.size == Vector3(4.2,3.4,5.5) and bodies[0].position == Vector3(0,1.7,0)
	if not reused: print("FAIL: Identical town houses should reuse baked meshes instead of rebuilding GPU geometry")
	print("HOUSE CACHE RESULT: ", "PASS" if reused and collision_ok else "FAIL")
	quit(0 if reused and collision_ok else 1)
