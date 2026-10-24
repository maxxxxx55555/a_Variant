extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	await process_frame
	var campaign := root.get_node_or_null("CampaignSystem")
	check(campaign != null, "Campaign has persistent, objective-driven progression")
	if campaign:
		campaign.new_campaign(1, false)
		check(campaign.definition.factions.size() == 8, "All eight political factions have definitions")
		check(campaign.definition.towns.size() == 14, "Fourteen distinct settlements exist")
		check(campaign.definition.quests.size() == 60, "Sixty quests have real objectives")
		check(campaign.ending().is_empty(), "A new game cannot claim a campaign victory")
		check(not campaign.deliver_supplies("invalid"), "Unknown recipient cannot consume supplies")
		check(not campaign.travel("unknown"), "Unknown road point is rejected")
		check(not campaign.capture_faction("iron_guild"), "A faction cannot be conquered before its garrison is defeated")
		var state: Dictionary = campaign.capture_state()
		campaign.visited.append("temporary")
		campaign.restore_state(state)
		check(not campaign.visited.has("temporary"), "Restoration replaces campaign progress instead of combining timelines")
		var language_listeners: int = root.get_node("EventBus").get_signal_connection_list("language_changed").size()
		var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
		root.add_child(world)
		current_scene = world
		await process_frame
		await physics_frame
		check(world.terrain.width == 4000, "The campaign terrain spans the connected four-kilometre map")
		var terrain_arrays: Array = world.terrain.get_child(0).mesh.surface_get_arrays(0)
		check(terrain_arrays[Mesh.ARRAY_NORMAL][GRID_CENTER()].y > 0.9, "Terrain triangles face the player instead of rendering only their underside")
		check(get_nodes_in_group("enemies").size() == 25, "Eight three-person camps and the tutorial enemy are present")
		check(world.strategy_ui.tabs.get_tab_count() == 5, "Map and crafting have accessible council tabs")
		world.open_town("greenhaven")
		check(paused and world.town_ui.visible and "greenhaven" in campaign.visited, "Talking to a reeve opens a real town interaction and records the visit")
		var gold: float = root.get_node("EconomySystem").stockpiles.gold
		campaign.refresh()
		campaign.refresh()
		check(root.get_node("EconomySystem").stockpiles.gold == gold, "Completed quest rewards cannot repeat on refresh")
		check(root.get_node("WorkshopSystem").build("farm"), "A starting settlement can build a productive farm")
		check(not root.get_node("WorkshopSystem").craft("invented"), "Unknown blueprints cannot create equipment")
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-town.png"))
		world.toggle_pause()
		world.toggle_strategy(3)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-map.png"))
		world.toggle_pause()
		world.player.position = Vector3(0, 1, -120)
		world.player.camera.rotation = Vector3.ZERO
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-march.png"))
		var saved_world: Dictionary = world.get_world_state()
		var saved_simulation: Dictionary = world.pause_menu.capture_simulation()
		var campaign_enemy: Node3D
		for actor in get_nodes_in_group("enemies"):
			if actor.has_meta("campaign_id"):
				campaign_enemy = actor
				break
		var enemy_id: String = campaign_enemy.get_meta("campaign_id")
		campaign_enemy.take_damage(10000)
		await process_frame
		world.pause_menu.restore_simulation(saved_simulation)
		world.load_world_state(saved_world)
		await process_frame
		var restored: Array = get_nodes_in_group("enemies").filter(func(actor): return actor.get_meta("campaign_id", "") == enemy_id)
		check(restored.size() == 1, "Loading an earlier snapshot restores a camp enemy killed after that save")
		root.get_node("ArmySystem").recruit("militia_spear", 3)
		root.get_node("SiegeSystem").begin("iron_guild")
		root.get_node("TimeSystem").advance_day()
		check(campaign.start_assault("iron_guild"), "A supplied blockade launches a real siege battle")
		saved_world = world.get_world_state()
		world.load_world_state(saved_world)
		world.load_world_state(saved_world)
		await process_frame
		var guards: Array = get_nodes_in_group("enemies").filter(func(actor): return str(actor.get_meta("campaign_id", "")).begins_with("iron_guild_guard_"))
		check(guards.size() == 3, "Repeated loads cannot duplicate a living garrison")
		var siege: Node = root.get_node("SiegeSystem")
		siege.damage_gate("iron_guild", 66)
		saved_simulation = world.pause_menu.capture_simulation()
		saved_world = world.get_world_state()
		siege.damage_gate("iron_guild", 500)
		await process_frame
		world.pause_menu.restore_simulation(saved_simulation)
		world.load_world_state(saved_world)
		await process_frame
		check(siege.states.iron_guild.wall_hp == 114 and is_instance_valid(world.siege_gates.get("iron_guild")), "Loading before a breach restores the physical damaged gate and its exact health")
		check(get_nodes_in_group("civilians").size() == 42, "Every town has three nonblocking residents while quest reeves remain available")
		world.queue_free()
		await process_frame
		check(root.get_node("EventBus").get_signal_connection_list("language_changed").size() == language_listeners, "Leaving a world removes its language listeners before the next campaign starts")
		var save: Node = root.get_node("SaveSystem")
		for index in 5:
			save.selected_slot = index
			check(save.save_game({"slot_marker": index}), "Manual save slot accepts a snapshot")
		for index in 5:
			check(save.load_slot(index).get("slot_marker", -1) == index, "Manual save slots keep independent snapshots")
		save.selected_slot = 0
		campaign.new_campaign(1, true)
		world = load("res://scenes/world/march.tscn").instantiate()
		root.add_child(world)
		current_scene = world
		await process_frame
		world.pause_menu._on_save()
		root.get_node("GameState").take_damage(1000)
		check(campaign.iron_dead and world.pause_menu.resume_btn.disabled and world.pause_menu.load_btn.disabled, "Iron mode death disables revival and manual rewind")
		var iron: Dictionary = save.load_slot(6)
		check(iron.get("simulation", {}).get("campaign", {}).get("iron_dead", false), "Iron death replaces the only iron save with a persistent tombstone")
		world.queue_free()
		await process_frame
		paused = false
	print("CAMPAIGN RESULT: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func GRID_CENTER() -> int:
	return 64 * 129 + 64
