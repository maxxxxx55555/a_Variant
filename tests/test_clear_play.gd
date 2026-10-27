extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",message)
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1,false)
	var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	var town:Control=world.town_ui
	town.open(root.get_node("CampaignSystem").definition.towns[0].id)
	var tabs:=town.find_child("TownTabs",true,false) as TabContainer
	check(tabs!=null,"Town actions are grouped into focused native pages")
	if tabs:
		check(tabs.get_tab_count()==3 and town.delivery_button.is_visible_in_tree() and not town.blockade_button.is_visible_in_tree(),"Journey starts with relevant actions instead of all siege controls")
		tabs.current_tab=1
		await process_frame
		var buy:Button
		for control in town.find_children("*","Button",true,false):
			if control.get_meta("trade_resource","")=="food" and control.get_meta("text_key","")=="ui.buy": buy=control
		check(buy!=null and buy.is_visible_in_tree(),"Trade page exposes its real food purchase action")
		var economy:Node=root.get_node("EconomySystem")
		var food:float=economy.stockpiles.food
		var gold:float=economy.stockpiles.gold
		if buy: buy.pressed.emit()
		check(economy.stockpiles.food==food+10 and economy.stockpiles.gold==gold-20,"Displayed food price matches the original paid transaction")
		economy.stockpiles.gold=19
		town.refresh()
		check(buy.disabled,"An unaffordable visible purchase cannot invite a failing click")
		economy.stockpiles.gold=gold-20
		town.refresh()
		tabs.current_tab=2
		await process_frame
		check(town.blockade_button.is_visible_in_tree() and not town.delivery_button.is_visible_in_tree(),"Siege actions are reachable without covering Journey")
		var help:=town.find_child("TownDetails",true,false) as Button
		check(help!=null,"Full town instructions remain available on demand")
		if help:
			help.pressed.emit()
			check(town.description.visible and "100" in town.description.text,"Expanded explanation retains the actual alliance cost")
		for lang in ["en","ru"]:
			root.get_node("LocalizationManager").set_language(lang)
			check(tabs.get_tab_title(0)!="town.journey" and town.blockade_button.text.length()<50,"Focused pages and concise actions remain localized")
	check(world.hud.controls_label.text.length()<22,"Default help does not occupy a permanent text bar")
	if DisplayServer.get_name()!="headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-clear-town.png"))
	print("CLEAR PLAY RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
