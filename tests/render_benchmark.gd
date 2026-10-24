extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	root.get_node("LocalizationManager").set_language("en")
	root.get_node("CampaignSystem").new_campaign(1,false)
	var before:=Time.get_ticks_msec()
	var world: Node3D=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	var load_ms:=Time.get_ticks_msec()-before
	var town: Dictionary=root.get_node("CampaignSystem").definition.towns[0]
	world.player.position=Vector3(town.x+3,world.terrain.ground_at(town.x+3,town.z+18)+0.1,town.z+18)
	world.player.look_at(Vector3(town.x-5,world.player.position.y,town.z-6))
	world.player.camera.rotation.x=-0.03
	root.get_node("WeatherSystem").set_weather(1)
	root.get_node("GameState").equip_item(0)
	for i in 60: await process_frame
	before=Time.get_ticks_msec()
	for i in 180: await process_frame
	var fps:=180000.0/float(Time.get_ticks_msec()-before)
	print("RENDER BENCHMARK: load_ms=",load_ms," fps=",fps," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-rain-benchmark.png"))
	quit(0)
