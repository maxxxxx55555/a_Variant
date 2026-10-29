extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var scenario:Node=load("res://tests/MechanicsRoute.gd").new()
	root.add_child(scenario)
