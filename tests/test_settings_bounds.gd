extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var settings: Node=root.get_node("SettingsManager")
	settings.master_volume=0.7
	var file:=FileAccess.open(settings.SETTINGS_FILE,FileAccess.WRITE)
	file.store_string("[audio]\nmaster_volume=-4.0\n")
	file.close()
	settings.load_settings()
	var good: bool=settings.master_volume==0.7
	if not good: print("FAIL: Out-of-range settings must not enter live state")
	for payload in ["[audio]\nmaster_volume=\"loud\"\n","[gameplay]\ncamera_shake=7\n","[extra]\npayload=Object(RefCounted,)\n"]:
		settings.master_volume=0.7
		file=FileAccess.open(settings.SETTINGS_FILE,FileAccess.WRITE)
		file.store_string(payload)
		file.close()
		settings.load_settings()
		if settings.master_volume!=0.7:
			good=false
			print("FAIL: Invalid or native-object settings must be rejected before application")
	settings.master_volume=0.7
	settings.save_settings()
	settings.master_volume=0.2
	settings.load_settings()
	good=good and is_equal_approx(settings.master_volume,0.7)
	print("SETTINGS BOUNDS: ","PASS" if good else "FAIL")
	quit(0 if good else 1)
