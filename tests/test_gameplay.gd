extends SceneTree

var failures: Array[String] = []
var state: Node
var world: Node3D
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)

func run() -> void:
	await process_frame
	state = root.get_node("GameState")
	world = load("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame
	check(world.has_method("get_objective_state"), "The test expedition has visible, completable objectives")
	for button in [world.hud.inventory_btn, world.hud.town_btn, world.hud.alchemy_btn]:
		check(button.get_global_rect().position.x >= 0, "HUD button remains inside the game viewport")
	if OS.get_cmdline_user_args().has("--playthrough"):
		await playthrough()
		finish()
		return
	var save: Node = root.get_node("SaveSystem")
	save.save_game({"hp": 75, "inventory": [], "equipment": {}})
	check(save.load_game().get("hp") == 75, "Save data round-trips")
	var file = FileAccess.open(save.SAVE_PATH, FileAccess.READ)
	var payload = JSON.parse_string(file.get_as_text())
	file.close()
	payload["data"]["hp"] = 9999
	file = FileAccess.open(save.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()
	check(save.load_game().get("hp", 0) != 9999, "Changed save checksum must be rejected")
	for path in [save.SAVE_PATH, save.BACKUP_PATH]:
		file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string("{broken")
		file.close()
	check(save.load_game().is_empty(), "Two corrupt saves fail safely without recursive backup loading")
	var pop: Node = root.get_node("PopulationSystem")
	check(pop.available_workers == 5, "Initial worker count equals unassigned population")
	var old_jobs: Dictionary = pop.jobs.duplicate()
	pop.update_worker_assignments({"farmers": -5})
	check(pop.jobs == old_jobs, "Negative worker assignment is rejected")
	var economy: Node = root.get_node("EconomySystem")
	var settlement: Node = root.get_node("SettlementSystem")
	settlement.set_law("taxes", "nonsense")
	check(settlement.current_laws.taxes == "normal", "Unknown law value is rejected")
	settlement.set_law("rations", "half")
	economy.stockpiles.food = 150
	economy._on_day_passed(2)
	check(economy.stockpiles.food == 157.5, "Half rations change actual food consumption")
	settlement.set_law("rations", "full")
	economy.stockpiles.food = 150
	check(economy.get_food_days_remaining() == 30, "Food forecast uses net production and consumption")
	var health_before: float = pop.health
	economy.stockpiles.food = 0
	pop.jobs.farmers = 0
	economy._on_day_passed(3)
	check(pop.health < health_before, "Starvation affects settlement health")
	pop.jobs = old_jobs
	pop.total_population = 8
	pop.reconcile_workers()
	check(pop.available_workers >= 0, "Emigration leaves a valid number of workers")
	var total_jobs := 0
	for job in pop.jobs.values():
		total_jobs += job
	check(total_jobs <= 8, "Emigration cannot leave more workers than citizens")
	pop.total_population = 25
	pop.jobs = old_jobs
	pop.reconcile_workers()
	var town_ui: Control = world.settlement_ui
	check(town_ui.has_method("apply_jobs"), "Settlement has working profession controls")
	if town_ui.has_method("apply_jobs"):
		town_ui.refresh_ui()
		town_ui.worker_inputs.farmers.value = 10
		town_ui.apply_jobs()
		check(pop.jobs.farmers == 10, "Profession controls update the production workers")
		pop.jobs = old_jobs
		pop.reconcile_workers()
	world.toggle_inventory()
	var player: Node3D = world.player
	var origin: Vector3 = player.position
	Input.action_press("move_forward")
	for i in range(8):
		await physics_frame
	Input.action_release("move_forward")
	check(player.position.distance_to(origin) < 0.05, "Inventory blocks player movement")
	world.toggle_inventory()
	# Menu buttons must retain the same behavior as their keyboard equivalents.
	world.hud.inventory_btn.pressed.emit()
	check(world.inventory_ui.visible, "HUD inventory button opens inventory")
	world.toggle_inventory()
	check(world.has_method("toggle_alchemy"), "Alchemy has a reachable opening action")
	var pause: Control = world.pause_menu
	var saved_state: Dictionary = world.get_world_state()
	world.enemy.die()
	await process_frame
	world.load_world_state(saved_state)
	await process_frame
	check(is_instance_valid(world.enemy) and not world.enemy.is_dead, "Loading an earlier save restores a slain enemy")
	var hp_before: float = state.player_hp
	Input.action_press("block")
	world.player.take_damage(20)
	Input.action_release("block")
	check(hp_before - state.player_hp < 20, "Held block reduces incoming damage")
	world.toggle_pause()
	var day_before: int = root.get_node("TimeSystem").current_day
	var gold_before: float = economy.stockpiles.gold
	world.pause_menu._on_save()
	root.get_node("TimeSystem").current_day = 40
	economy.stockpiles.gold = 0
	world.pause_menu._on_load()
	check(world.hud.visible, "Loading and resuming restores the HUD")
	check(root.get_node("TimeSystem").current_day == day_before, "Save restores the settlement calendar")
	check(economy.stockpiles.gold == gold_before, "Save restores settlement resources")
	root.get_node("LocalizationManager").set_language("ru")
	check(world.hud.inventory_btn.text.contains("Инвентарь"), "HUD controls are localized into Russian")
	root.get_node("LocalizationManager").set_language("en")
	check(world.hud.inventory_btn.text.contains("Inventory"), "HUD switches language immediately")
	for bus in ["Music", "SFX", "UI"]:
		check(AudioServer.get_bus_index(bus) >= 0, "Volume slider controls a real audio bus: " + bus)
	var time: Node = root.get_node("TimeSystem")
	time.current_day = 6
	time.current_week = 1
	time.advance_day()
	check(time.current_week == 1, "A full seven-day week ends before week two begins")
	time.advance_day()
	check(time.current_week == 2, "Day eight starts week two")
	time.current_day = 27
	time.current_season_idx = 0
	time.advance_day()
	check(time.current_season_idx == 0, "Spring contains all 28 days")
	time.advance_day()
	check(time.current_season_idx == 1, "Day 29 starts summer")
	state.player_hp = 0
	state.take_damage(1)
	await process_frame
	check(get_tree_paused_or_dead_panel(), "Death presents a recovery screen and stops play")
	var gold_before_respawn: float = economy.stockpiles.gold
	state.equipment.torso = {"resource_path": "res://data/armors/leather_armor.tres", "durability": 100.0}
	world.restart_run()
	check(economy.stockpiles.gold == gold_before_respawn * 0.8, "Ordinary death respawns with the specified gold penalty")
	check(world.hud.visible, "Respawning restores the HUD")
	check(state.equipment.torso.durability == 80, "Respawn applies the specified equipment durability penalty")
	state.equipment.torso.durability = 0
	state.recalculate_stats()
	check(state.current_defense == 10, "Broken armor provides half of its original protection")
	check(state.has_method("repair_equipment"), "Worn equipment can be repaired in the settlement")
	if state.has_method("repair_equipment"):
		economy.stockpiles.gold = 100
		check(state.repair_equipment(), "Available gold can pay for a real repair")
		check(state.equipment.torso.durability == 100 and state.current_defense == 20, "Repair restores full armor protection")
		check(economy.stockpiles.gold == 75, "Repair charges its displayed price")
	state.player_hp = 100
	state.player_stamina = 20
	state.inventory.clear()
	state.add_item(load("res://data/potions/health_potion.tres"), 1)
	state.add_item(load("res://data/potions/stamina_potion.tres"), 1)
	world.player.use_quick_potion()
	check(state.player_stamina == 70, "Quick potion skips unusable healing potions and finds stamina recovery")
	get_root().get_tree().paused = false
	finish()

func finish() -> void:
	print("RESULT: ", "PASS" if failures.is_empty() else "FAIL", " (", checks, " checks, ", failures.size(), " failures)")
	quit(0 if failures.is_empty() else 1)

func get_tree_paused_or_dead_panel() -> bool:
	return paused

func action(name: String, frames: int = 1) -> void:
	Input.action_press(name)
	for i in range(frames):
		await physics_frame
	Input.action_release(name)
	await physics_frame

func screenshot(suffix: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png"))

func playthrough() -> void:
	await screenshot("start")
	world.toggle_inventory()
	world.inventory_ui._on_item_selected(0)
	world.inventory_ui.equip_button.pressed.emit()
	check(state.equipment.weapon != null, "Inventory button equips the starting sword")
	await screenshot("inventory")
	world.toggle_inventory()
	var player: Node3D = world.player
	# Pick up the world armor through the real interaction ray and E action.
	await action("move_right", 16)
	await action("move_forward", 16)
	player.camera.look_at(world.armor_pickup.global_position)
	await action("interact", 3)
	var armor_index := -1
	for i in range(state.inventory.size()):
		if state.inventory[i].resource_path.ends_with("leather_armor.tres"):
			armor_index = i
	check(armor_index >= 0, "E picks up armor from the world")
	if armor_index >= 0:
		world.toggle_inventory()
		world.inventory_ui._on_item_selected(armor_index)
		world.inventory_ui.equip_button.pressed.emit()
		world.toggle_inventory()
	# Walk into detection range and exchange real raycast attacks.
	player.camera.rotation.x = 0
	await action("move_forward", 95)
	var count := 0
	while is_instance_valid(world.enemy) and count < 600 and state.player_hp > 0:
		count += 1
		var enemy: Node3D = world.enemy
		player.look_at(Vector3(enemy.global_position.x, player.global_position.y, enemy.global_position.z))
		player.camera.look_at(enemy.global_position + Vector3(0, 0.9, 0))
		Input.action_press("block")
		await action("attack")
		Input.action_release("block")
	check(not is_instance_valid(world.enemy), "Normal movement and sword attacks defeat the enemy")
	check(state.player_hp > 0, "Player survives the fight")
	await screenshot("combat")
	var alchemy: Node = root.get_node("AlchemySystem")
	world.toggle_alchemy()
	var herbs_before := 0
	for item in state.inventory:
		if item.resource_path.ends_with("healing_herb.tres"):
			herbs_before += item.count
	world.alchemy_ui.brew_button.pressed.emit()
	check(item_count("healing_herb.tres") == 2, "Brewing consumes exactly two of the four starting herbs")
	check(item_count("health_potion.tres") == 3, "Brewing creates exactly one additional health potion")
	await screenshot("alchemy")
	world.toggle_alchemy()
	# Drink through Q; combat naturally left the player injured.
	var hp_before: float = state.player_hp
	await action("quick_potion")
	check(state.player_hp > hp_before, "Q consumes a potion and heals combat damage")
	check(item_count("health_potion.tres") == 2, "Quick potion consumes exactly one potion")
	world.toggle_settlement()
	if world.settlement_ui.has_method("apply_jobs"):
		world.settlement_ui.worker_inputs.farmers.value = 10
		world.settlement_ui.apply_button.pressed.emit()
		world.settlement_ui.wait_button.pressed.emit()
	await screenshot("settlement")
	world.toggle_settlement()
	world.toggle_pause()
	world.pause_menu.save_btn.pressed.emit()
	var saved_hp: float = state.player_hp
	state.player_hp = 1
	world.pause_menu.load_btn.pressed.emit()
	check(state.player_hp == saved_hp, "Pause save/load restores post-combat health")
	check(not is_instance_valid(world.enemy), "Loading the completed fight does not resurrect its enemy")
	if world.has_method("get_objective_state"):
		check(world.get_objective_state().get("completed", false), "Combat, equipment, brewing and stable food finish the expedition")
	await screenshot("completed")

func item_count(suffix: String) -> int:
	var total := 0
	for item in state.inventory:
		if item.resource_path.ends_with(suffix):
			total += int(item.count)
	return total
