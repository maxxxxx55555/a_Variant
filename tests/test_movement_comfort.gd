extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var player: CharacterBody3D = load("res://scenes/characters/player.tscn").instantiate()
	if not player.has_method("brake_horizontal"):
		print("FAIL: Player braking must accept elapsed time")
		player.free()
		quit(1)
		return
	var results: Array[float] = []
	for hz in [30, 120]:
		player.velocity = Vector3(5,0,0)
		for tick in int(hz * 0.1): player.brake_horizontal(1.0 / hz, 5.0)
		results.append(player.velocity.x)
	var equal := absf(results[0]-results[1]) < 0.001 and results[0] > 0 and results[0] < 5
	player.free()
	print("MOVEMENT COMFORT RESULT: ", "PASS" if equal else "FAIL")
	quit(0 if equal else 1)
