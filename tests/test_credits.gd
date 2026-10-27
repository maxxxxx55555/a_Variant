extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",message)
func run() -> void:
	await process_frame
	var menu:Control=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	check(menu.has_method("open_credits"),"The initial menu provides real credits")
	if not menu.has_method("open_credits"):
		finish_test(1)
		return
	var trigger:=menu.find_child("CreditsButton",true,false) as Button
	check(trigger!=null,"Credits are reachable through a visible menu button")
	if trigger:trigger.pressed.emit()
	else:menu.open_credits()
	await process_frame
	var credits:=menu.find_child("CreditsPanel",true,false) as Control
	check(credits!=null and credits.visible,"The credits action opens a real screen")
	if credits:
		var close:=credits.find_child("CloseCredits",true,false) as Button
		check(close!=null and root.get_visible_rect().encloses(close.get_global_rect()),"Credits provide an in-bounds close action")
		var body:=credits.find_child("CreditsBody",true,false) as Label
		check(body!=null and "Godot" in body.text and "OFL" in body.text and "CC0" in body.text,"Credits disclose engine, fonts and effect provenance")
		if close:close.pressed.emit()
		await process_frame
		check(not is_instance_valid(credits) or credits.is_queued_for_deletion() or not credits.visible,"Closing credits restores the existing menu")
	print("CREDITS RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
