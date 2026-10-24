extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var view: Node3D = load("res://scripts/characters/WeaponView.gd").new()
	root.add_child(view)
	var state: Node = root.get_node("GameState")
	var failed := false
	for pair in [["hunter_bow", "bow"], ["war_axe", "axe"], ["iron_spear", "spear"], ["mace", "mace"], ["dagger", "dagger"], ["iron_sword", "sword"]]:
		state.equipment.weapon = {"resource_path": "res://data/weapons/" + pair[0] + ".tres"}
		view.refresh()
		if view.get("weapon_kind") != pair[1]:
			print("FAIL: Equipped ", pair[0], " needs its own readable silhouette")
			failed = true
	state.equipment.weapon = null
	view.refresh()
	if view.visible: failed = true
	print("WEAPON VIEW RESULT: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
