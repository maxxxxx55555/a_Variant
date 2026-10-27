extends "res://scripts/verification/CampaignRoute.gd"
const TitleView=preload("res://scripts/ui/MainMenu.gd")

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	call_deferred("run")

func check(ok:bool,message:String)->void:
	if not ok:fail(message)

func run()->void:
	if not OS.has_feature("qa_verifier") or OS.get_environment("GAME_QA")!="1":quit(64);return
	await process_frame
	if is_instance_valid(current_scene):current_scene.queue_free();await process_frame
	campaign=CampaignSystem
	state=GameState
	campaign.new_campaign(1,true)
	var scene:PackedScene=load("res://scenes/world/march.tscn")
	world=scene.instantiate() as WorldView
	root.add_child(world);current_scene=world
	await process_frame
	state.take_damage(1000)
	check(campaign.iron_dead and state.player_hp==0 and get_tree().paused,"Real lethal damage produces terminal iron death")
	check(world.pause_menu.resume_btn.disabled and world.pause_menu.load_btn.disabled,"Native terminal actions block revival and rewind")
	var tombstone:Dictionary=SaveSystem.load_slot(6)
	var simulation:Dictionary=tombstone.get("simulation",{})
	var saved_campaign:Dictionary=simulation.get("campaign",{})
	var persisted_dead:bool=saved_campaign.get("iron_dead",false)
	check(persisted_dead,"Native authenticated iron tombstone persists")
	var raw:PackedByteArray=FileAccess.get_file_as_bytes(SaveSystem.slot_path(6))
	var stamina:float=state.player_stamina
	Input.action_press("block")
	for _hit:int in 20:
		state.take_damage(1)
		world.player.take_damage(1)
	Input.action_release("block")
	for _click:int in 20:
		world.pause_menu._on_load()
		world.pause_menu._on_resume()
		world.restart_run()
	check(campaign.iron_dead and state.player_hp==0 and state.player_stamina==stamina,"Repeated native callbacks cannot revive or consume terminal stamina")
	check(FileAccess.get_file_as_bytes(SaveSystem.slot_path(6))==raw,"Rejected native callbacks preserve tombstone bytes")
	for language:String in ["en","ru"]:
		LocalizationManager.set_language(language)
		check(world.pause_menu.resume_btn.text==LocalizationManager.get_string("ui.iron_end_label"),"Native terminal copy follows live language")
		check(world.pause_menu.resume_btn.tooltip_text==LocalizationManager.get_string("ui.iron_dead"),"Native disabled action has a translated explanation")
	var escape:InputEventKey=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	Input.parse_input_event(escape);await process_frame
	escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=false
	Input.parse_input_event(escape);await process_frame
	check(get_tree().paused and state.player_hp==0,"Native Escape cannot resume iron death")
	var back:Button=world.pause_menu.find_child("ToMenuButton",true,false) as Button
	check(back!=null and not back.disabled,"Native terminal screen has an enabled return action")
	if back:back.pressed.emit()
	for _frame:int in 180:
		await process_frame
		if current_scene is TitleView:break
	var title:TitleView=current_scene as TitleView
	check(title!=null and not is_instance_valid(world),"Actual native Back reaches the title")
	if title:
		check(title.continue_button.disabled,"The title cannot continue the dead iron profile")
		title.queue_free()
	get_tree().paused=false;await process_frame
	check(FileAccess.get_file_as_bytes(SaveSystem.slot_path(6))==raw,"Returning to the title preserves the authenticated tombstone")
	campaign.new_campaign(1,false)
	world=scene.instantiate() as WorldView;root.add_child(world);current_scene=world
	await process_frame
	state.take_damage(1000)
	var gold:float=qa_economy_system.stockpiles.gold
	world.pause_menu._on_resume()
	var actual_gold:float=qa_economy_system.stockpiles.gold
	check(state.player_hp==state.max_hp and not get_tree().paused and is_equal_approx(actual_gold,gold*0.8),"Ordinary native paid recovery remains functional")
	world.queue_free();await process_frame
	var audio_settled:bool=await settle_audio()
	print("NATIVE IRON DEATH: ","FAIL" if failed or not audio_settled else "PASS")
	quit(1 if failed or not audio_settled else 0)
