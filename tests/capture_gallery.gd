extends SceneTree

func _initialize() -> void: call_deferred("run")

func shot(suffix: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png"))

func run() -> void:
	await process_frame
	root.get_node("LocalizationManager").set_language("en")
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await shot("title")
	menu.queue_free()
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1, false)
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var state: Node = root.get_node("GameState")
	state.equip_item(0)
	world.player.position = Vector3(0, 1, 25)
	world.player.camera.rotation = Vector3(-0.04, 0, 0)
	for i in 20: await physics_frame
	await shot("homestead")
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
	print("CAMPAIGN GALLERY: PASS")
	quit(0)
