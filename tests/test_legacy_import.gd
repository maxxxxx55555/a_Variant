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
	DirAccess.remove_absolute(saves.backup_path(path))
	DirAccess.remove_absolute(path)
	check(DirAccess.copy_absolute("res://tests/fixtures/legacy-MarchlandOaths.json",path)==OK,"Legacy fixture staged at "+path)
	var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(int(payload.get("version",SCHEMA)) < SCHEMA,"Staged fixture really is a checksum-only schema")
	return JSON.parse_string(payload.get("data"))
func write_text(path:String,text:String)->void:
	var file:FileAccess=FileAccess.open(path,FileAccess.WRITE)
	check(file!=null,"Write handle for "+path)
	if file==null:
		return
	file.store_string(text)
	file.flush()
	file.close()
# A different checksum-only state, valid under the published checksum rule, written over an
# already-offered file. This is what an answer bound to a pathname instead of bytes would accept.
func variant_text(path:String)->String:
	var saves:Node=root.get_node("SaveSystem")
	var envelope:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var body:Dictionary=JSON.parse_string(envelope.get("data"))
	body["hp"]=12.0
	var inner:String=JSON.stringify(body,"",true,true)
	var record:Dictionary={"version":3,"timestamp":int(envelope.get("timestamp",0))+7,
		"checksum":saves.calculate_checksum(inner),"data":inner}
	return JSON.stringify(record,"",true,true)
func legacy_dialogs(transition:Node,title:String)->int:
	var found:int=0
	for child:Node in transition.get_children():
		if child is ConfirmationDialog and (child as ConfirmationDialog).title==title:
			found+=1
	return found
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
	var notices:Array=[]
	var event_bus:Node=root.get_node("EventBus")
	event_bus.notification_posted.connect(func(text:String,_danger:bool)->void: notices.append(text))

	var path:String="user://legacy-import-confirm.json"
	var expected:Dictionary=stage(path)
	check(saves._load_path(path).is_empty(),"A silent load never applies a checksum-only profile")
	check(saves.has_pending_legacy(path) and saves.pending_legacy_digest(path)==saves._text_digest(FileAccess.get_file_as_string(path)),"The refused file is pending under its own digest")
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
	check(not saves.has_pending_legacy(path),"A confirmed import stops being pending")
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
	check(not saves.has_pending_legacy(declined),"Declining clears the pending entry")
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

	# Each rejection keeps its own preserved copy instead of overwriting the previous evidence.
	var first_rejected:String=FileAccess.get_file_as_string(declined+".rejected")
	var twice:String="user://legacy-import-twice.json"
	stage(twice)
	check(saves._load_path(twice).is_empty(),"A rejection at a fresh slot is refused")
	check(saves._store(twice, declined_expected),"Writing over that rejection succeeds")
	stage(twice)
	write_text(twice,variant_text(twice))
	check(saves._load_path(twice).is_empty(),"A different rejection at the same slot is refused too")
	check(saves._store(twice, declined_expected),"Writing over the second rejection succeeds")
	check(FileAccess.file_exists(twice+".rejected-2"),"The second rejection is preserved under its own name")
	check(FileAccess.get_file_as_string(twice+".rejected") != FileAccess.get_file_as_string(twice+".rejected-2"),
		"The two preserved bodies are distinct")
	check(not first_rejected.is_empty(),"The declined slot still holds its preserved original")

	# Consent is bound to bytes: a file swapped while the dialog is open cannot inherit the answer.
	stage(path)
	var tampered:String=variant_text(path)
	write_text(path,tampered)
	check(saves._load_path(path).is_empty(),"A swapped checksum-only file is refused")
	var swapped_digest:String=saves.pending_legacy_digest(path)
	write_text(path,first_rejected)
	check(saves._load_path(path).is_empty(),"The original bytes are refused as a new body")
	check(saves.pending_legacy_digest(path)!=swapped_digest,"A different body records a different pending digest")
	transition.confirm_legacy_import(path,func(data:Dictionary)->void: delivered.append(data))
	await process_frame
	var third:ConfirmationDialog=dialog_for(transition,title)
	check(third!=null,"The player is asked about the bytes now on disk")
	if third==null:
		print("LEGACY IMPORT RESULT: FAIL")
		quit(1)
		return
	write_text(path,tampered)
	notices.clear()
	var answers:int=delivered.size()
	@warning_ignore("return_value_discarded")
	third.confirmed.emit()
	await process_frame
	check(delivered.size()==answers+1 and delivered[answers].is_empty(),
		"An answer given for other bytes imports nothing and still answers its caller")
	check(notices.has(localization.get_string("msg.legacy_changed")),"The player is told the file changed")
	check(saves.has_pending_legacy(path) and saves.pending_legacy_digest(path)==swapped_digest,
		"The current body stays pending for a fresh question")
	var refused:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	check(int(refused.get("version")) < 4 and not refused.has("auth"),"The swapped file is not re-signed by a stale answer")
	transition.confirm_legacy_import(path,func(data:Dictionary)->void: delivered.append(data))
	await process_frame
	var fourth:ConfirmationDialog=dialog_for(transition,title)
	check(fourth!=null,"The swapped body is offered on its own terms")
	if fourth!=null:
		@warning_ignore("return_value_discarded")
		fourth.confirmed.emit()
		await process_frame
		var swapped_state:Dictionary=JSON.parse_string(JSON.parse_string(tampered).get("data"))
		check(delivered.size()==answers+2 and delivered[answers+1]==swapped_state,
			"A fresh explicit answer imports the body it was shown")
		var re_signed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		check(int(re_signed.get("version"))==4 and re_signed.has("auth"),"The newly confirmed body is the one written")

	# A second slot gets its own dialog; the superseded caller is answered and its file stays pending.
	var superseded:String="user://legacy-import-superseded.json"
	var replacement:String="user://legacy-import-replacement.json"
	var replacement_state:Dictionary=stage(replacement)
	var superseded_state:Dictionary=stage(superseded)
	var superseded_bytes:String=FileAccess.get_file_as_string(superseded)
	check(saves._load_path(superseded).is_empty(),"The first of two slots is refused")
	var first_answer:Array=[]
	transition.confirm_legacy_import(superseded,func(data:Dictionary)->void: first_answer.append(data))
	await process_frame
	check(saves._load_path(replacement).is_empty(),"The second of two slots is refused")
	transition.confirm_legacy_import(replacement,func(data:Dictionary)->void: first_answer.append(data))
	await process_frame
	await process_frame
	check(first_answer.size()==1 and first_answer[0].is_empty(),"The superseded request is answered with nothing")
	check(legacy_dialogs(transition,title)==1,"Only one legacy dialog is on screen")
	check(saves.has_pending_legacy(superseded),"The first file stays pending for its own question")
	var live:ConfirmationDialog=dialog_for(transition,title)
	if live!=null:
		@warning_ignore("return_value_discarded")
		live.confirmed.emit()
		await process_frame
		check(FileAccess.get_file_as_string(superseded)==superseded_bytes,"Confirming one slot leaves the other file untouched")
		check(not saves.has_pending_legacy(replacement),"The dialog answered for the slot that asked last")
		check(saves.has_pending_legacy(superseded),"The other slot is still waiting for its own answer")
		check(first_answer.size()==2 and first_answer[1]==replacement_state,"The surviving dialog answers its own caller")
	var superseded_again:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(superseded))
	check(int(superseded_again.get("version")) < 4,"The untouched slot is still a checksum-only file")
	check(not superseded_state.is_empty(),"Both staged profiles carry real state")
	print("LEGACY IMPORT RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
