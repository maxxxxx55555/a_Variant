extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func unobscured(control:Control) -> bool:
	var bounds:Rect2=control.get_global_rect()
	if not control.is_visible_in_tree() or not root.get_visible_rect().encloses(bounds):return false
	var ancestor:Control=control.get_parent_control()
	while ancestor:
		if ancestor.clip_contents and not ancestor.get_global_rect().encloses(bounds):return false
		ancestor=ancestor.get_parent_control()
	return true
func run() -> void:
	await process_frame
	var panel:Control=load("res://scenes/ui/pause_menu.tscn").instantiate()
	panel.theme=load("res://scripts/ui/MarchTheme.gd").create()
	root.add_child(panel);panel.show();panel._on_toggle_settings()
	await process_frame;await process_frame
	var back:Button=panel.find_child("BackButton",true,false)
	check(back!=null,"Settings provides an explicit back action")
	if back:
		check(unobscured(back),"Back is visible before scrolling settings")
		var scroll:ScrollContainer=panel.get_node("MarginContainer/SettingsScroll")
		scroll.scroll_vertical=10000
		await process_frame;await process_frame
		check(unobscured(back),"Back stays visible after scrolling to the final setting")
		back.pressed.emit()
		check(not panel.settings_panel.visible and panel.visible and panel.settings_btn.has_focus(),"Back returns to the pause actions and restores keyboard focus")
	print("SETTINGS NAVIGATION RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
