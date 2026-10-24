extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(suffix: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png"))

func run() -> void:
	await process_frame
	print("DEFAULT DISPLAY: vsync=", DisplayServer.window_get_vsync_mode(), " max_fps=", Engine.max_fps)
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await shot("main-menu")
	for button in menu.find_children("*", "Button", true, false):
		if button.visible and button.get_global_rect().end.y > menu.size.y + 1:
			push_error("Menu button is outside the viewport: " + button.text)
	menu.queue_free()
	await process_frame
	var begin := Time.get_ticks_msec()
	root.get_node("CampaignSystem").new_campaign(1, false)
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	print("WORLD LOAD MS: ", Time.get_ticks_msec() - begin)
	world.player.position = Vector3(0, 1, -120)
	world.player.camera.rotation = Vector3.ZERO
	await shot("world")
	begin = Time.get_ticks_msec()
	for index in 180:
		await process_frame
	print("RENDER AVERAGE FPS: ", 180000.0 / (Time.get_ticks_msec() - begin))
	print("RENDER PROFILE: draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " process_ms=", Performance.get_monitor(Performance.TIME_PROCESS) * 1000, " physics_ms=", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
	world.toggle_strategy(4)
	await shot("workshop")
	root.get_node("LocalizationManager").set_language("en")
	await shot("workshop-en")
	world.toggle_pause()
	world.open_town("greenhaven")
	await shot("town-en")
	quit(0)
