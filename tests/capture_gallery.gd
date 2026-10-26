extends SceneTree

func _initialize() -> void: call_deferred("run")

func shot(suffix: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png"))

func run() -> void:
	await process_frame
	root.get_node("LocalizationManager").set_language(OS.get_environment("GAME_LANGUAGE") if OS.get_environment("GAME_LANGUAGE") in ["ru","en"] else "en")
	root.get_node("MarchTransition").show_loading()
	await shot("loading")
	root.get_node("MarchTransition").hide_loading()
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await shot("title")
	menu.open_credits()
	await shot("credits")
	menu.find_child("CreditsPanel",true,false).close()
	await process_frame
	menu.queue_free()
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1, false)
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	world.toggle_pause()
	world.pause_menu._on_toggle_settings()
	await shot("settings")
	world.pause_menu._on_toggle_settings()
	world.toggle_pause()
	var state: Node = root.get_node("GameState")
	state.equip_item(0)
	world.player.position = Vector3(0, 1, 25)
	world.player.camera.rotation = Vector3(-0.04, 0, 0)
	for i in 20: await physics_frame
	await shot("homestead")
	for batch in world.find_children("Roadside*","MultiMeshInstance3D",true,false):
		if not str(batch.name).ends_with("_1"):continue
		var at:Vector3=batch.global_transform*batch.multimesh.get_instance_transform(0).origin
		world.player.position=at+Vector3(-4,0,5)
		world.player.position.y=world.terrain.ground_at(world.player.position.x,world.player.position.z)+0.1
		world.player.look_at(Vector3(at.x,world.player.position.y,at.z))
		world.player.camera.rotation.x=-0.05
		for i in 20:await physics_frame
		await shot("roadside")
		break
	var town: Dictionary = root.get_node("CampaignSystem").definition.towns[0]
	world.player.position = Vector3(town.x + 3, world.terrain.ground_at(town.x + 3, town.z + 18) + 0.1, town.z + 18)
	world.player.look_at(Vector3(town.x - 5, world.player.position.y, town.z - 6))
	world.player.camera.rotation.x = -0.03
	for i in 20: await physics_frame
	await shot("village")
	root.get_node("WeatherSystem").set_weather(1)
	for i in 15: await physics_frame
	await shot("village-rain")
	root.get_node("WeatherSystem").set_weather(0)
	world.open_town(town.id)
	await shot("trade")
	world.toggle_pause()
	world.toggle_strategy(3)
	await shot("world-map")
	world.toggle_pause()
	world.toggle_strategy(4)
	await shot("crafting")
	world.toggle_pause()
	var ending:Control=load("res://scripts/ui/CampaignFinale.gd").new()
	ending.route="diplomatic";ending.quests=60;ending.days=8
	for panel in [world.hud,world.pause_menu,world.inventory_ui,world.strategy_ui,world.town_ui,world.alchemy_ui,world.settlement_ui]:panel.hide()
	ending.z_index=80
	world.hud.get_parent().add_child(ending)
	ending.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await shot("ending-staged")
	print("CAMPAIGN GALLERY: PASS")
	quit(0)
