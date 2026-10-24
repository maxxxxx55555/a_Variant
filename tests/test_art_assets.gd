extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	var house := MarchArt.house(stage, Vector3.ZERO, Color("9d9276"))
	var actor := MarchArt.humanoid(stage, Color("bda171"), true)
	var imported: bool = house.has_meta("authored_asset")
	var animation := actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var animated: bool = animation != null and animation.has_animation("Walking_A") and animation.has_animation("Idle")
	MarchArt.animate_walk(actor, 1.0, 0.6)
	if animated: animated = animation.current_animation == "Walking_A"
	print("AUTHORED ART RESULT: ", "PASS" if imported and animated else "FAIL")
	quit(0 if imported and animated else 1)
