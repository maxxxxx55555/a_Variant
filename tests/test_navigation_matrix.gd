extends SceneTree
var failures:int=0
var screens:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: ",label)

func key(code:Key)->void:
	var event:InputEventKey=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event)
	await process_frame
func escape_panel(panel:Control)->void:
	# A focused number editor uses the first Escape to cancel its edit.
	# The next Escape must close the containing menu and resume gameplay.
	for attempt:int in 3:
		if not panel.visible:return
		await key(KEY_ESCAPE)
func visit(panel:Control,label:String)->void:
	await process_frame;await process_frame
	var controls:Array=panel.find_children("*","BaseButton",true,false).filter(func(c:BaseButton)->bool:return c.is_visible_in_tree() and not c.disabled and c.focus_mode!=Control.FOCUS_NONE)
	check(not controls.is_empty(),label+" has a keyboard action")
	if controls.is_empty():return
	controls[0].grab_focus()
	for index:int in mini(controls.size()+2,30):
		await key(KEY_TAB)
		var owner:Control=root.gui_get_focus_owner()
		check(owner!=null and owner.is_visible_in_tree(),label+" Tab retains a visible focus target")
		if owner:check(root.get_visible_rect().encloses(owner.get_global_rect()),label+" focused control stays inside viewport: "+str(owner.name))
	for control:BaseButton in panel.find_children("*","BaseButton",true,false):
		if control.is_visible_in_tree() and control.disabled:check(not control.tooltip_text.is_empty(),label+" disabled action explains its requirement")

func run()->void:
	await process_frame
	var campaign:Node=root.get_node("CampaignSystem")
	campaign.new_campaign(1,false)
	var menu:Control=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu);current_scene=menu
	await visit(menu,"Title")
	menu.open_credits()
	var credits:Control=menu.find_child("CreditsPanel",true,false)
	await visit(credits,"Credits")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(credits),"Credits Escape returns to title")
	menu.queue_free();await process_frame
	var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world);current_scene=world
	await process_frame
	for language:String in ["en","ru"]:
		root.get_node("LocalizationManager").set_language(language)
		for index:int in 5:
			world.toggle_strategy(index)
			await visit(world.strategy_ui,"Council "+str(index)+" "+language)
			await escape_panel(world.strategy_ui)
			check(not world.strategy_ui.visible and not paused,"Council Escape resumes gameplay")
			screens+=1
		world.open_town("greenhaven")
		for index:int in world.town_ui.tabs.get_tab_count():
			world.town_ui.tabs.current_tab=index
			await visit(world.town_ui,"Town "+str(index)+" "+language)
			screens+=1
		await escape_panel(world.town_ui)
		check(not world.town_ui.visible and not paused,"Town Escape resumes gameplay")
		for method:String in ["toggle_inventory","toggle_alchemy","toggle_settlement"]:
			world.call(method)
			var panel:Control=world.inventory_ui if method=="toggle_inventory" else world.alchemy_ui if method=="toggle_alchemy" else world.settlement_ui
			await visit(panel,method+" "+language)
			await escape_panel(panel)
			check(not panel.visible and not paused,method+" Escape resumes gameplay")
			screens+=1
		world.toggle_pause()
		await visit(world.pause_menu,"Pause "+language)
		world.pause_menu._on_toggle_settings()
		await visit(world.pause_menu,"Settings "+language)
		await key(KEY_ESCAPE)
		check(world.pause_menu.visible and not world.pause_menu.settings_panel.visible,"Settings Escape returns to pause")
		await key(KEY_ESCAPE)
		check(not paused,"Pause Escape resumes gameplay")
		screens+=2
		if DisplayServer.get_name()!="headless":
			DisplayServer.window_set_size(Vector2i(1440,900))
			await process_frame;await process_frame
			DisplayServer.window_set_size(Vector2i(1280,720))
			await process_frame;await process_frame
	world.queue_free();paused=false
	await process_frame
	print("NAVIGATION MATRIX RESULT: ","PASS" if failures==0 else "FAIL"," screens=",screens)
	quit(0 if failures==0 else 1)
