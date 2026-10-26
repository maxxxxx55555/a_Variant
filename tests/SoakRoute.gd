extends "res://scripts/verification/CampaignRoute.gd"
signal cycle_finished(code:int)
var checkpoints:int=0
func quit(code:int)->void:cycle_finished.emit(code)
func region_checkpoint()->void:
	if not campaign.ending().is_empty():return
	world.toggle_pause()
	var before:float=root.get_node("TimeSystem").game_time_seconds
	await get_tree().create_timer(0.1,true,false,true).timeout
	if not get_tree().paused or before!=root.get_node("TimeSystem").game_time_seconds:fail("Soak pause cannot advance simulation")
	world.pause_menu._on_toggle_settings()
	await process_frame
	world.pause_menu._on_toggle_settings()
	if not world.pause_menu._on_save():fail("Soak ordinary manual save")
	world.pause_menu._on_load()
	if get_tree().paused:world.toggle_pause()
	world.toggle_inventory()
	await process_frame
	world.toggle_inventory()
	root.get_node("LocalizationManager").set_language("ru" if checkpoints%2 else "en")
	checkpoints+=1
