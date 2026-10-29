extends "res://tests/AudioCleanTree.gd"
var failures:int=0
var campaign:Node
var codex:Node
var stats:Node
var saves:Node
var codex_before:int=0
func check(ok:bool,label:String)->void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func digest(value:Variant)->String:
	return JSON.stringify(saves._normalize_numbers(value),"",true,true).sha256_text()
func write_text(path:String,text:String)->bool:
	var file:FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null:return false
	file.store_string(text)
	file.close()
	return FileAccess.get_file_as_string(path)==text
func fixture(name:String)->String:
	return "res://tests/fixtures/"+name+".json"
func body_of(name:String)->String:
	var raw:Variant=JSON.parse_string(FileAccess.get_file_as_string(fixture(name)))
	if not raw is Dictionary:
		return ""
	@warning_ignore("unsafe_cast")
	var envelope:Dictionary=raw
	var value:Variant=envelope.get("data")
	if value is String:
		return str(value)
	return JSON.stringify(value)
func block(profile:Dictionary)->Dictionary:
	var simulation:Variant=profile.get("simulation",{})
	if not simulation is Dictionary:
		return {}
	@warning_ignore("unsafe_cast")
	var typed:Dictionary=simulation
	var value:Variant=typed.get("campaign",{})
	return value if value is Dictionary else {}
func assert_defaults(name:String)->void:
	check(int(campaign.ng_level)==0,"Legacy profile starts outside the Second Oath loop: "+name)
	check((campaign.oaths as Array).is_empty(),"Legacy profile carries no oath modifiers: "+name)
	check((campaign.titles as Array).is_empty(),"Legacy profile carries no inherited titles: "+name)
	check(float(campaign.enemy_scale())==1.0,"Legacy profile keeps the original enemy scale: "+name)
	stats.restore_state({})
	check(int(codex.found())==codex_before,"Loading a pre-1.6 profile leaves Codex progress intact: "+name)
	check(not (stats.by_difficulty() as Array).is_empty(),"A profile with no statistics block still yields complete rows: "+name)
