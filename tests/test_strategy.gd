extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	await process_frame
	var army: Node = root.get_node("ArmySystem")
	var population: Node = root.get_node("PopulationSystem")
	var economy: Node = root.get_node("EconomySystem")
	var factions: Node = root.get_node("FactionSystem")
	var diplomacy: Node = root.get_node("DiplomacySystem")
	check(army.has_method("recruit"), "Recruitment is available through a real population/equipment transaction")
	check(army.squads.is_empty(), "A new character does not start with more soldiers than the entire town population")
	check(not diplomacy.propose_treaty("missing_faction", "alliance"), "Unknown factions cannot sign treaties")
	check(not diplomacy.propose_treaty("iron_guild", "invented_treaty"), "Unknown treaty types are rejected")
	check(not diplomacy.propose_treaty("iron_guild", "alliance"), "Alliance requires actual trust instead of a free button")
	if army.has_method("recruit"):
		check(not army.recruit("militia_spear", -2), "Negative recruitment is rejected")
		check(not army.recruit("militia_spear", 100), "Recruitment cannot create workers out of thin air")
		var before_gold: float = economy.stockpiles.gold
		check(army.recruit("militia_spear", 3), "Available citizens can join militia")
		check(army.get_total_soldiers() == 3 and population.available_workers == 2, "Recruitment reserves actual citizens")
		check(economy.stockpiles.gold < before_gold, "Recruitment pays its equipment cost")
		army.issue_order_to_selected("invented_order")
		check(army.squads[0].order == "follow", "Unknown orders cannot leave squads in an invalid state")
		var hp_jobs: Dictionary = population.jobs.duplicate()
		hp_jobs.farmers = 14
		population.update_worker_assignments(hp_jobs)
		check(population.jobs.farmers == 8, "Already recruited soldiers cannot simultaneously be assigned to civilian jobs")
		factions.recalculate_threat(500)
		check(factions.factions.iron_guild.escalation_level < 5, "Threat escalation cannot jump directly from peace to war")
		factions.factions.iron_guild.relationship = 70
		economy.stockpiles.gold = 500
		check(diplomacy.propose_treaty("iron_guild", "alliance"), "Trusted faction accepts a paid alliance")
		var treaty_gold: float = economy.stockpiles.gold
		check(not diplomacy.propose_treaty("iron_guild", "alliance"), "Signing the same treaty twice cannot duplicate rewards")
		check(economy.stockpiles.gold == treaty_gold, "Rejected duplicate treaty does not charge money")
		population.jobs.farmers = 0
		economy.stockpiles.food = 200
		var civilian_food: float = population.total_population - army.get_total_soldiers()
		economy._on_day_passed(1)
		check(is_equal_approx(economy.stockpiles.food, 200 - civilian_food), "Civilian food accounting excludes soldiers, whose rations are charged by the army")
		var world: Node = load("res://scenes/world/test_location.tscn").instantiate()
		root.add_child(world)
		current_scene = world
		await process_frame
		world.toggle_strategy(0)
		check(paused and world.strategy_ui.visible and world.strategy_ui.roster.item_count == 1, "Council is accessible and shows the actual recruited squad")
		world.toggle_strategy(1)
		check(world.strategy_ui.tabs.current_tab == 1, "Diplomacy tab can be reached while the game is paused")
		var snapshot: Dictionary = world.pause_menu.capture_simulation()
		army.squads.clear()
		diplomacy.active_treaties.clear()
		world.pause_menu.restore_simulation(snapshot)
		check(army.get_total_soldiers() == 3 and diplomacy.has_treaty("iron_guild", "alliance"), "Army and diplomatic agreements survive save restoration")
		world.toggle_pause()
		var foe: Node3D = world.enemy
		foe.global_position = world.player.global_position + Vector3(3, 0, 0)
		foe.detection_range = 0
		var hp_before: float = foe.current_hp
		army.visual_timer = 0
		army._process(0.5)
		await create_timer(1.5).timeout
		check(not is_instance_valid(foe) or foe.current_hp < hp_before, "Recruited soldiers exist in the world and physically fight nearby enemies")
		world.queue_free()
		await process_frame
	print("STRATEGY RESULT: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
