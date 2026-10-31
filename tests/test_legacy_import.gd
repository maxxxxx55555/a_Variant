extends SceneTree
var failures:int=0
const SCHEMA:int=4
const Guard=preload("res://scripts/security/SaveGuard.gd")
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func stage(path:String)->Dictionary:
	var saves:Node=root.get_node("SaveSystem")
	DirAccess.remove_absolute(Guard.lock_path(saves.purpose(path)))
	DirAccess.remove_absolute(path)
	check(DirAccess.copy_absolute("res://tests/fixtures/legacy-MarchlandOaths.json",path)==OK,"Legacy fixture staged at "+path)
	var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(int(payload.get("version",SCHEMA)) < SCHEMA,"Staged fixture really is a checksum-only schema")
	return JSON.parse_string(payload.get("data"))
func dialog_for(transition:Node,title:String)->ConfirmationDialog:
	for child:Node in transition.get_children():
		if child is ConfirmationDialog and (child as ConfirmationDialog).title==title:
			return child as ConfirmationDialog
	return null
func run()->void:
	await process_frame
	var saves:Node=root.get_node("SaveSystem")
	var localization:Node=root.get_node("LocalizationManager")
	var transition:Node=root.get_node("MarchTransition")
	var title:String=localization.get_string("ui.legacy_import_title")

	var path:String="user://legacy-import-confirm.json"
	var expected:Dictionary=stage(path)
	check(saves._load_path(path).is_empty(),"A silent load never applies a checksum-only profile")
	check(saves.has_pending_legacy() and saves.pending_legacy_path()==path,"The refused file is recorded as pending")
	var delivered:Array=[]
	var answered:Array=[false]
	transition.confirm_legacy_import(path,func(data:Dictionary)->void:
		delivered.append(data)
		answered[0]=true)
	await process_frame
	var dialog:ConfirmationDialog=dialog_for(transition,title)
	check(dialog!=null,"The transition shows the legacy import dialog")
	if dialog==null:
		print("LEGACY IMPORT RESULT: FAIL")
		quit(1)
		return
	check(dialog.dialog_text==localization.get_string("ui.legacy_import_body"),"The dialog states the checksum-only risk")
	check(dialog.ok_button_text==localization.get_string("ui.legacy_import_accept"),"The accept action is localized")
	check(dialog.cancel_button_text==localization.get_string("ui.legacy_import_decline"),"The decline action is localized")
	@warning_ignore("return_value_discarded")
	dialog.confirmed.emit()
	await process_frame
	check(answered[0] and delivered.size()==1,"Confirming hands the profile back to the caller")
	check(not delivered[0].is_empty() and delivered[0]==expected,"The confirmed import restores the actual 1.1 state")
	check(not saves.has_pending_legacy(),"A confirmed import stops being pending")
	var signed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(int(signed.get("version"))==4 and signed.has("auth"),"The confirmed file is re-signed under schema 4")
	check(not is_instance_valid(dialog),"The dialog releases itself after the answer")

	var declined:String="user://legacy-import-decline.json"
	var declined_expected:Dictionary=stage(declined)
	check(not declined_expected.is_empty(),"A second checksum-only file is staged")
	var before:String=FileAccess.get_file_as_string(declined)
	check(not before.is_empty(),"The staged file is readable")
	check(saves._load_path(declined).is_empty(),"The second silent load is refused too")
	var declined_answered:Array=[]
	transition.confirm_legacy_import(declined,func(data:Dictionary)->void: declined_answered.append(data))
	await process_frame
	var second:ConfirmationDialog=dialog_for(transition,title)
	check(second!=null,"Declining also presents the dialog")
	if second==null:
		print("LEGACY IMPORT RESULT: FAIL")
		quit(1)
		return
	@warning_ignore("return_value_discarded")
	second.canceled.emit()
	await process_frame
	check(declined_answered.size()==1 and declined_answered[0].is_empty(),"Declining delivers nothing to the caller")
	check(not saves.has_pending_legacy(),"Declining clears the pending entry")
	check(FileAccess.get_file_as_string(declined)==before,"Declining leaves the legacy file byte-identical")
	var untouched:Dictionary=JSON.parse_string(before)
	check(int(untouched.get("version")) < 4,"No silent re-signing happened behind the player's back")
	# A declined body must never return later as an authenticated backup of that slot.
	check(saves._store(declined, declined_expected),"An ordinary write into the declined slot succeeds")
	var backup_text:String=FileAccess.get_file_as_string(saves.backup_path(declined))
	var promoted:bool=false
	if not backup_text.is_empty():
		var backup_envelope:Dictionary=JSON.parse_string(backup_text)
		var backup_body:Variant=backup_envelope.get("data")
		if backup_body is String:
			promoted=JSON.parse_string(backup_body as String)==declined_expected
		else:
			promoted=backup_body is Dictionary and (backup_body as Dictionary)==declined_expected
	check(not promoted,"A declined checksum-only body is never promoted into an authenticated backup")
	check(FileAccess.file_exists(declined+".rejected"),"The declined file is preserved as .rejected instead")
	print("LEGACY IMPORT RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
