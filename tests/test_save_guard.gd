extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ",label)
func run() -> void:
	await process_frame
	var save: Node = root.get_node("SaveSystem")
	save.selected_slot = 0
	check(save.save_game({"hp":75,"inventory":[],"equipment":{}}),"First legitimate save succeeds")
	check(save.save_game({"hp":70,"inventory":[],"equipment":{}}),"Second legitimate save creates a backup")
	var file := FileAccess.open(save.SAVE_PATH,FileAccess.WRITE)
	file.store_string("{interrupted")
	file.close()
	check(save.load_slot(0).get("hp",0)==75,"Title slot zero recovers the same known-good backup as the pause menu")
	check(not save.save_game({"hp":75,"inventory":[{"resource_path":"user://external.tres"}],"equipment":{}}),"Untrusted resource references are rejected before they can be loaded")
	var state: Node = root.get_node("GameState")
	var before: int = state.inventory.size()
	check(not state.add_item(load("res://data/weapons/iron_sword.tres"),-5) and state.inventory.size()==before,"Negative item counts cannot enter inventory")
	check(not save.save_game({"hp":"broken"}),"Wrongly typed saved health is rejected")
	check(save.save_game({"hp":75,"inventory":[{"resource_path":"res://data/potions/healing_herb.tres","count":4}],"equipment":{}}),"Shipped crafting ingredients remain valid inventory items")
	check(not save.save_game({"world":{"pickups":[{"path":"user://external.tres","count":1}]}}),"World pickup resource references use the shipped resource allowlist")
	check(not save.save_game({"simulation":{"factions":{"fake":{"res_path":"user://external.tres"}}}}),"Faction resources cannot bypass the resource allowlist")
	check(save.save_game({"hp":80,"inventory":[],"equipment":{}}),"A legitimate save remains possible after rejected inputs")
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save.SAVE_PATH))
	var data: Dictionary = JSON.parse_string(payload.data)
	data.hp = 9999
	payload.data = JSON.stringify(data)
	payload.checksum = save.calculate_checksum(payload.data)
	file = FileAccess.open(save.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	check(save.load_game().get("hp",0)!=9999,"Recomputing the old public checksum does not forge the new authentication")
	var stamina: float = state.player_stamina
	check(not state.consume_stamina(-10) and state.player_stamina==stamina,"Negative stamina costs cannot grant stamina")
	print("SAVE GUARD RESULT: ","PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
