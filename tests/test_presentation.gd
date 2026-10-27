extends "res://tests/AudioCleanTree.gd"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1, false)
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var failed := false
	if world.hud.controls_label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		push_error("Keyboard help must wrap inside its allotted HUD area")
		failed = true
	var help_rect: Rect2 = world.hud.controls_label.get_global_rect()
	if help_rect.position.y < 0 or help_rect.end.y > root.get_visible_rect().size.y + 1:
		push_error("Compact keyboard help must stay inside the viewport")
		failed = true
	if not DisplayServer.is_touchscreen_available() and world.hud.attack_btn.visible:
		push_error("Desktop keyboard help must not overlap unnecessary touch action buttons")
		failed = true
	world.show_ending("diplomatic")
	world._sync_menu_state()
	if world.hud.visible or not paused:
		push_error("The ending must remain modal and hide the HUD after menu synchronization")
		failed = true
	if world.ending_panel.get_global_rect().size != root.get_visible_rect().size:
		push_error("The ending backdrop must cover the complete viewport")
		failed = true
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-ending.png"))
	world.ending_panel.find_child("ContinueEnding", true, false).pressed.emit()
	await process_frame
	if paused or not world.hud.visible:
		push_error("Continuing after an ending must restore the world and HUD")
		failed = true
	print("PRESENTATION RESULT: ", "FAIL" if failed else "PASS")
	finish_test(1 if failed else 0)
