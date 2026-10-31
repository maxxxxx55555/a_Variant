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
		var silent: Dictionary = save._load_path(target)
		check(silent.is_empty(), "A checksum-only profile is never applied without an explicit confirmation")
		check(save.has_pending_legacy(target) and save.pending_legacy_digest(target) == save._text_digest(FileAccess.get_file_as_string(target)), "The pending import names exactly that file and its bytes")
		var loaded: Dictionary = save.confirm_legacy_import(target)
		check(loaded == expected, "Confirming imports the actual 1.1 " + name + " state without losing progress")
		check(not save.has_pending_legacy(target), "A resolved import stops being pending")
		var migrated: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(target))
		check(migrated.get("version")==4 and migrated.has("auth"),"Migration writes authenticated version 4")
		check(save._load_path(target)==expected,"Authenticated migrated state reloads")
	print("LEGACY MIGRATION RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
