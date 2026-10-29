extends "res://tests/AudioCleanTree.gd"

func _initialize() -> void: call_deferred("run")

func target_path(suffix: String, size: Vector2i) -> String:
	var folder: String = OS.get_environment("GAME_GALLERY_DIR")
	if folder.is_empty():
		return OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png")
	DirAccess.make_dir_recursive_absolute(folder)
	var locale: String = OS.get_environment("GAME_LANGUAGE")
	if locale not in ["ru", "en"]: locale = "en"
	return folder.path_join("%s-%dx%d-%s.png" % [locale, size.x, size.y, suffix])

func shot(suffix: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(target_path(suffix, image.get_size()))

func scroll_to_bottom(panel: Node) -> void:
	var found: Array[Node] = panel.find_children("*", "ScrollContainer", true, false)
	if found.is_empty(): return
	var scroll: ScrollContainer = found[0] as ScrollContainer
	await process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await process_frame

func stage_profile() -> void:
	var profile: Node = root.get_node("ProfileStats")
	for difficulty: int in 4:
		profile.call("begin_run", difficulty)
		profile.call("finish_victory", difficulty, 18 - difficulty * 2, 2800.0 - 350.0 * difficulty, 8 - difficulty * 2, 3600.0 * (4.5 - 0.4 * difficulty))
	profile.call("begin_run", 1)
	profile.call("finish_defeat", 1, 25, 900.0, 4, 7200.0)

func stage_settlement() -> void:
	var economy: Node = root.get_node("EconomySystem")
	economy.stockpiles = {"food": 1200.0, "wood": 4000.0, "ore": 2000.0, "stone": 3000.0, "gold": 12000.0}
	var workshop: Node = root.get_node("WorkshopSystem")
	for id: String in ["farm", "housing", "infirmary", "well", "market", "sawmill", "quarry", "forge", "barracks", "hall"]:
		for _level: int in 3:
			if not workshop.call("build", id): break

func run() -> void:
	await process_frame
	root.get_node("LocalizationManager").set_language(OS.get_environment("GAME_LANGUAGE") if OS.get_environment("GAME_LANGUAGE") in ["ru", "en"] else "en")
	stage_profile()
	root.get_node("MarchTransition").show_loading()
	await shot("loading")
	root.get_node("MarchTransition").hide_loading()
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await shot("title")
	menu.call("open_stats")
	await shot("stats")
	menu.find_child("StatsPanel", true, false).call("close")
	await process_frame
	menu.cached_save = {"simulation": {"campaign": {"active": true, "ng_level": 2, "ng_banner": "oath.banner.wanderer", "titles": ["oath.title.hard"], "difficulty": 2}}}
	menu.call("open_credits")
	await scroll_to_bottom(menu.find_child("CreditsPanel", true, false))
	await shot("credits")
	menu.find_child("CreditsPanel", true, false).call("close")
	await process_frame
	menu.queue_free()
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1, false, {"level": 2, "oaths": ["wanderer", "peace"], "titles": ["oath.title.hard"], "banner": "oath.banner.wanderer"})
	stage_settlement()
	root.get_node("SettingsManager").reduced_motion = true
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	world.toggle_pause()
	world.pause_menu._on_toggle_settings()
	await shot("settings-reduced")
	world.pause_menu._on_toggle_settings()
	world.toggle_pause()
	root.get_node("SettingsManager").reduced_motion = false
	var state: Node = root.get_node("GameState")
	state.equip_item(0)
	world.player.position = Vector3(0, 1, 25)
	world.player.camera.rotation = Vector3(-0.04, 0, 0)
	for i: int in 20: await physics_frame
	await shot("homestead")
	var town: Dictionary = root.get_node("CampaignSystem").definition.towns[0]
	world.player.position = Vector3(town.x + 3, world.terrain.ground_at(town.x + 3, town.z + 18) + 0.1, town.z + 18)
	world.player.look_at(Vector3(town.x - 5, world.player.position.y, town.z - 6))
	world.player.camera.rotation.x = -0.03
	for i: int in 20: await physics_frame
	root.get_node("WeatherSystem").set_weather(1)
	for i: int in 15: await physics_frame
	await shot("village-rain")
	root.get_node("WeatherSystem").set_weather(0)
	world.open_town(town.id)
	await shot("trade")
	world.toggle_pause()
	world.toggle_strategy(3)
	await shot("world-map")
	world.toggle_pause()
	world.toggle_codex()
	await shot("codex")
	world.toggle_codex()
	world.toggle_inventory()
	await shot("inventory")
	world.toggle_inventory()
	world.toggle_settlement()
	await shot("settlement")
	world.toggle_settlement()
	world.toggle_strategy(1)
	await shot("diplomacy")
	world.toggle_pause()
	var ending: Control = load("res://scripts/ui/CampaignFinale.gd").new()
	ending.route = "diplomatic"
	ending.quests = 60
	ending.days = 8
	for panel: Control in [world.hud, world.pause_menu, world.inventory_ui, world.strategy_ui, world.town_ui, world.alchemy_ui, world.settlement_ui]:
		panel.hide()
	ending.z_index = 80
	world.hud.get_parent().add_child(ending)
	ending.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await shot("ending-staged")
	print("CAMPAIGN GALLERY: PASS")
	finish_test(0)
