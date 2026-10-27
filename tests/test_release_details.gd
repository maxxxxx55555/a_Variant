extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
	await process_frame
	var transition:=root.get_node_or_null("MarchTransition")
	check(transition!=null,"Boot and campaign transitions have a persistent loading presentation")
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://scenes/ui/boot.tscn","A real boot scene precedes the title")
	var settings:Node=root.get_node("SettingsManager")
	check("msaa_quality" in settings,"MSAA quality is a persistent preference")
	var panel:Control=load("res://scenes/ui/pause_menu.tscn").instantiate()
	root.add_child(panel)
	await process_frame
	panel._on_toggle_settings()
	await process_frame
	var sensitivity:HSlider=panel.find_child("MouseSensitivity",true,false)
	var quality:OptionButton=panel.find_child("MSAAQuality",true,false)
	check(sensitivity!=null,"Mouse sensitivity has a real UI input")
	check(quality!=null,"MSAA quality has a real UI input")
	if sensitivity:
		sensitivity.value=0.006
		check(is_equal_approx(settings.mouse_sensitivity,0.006),"Sensitivity input changes the live model")
	if quality:
		quality.select(1);quality.item_selected.emit(1)
		check(root.msaa_3d==Viewport.MSAA_2X,"Quality input changes the actual viewport")
		settings.save_settings();settings.msaa_quality=0;settings.load_settings()
		check(settings.msaa_quality==1,"Quality survives a settings round trip")
	if transition:
		transition.show_loading()
		check(transition.loading_tip.text.length()>12,"Loading screen has an authored localized hint")
		transition.hide_loading()
		var attempts:=[0]
		transition.confirm_unsaved(func():attempts[0]+=1;return false,func():attempts[0]+=100)
		var dialog:ConfirmationDialog=transition.unsaved_dialog
		dialog.confirmed.emit()
		check(attempts[0]==1,"Failed retry does not discard the session or quit")
		dialog.canceled.emit()
		check(attempts[0]==1,"Stay cancels without quitting")
	panel.queue_free()
	await process_frame
	print("RELEASE DETAILS RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
