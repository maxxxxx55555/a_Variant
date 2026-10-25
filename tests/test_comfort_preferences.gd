extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",message)
func run() -> void:
	await process_frame
	var settings:Node=root.get_node("SettingsManager")
	check("reduced_motion" in settings,"Reduced motion is a real persistent comfort preference")
	for field in ["master_volume","music_volume","sfx_volume","ui_volume"]:settings.set(field,0.35)
	if "reduced_motion" in settings:settings.reduced_motion=true
	settings.save_settings()
	for field in ["master_volume","music_volume","sfx_volume","ui_volume"]:settings.set(field,0.9)
	if "reduced_motion" in settings:settings.reduced_motion=false
	settings.load_settings()
	for field in ["master_volume","music_volume","sfx_volume","ui_volume"]:check(is_equal_approx(settings.get(field),0.35),"Sound preference survives reload: "+field)
	if "reduced_motion" in settings:check(settings.reduced_motion,"Reduced motion survives reload")
	print("COMFORT PREFERENCES RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
