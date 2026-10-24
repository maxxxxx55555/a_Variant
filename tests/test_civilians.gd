extends SceneTree

var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var source := "res://scripts/ai/CivilianActor.gd"
	check(FileAccess.file_exists(source), "Towns have residents with real routines")
	if not FileAccess.file_exists(source):
		quit(1)
		return
	var actor: Node3D = load(source).new()
	actor.home = Vector3(-10, 0, 0)
	actor.workplace = Vector3(-10, 0, 12)
	actor.plaza = Vector3(-20, 0, 5)
	root.add_child(actor)
	check(actor.schedule_target(0.1) == actor.home, "Residents return home at night")
	check(actor.schedule_target(0.45) == actor.workplace, "Residents work by day")
	check(actor.schedule_target(0.8) == actor.plaza, "Residents gather after work")
	check(actor.threat_destination(Vector3(0, 0, -4)).distance_to(Vector3(0, 0, -4)) > actor.position.distance_to(Vector3(0, 0, -4)), "Civilians flee away from nearby combat")
	check(not actor.is_in_group("enemies") and not actor.is_in_group("allies"), "Civilians do not replace combatants or quest access")
	actor.queue_free()
	await process_frame
	print("CIVILIAN RESULT: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
