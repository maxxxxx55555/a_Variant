extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func run() -> void:
	await process_frame
	var save: Node=root.get_node("SaveSystem")
	var Guard=preload("res://scripts/security/SaveGuard.gd")
	for name in ["MarchlandOaths","MarchlandOaths-military"]:
		var source: String="res://tests/fixtures/legacy-"+name+".json"
		var target: String="user://legacy-"+name+".json"
		DirAccess.remove_absolute(Guard.lock_path(save.purpose(target)))
		check(DirAccess.copy_absolute(source,target)==OK,"Copy actual 1.1 profile fixture")
		var payload: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
		var expected: Dictionary=JSON.parse_string(payload.data)
		var loaded: Dictionary=save._load_path(target)
		check(not loaded.is_empty() and loaded==expected,"Actual 1.1 "+name+" state migrates without losing progress")
		var migrated: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(target))
		check(migrated.get("version")==4 and migrated.has("auth"),"Migration writes authenticated version 4")
		check(save._load_path(target)==expected,"Authenticated migrated state reloads")
	print("LEGACY MIGRATION RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
