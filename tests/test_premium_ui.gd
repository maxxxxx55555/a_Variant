extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func run() -> void:
	await process_frame
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	var body:=menu.get_theme_default_font()
	check(body.has_char(0x042f) and body.has_char(0x0436),"RPG font supports Russian and English")
	check("GolosText" in str(body.resource_path) or (body is FontVariation and "GolosText" in body.base_font.resource_path),"RPG uses its new readable body family")
	for state in ["normal","hover","pressed","disabled"]:
		check(menu.continue_button.get_theme_stylebox(state) is StyleBoxTexture,"Menu has an authored scalable "+state+" surface")
	var focus: StyleBox = menu.continue_button.get_theme_stylebox("focus")
	check(focus is StyleBoxFlat and focus.border_width_left>=2,"RPG has a visible keyboard focus ring")
	for button in menu.find_children("*","Button",true,false):
		check(root.get_visible_rect().encloses(button.get_global_rect()),"Title controls stay on-screen: "+button.text)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-premium-menu.png"))
	print("PREMIUM UI RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