func run()->void:
	await process_frame
	saves=root.get_node("SaveSystem")
	campaign=root.get_node("CampaignSystem")
	codex=root.get_node("CodexSystem")
	stats=root.get_node("ProfileStats")
	var Guard=preload("res://scripts/security/SaveGuard.gd")
	var entries:Array=codex.entries()
	check(not entries.is_empty(),"The Codex catalogue is loaded before migration runs")
	# Suite cases share one throwaway profile, so earlier routes may already have unlocked entries.
	# The migration contract is a delta over whatever the profile reached, not a count only a
	# pristine profile can produce.
	var baseline:int=int(codex.found())
	var pending:String=""
	for candidate:Variant in entries:
		if not (candidate is Dictionary):
			continue
		@warning_ignore("unsafe_cast")
		var identifier:String=str((candidate as Dictionary).get("id",""))
		if not identifier.is_empty() and not codex.is_unlocked(identifier):
			pending=identifier
			break
	check(not pending.is_empty(),"A still-locked Codex entry exists for the migration baseline")
	if not pending.is_empty():
		codex.unlock(pending,false)
	codex_before=int(codex.found())
	check(codex_before==baseline+1,"Exactly one Codex entry is unlocked as the migration baseline")
	for name in ["legacy-MarchlandOaths","legacy-MarchlandOaths-military"]:
		var original:Dictionary=JSON.parse_string(body_of(name))
		var original_campaign:Dictionary=block(original)
		var target:String="user://oath-migration-"+name+".json"
		DirAccess.remove_absolute(Guard.lock_path(saves.purpose(target)))
		check(DirAccess.copy_absolute(fixture(name),target)==OK,"Copy shipped pre-1.6 profile: "+name)
		var loaded:Dictionary=saves._load_path(target)
		check(not loaded.is_empty(),"Checksum-only pre-1.6 profile loads and re-signs under the 1.6 schema: "+name)
		if loaded.is_empty():
			continue
		var migrated:Dictionary=block(loaded)
		check(not migrated.is_empty(),"Migrated profile keeps its simulation block: "+name)
		campaign.restore_state(migrated)
		assert_defaults(name)
		for key:String in original_campaign:
			if key=="sieges":
				continue
			check(digest(migrated.get(key))==digest(original_campaign.get(key)),"Migration preserves "+key+" in "+name)
		var signed:Variant=JSON.parse_string(FileAccess.get_file_as_string(target))
		check(signed is Dictionary and int((signed as Dictionary).get("version",0))==4
			and (signed as Dictionary).has("auth"),"Reading a pre-1.6 profile upgrades it to an authenticated version 4 file")
		var staged:Dictionary=loaded.duplicate(true)
		@warning_ignore("unsafe_cast")
		var staged_simulation:Dictionary=staged.get("simulation",{})
		staged_simulation["campaign"]=campaign.capture_state()
		check(bool(saves._store(target,staged)),"Saving a migrated pre-1.6 profile: "+name)
		var rewritten:Dictionary=block(saves._load_path(target))
		check(rewritten.has("ng_level") and rewritten.has("oaths") and rewritten.has("titles"),
			"The first 1.6 save adds the oath fields to "+name)
		check(str(rewritten.get("ng_banner","")).is_empty(),"Migrated profile keeps an unclaimed banner: "+name)
	var foreign:String="user://oath-migration-foreign.json"
	DirAccess.remove_absolute(Guard.lock_path(saves.purpose(foreign)))
	check(DirAccess.copy_absolute(fixture("protected-v1.5.0-autosave"),foreign)==OK,"Copy the published 1.5.0 autosave")
	check(saves._load_path(foreign).is_empty(),"A profile signed by another installation is refused, not trusted")
	var published_body:String=body_of("protected-v1.5.0-autosave")
	check(not published_body.is_empty(),"The published 1.5.0 autosave body is readable")
	var own:String="user://oath-migration-own-key.json"
	DirAccess.remove_absolute(Guard.lock_path(saves.purpose(own)))
	var envelope:Dictionary={"version":4,"timestamp":Time.get_unix_time_from_system(),
		"checksum":saves.calculate_checksum(published_body),"data":published_body,
		"auth":Guard.signature(published_body,saves.purpose(own))}
	check(write_text(own,JSON.stringify(envelope)),"Install the 1.5.0 profile as this installation would have written it")
	var upgraded:Dictionary=saves._load_path(own)
	check(not upgraded.is_empty(),"A 1.5.0 autosave from the same installation loads in 1.6.0")
	if not upgraded.is_empty():
		var upgraded_campaign:Dictionary=block(upgraded)
		check(not upgraded_campaign.has("ng_level"),"The 1.5.0 profile predates the oath fields")
		campaign.restore_state(upgraded_campaign)
		assert_defaults("protected-v1.5.0-autosave")
		var restored:Dictionary=upgraded.duplicate(true)
		@warning_ignore("unsafe_cast")
		var simulation:Dictionary=restored.get("simulation",{})
		simulation["campaign"]=campaign.capture_state()
		check(bool(saves._store(own,restored)),"Migrated 1.6 profile saves")
		check(digest(saves._load_path(own))==digest(restored),"Migrated profile round trips with an identical hash")
	var forged_body:String=body_of("protected-v1.4.0-autosave")
	var forged:String="user://oath-migration-forged.json"
	DirAccess.remove_absolute(Guard.lock_path(saves.purpose(forged)))
	check(write_text(forged,JSON.stringify({"version":4,"timestamp":Time.get_unix_time_from_system(),
		"checksum":saves.calculate_checksum(forged_body),"data":forged_body,"auth":"00"})),"Install a forged 1.6 envelope")
	check(saves._load_path(forged).is_empty(),"Forged 1.6 envelope is refused")
	var future:String="user://oath-migration-future.json"
	DirAccess.remove_absolute(Guard.lock_path(saves.purpose(future)))
	check(write_text(future,JSON.stringify({"version":99,"timestamp":0,"checksum":"0","data":{}})),"Install a future schema profile")
	check(saves._load_path(future).is_empty(),"Unknown future schema is refused")
	campaign.restore_state({})
	check(not bool(campaign.second_oath_available()),"A legacy profile cannot start a Second Oath before finishing a campaign")
	campaign.restore_state({"active":true,"announced_ending":"ending.peace","difficulty":1})
	check(bool(campaign.second_oath_available()),"A completed campaign unlocks the Second Oath")
	check(bool(campaign.begin_second_oath(["wanderer","bogus","bogus"])),"Second Oath starts from a migrated profile")
	check(int(campaign.ng_level)==1,"Second Oath advances the level exactly once")
	check(campaign.oaths==["wanderer"],"Unknown oath ids are dropped before they reach the save")
	var carry:Dictionary=campaign.capture_state()
	campaign.restore_state({})
	campaign.restore_state(carry)
	check(campaign.oaths==["wanderer"] and int(campaign.ng_level)==1,"Oath state survives a save and reload")
	print("OATH MIGRATION RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
