extends Node

const SAVE_PATH:String= "user://savegame.json"
const BACKUP_PATH:String= "user://savegame.bak"
const Exact=preload("res://scripts/security/ExactFloats.gd")
const EXACT_FIELD:String="_exact_floats"
const SCHEMA_VERSION:int= 4
const SECRET_SALT:String= "OathsOfTheMarch_v1_Salt"
const Guard = preload("res://scripts/security/SaveGuard.gd")
const Policy = preload("res://scripts/security/MarchSavePolicy.gd")
var selected_slot: int = 0
# A checksum-only v1-v3 body is the pre-1.6 migration path. It is never applied silently: the
# load records the exact bytes as pending and only an explicit player confirmation for those
# bytes imports them. Consent is bound to a digest, not to a pathname, so a file swapped while
# the dialog is open cannot be promoted by an older answer.
var legacy_pending: Dictionary = {}
var legacy_authorised: String = ""
var last_read_schema: int = 0
var last_read_digest: String = ""

func slot_path(index: int) -> String:
	if index == 5: return "user://autosave.json"
	if index == 6: return "user://iron_save.json"
	return SAVE_PATH if index == 0 else "user://savegame_%d.json" % clampi(index,1,4)

func backup_path(path: String) -> String:
	return BACKUP_PATH if path == SAVE_PATH else path + ".bak"

func purpose(path: String) -> String:
	if path == BACKUP_PATH: return "march/savegame.json"
	return "march/" + path.get_file().trim_suffix(".bak")

func newest_slot() -> int:
	var newest:int= 0
	var stamp:int= 0
	for index:int in 7:
		var path:String= slot_path(index)
		var data:Dictionary= _read_valid_save(path)
		var valid_path:String= path
		if data.is_empty() and index != 6:
			valid_path = backup_path(path)
			data = _read_valid_save(valid_path)
		if not data.is_empty() and FileAccess.get_modified_time(valid_path) >= stamp:
			stamp = FileAccess.get_modified_time(valid_path)
			newest = index
	return newest

func load_slot(index: int) -> Dictionary:
	if index < 0 or index > 6: return {}
	return _load_path(slot_path(index))

func _encoded(data: Dictionary, context: String) -> String:
	if data.has(EXACT_FIELD):return ""
	var normalized:Dictionary=_normalize_numbers(data)
	var precision:Dictionary=Exact.capture(normalized)
	if not precision.ok:return ""
	normalized[EXACT_FIELD]=precision.patches
	var body:String=JSON.stringify(normalized,"",true,true)
	var auth:String= Guard.signature(body,context)
	if auth.is_empty(): return ""
	return JSON.stringify({"version":SCHEMA_VERSION,"timestamp":Time.get_unix_time_from_system(),"checksum":calculate_checksum(body),"data":body,"auth":auth},"",true,true)

# A checksum-only body is never promoted into an authenticated backup: without the player's
# confirmation for those exact bytes it is not trusted enough to be re-signed.
func _read_previous(path: String) -> Dictionary:
	var data: Dictionary = _read_valid_save(path)
	if not data.is_empty() and last_read_schema < SCHEMA_VERSION and legacy_authorised != last_read_digest:
		return {}
	return data

# Rejected originals are kept one per rejection: a later decline must not destroy the bytes
# an earlier one preserved.
func _preserve_rejected(path: String) -> bool:
	var target: String = path + ".rejected"
	var suffix: int = 2
	while FileAccess.file_exists(target):
		target = "%s.rejected-%d" % [path, suffix]
		suffix += 1
	return DirAccess.copy_absolute(path, target) == OK

func _store(path: String, data: Dictionary) -> bool:
	if not Guard.can_write(): return false
	if not Policy.valid(data): return false
	var primary:Dictionary= _read_previous(path)
	var previous:Dictionary= primary
	# Preserve the authenticated envelope and timestamp for an unchanged state.
	# Legacy files still migrate; invalid primaries still recover from their backup.
	if not previous.is_empty() and Guard.locked(purpose(path)):
		var envelope:Variant=JSON.parse_string(Guard.bounded_text(path))
		if envelope is Dictionary:
			var record:Dictionary=envelope
			if record.get("version")==SCHEMA_VERSION and JSON.stringify(_normalize_numbers(previous),"",true,true)==JSON.stringify(_normalize_numbers(data),"",true,true):return true
	var encoded:String= _encoded(data,purpose(path))
	if encoded.is_empty(): return false
	if previous.is_empty(): previous = _read_previous(backup_path(path))
	if FileAccess.file_exists(path) and primary.is_empty():
		if not _preserve_rejected(path): return false
	if not previous.is_empty() and path != slot_path(6):
		if not Guard.atomic_text(backup_path(path),_encoded(previous,purpose(path))): return false
	if not Guard.atomic_text(path,encoded): return false
	return Guard.lock(purpose(path))

func save_game(game_data: Dictionary, autosave: bool = false) -> bool:
	var path:String= slot_path(6 if CampaignSystem.active and CampaignSystem.iron_mode else 5 if autosave else selected_slot)
	if not _store(path,game_data):
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.save_write_error"),true)
		return false
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_saved"),false)
	return true

func _load_path(path: String) -> Dictionary:
	if Guard.transaction_depth!=0:return {}
	var data:Dictionary= _read_valid_save(path)
	var body_digest:String= last_read_digest
	var recovered:bool= false
	if data.is_empty() and path != slot_path(6):
		data = _read_valid_save(backup_path(path))
		recovered = true
		body_digest = last_read_digest
	# An unconfirmed checksum-only body is recorded by its exact bytes and never reaches game
	# state or the recovery notices; only confirm_legacy_import() for that digest applies it.
	if not data.is_empty() and last_read_schema < SCHEMA_VERSION and legacy_authorised != body_digest:
		legacy_pending[path] = body_digest
		return {}
	if not data.is_empty() and recovered: Guard.report_recovery("integrity.save_recovered",path)
	if data.is_empty() and (FileAccess.file_exists(path) or FileAccess.file_exists(backup_path(path))): Guard.report_recovery("integrity.save_rejected",path)
	if Guard.can_write() and not data.is_empty() and (recovered or not Guard.locked(purpose(path))):
		if not _store(path,data): EventBus.notification_posted.emit(LocalizationManager.get_string("msg.save_write_error"),true)
	return data

func has_pending_legacy(path: String) -> bool:
	return legacy_pending.has(path)

func pending_legacy_digest(path: String) -> String:
	return str(legacy_pending.get(path, ""))

func cancel_legacy_import(path: String) -> void:
	# Dictionary.erase returns whether it removed something; the caller only needs the state cleared.
	@warning_ignore("return_value_discarded")
	legacy_pending.erase(path)

func confirm_legacy_import(path: String) -> Dictionary:
	if not legacy_pending.has(path): return {}
	var expected: String = str(legacy_pending[path])
	legacy_authorised = expected
	var data: Dictionary = _load_path(path)
	legacy_authorised = ""
	if data.is_empty():
		# The bytes behind this slot are no longer the ones the player was shown, so nothing is
		# applied and the current body stays pending for a fresh question.
		if legacy_pending.has(path) and str(legacy_pending[path]) != expected:
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.legacy_changed"), true)
		return {}
	@warning_ignore("return_value_discarded")
	legacy_pending.erase(path)
	if not data.is_empty(): EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_loaded"), false)
	return data

func load_game() -> Dictionary:
	var data:Dictionary= _load_path(slot_path(selected_slot))
	if not data.is_empty(): EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_loaded"),false)
	return data

func _read_valid_save(path: String) -> Dictionary:
	last_read_schema = 0
	last_read_digest = ""
	var text:String= Guard.bounded_text(path)
	if text.is_empty() or not Guard.safe_text(text): return {}
	last_read_digest = _text_digest(text)
	var payload_value:Variant=JSON.parse_string(text)
	if not payload_value is Dictionary:return {}
	var payload:Dictionary=payload_value
	var version: Variant = payload.get("version",0)
	if not Guard.numeric(version,1,SCHEMA_VERSION,true): return {}
	var decoded:Variant
	var schema:int=version
	last_read_schema = schema
	if schema == SCHEMA_VERSION:
		if not payload.get("data") is String:return {}
		var body:String=payload.data
		if not Guard.authentic(body,purpose(path),payload.get("auth")) or not Guard.safe_text(body):return {}
		decoded=JSON.parse_string(body)
	else:
		if Guard.locked(purpose(path)): return {}
		if schema == 3:
			if not payload.get("data") is String:return {}
			var body:String=payload.data
			if calculate_checksum(body)!=payload.get("checksum") or not Guard.safe_text(body):return {}
			decoded=JSON.parse_string(body)
		else:
			if not payload.get("data") is Dictionary: return {}
			decoded = payload.data
			if calculate_checksum(JSON.stringify(_normalize_numbers(decoded))) != payload.get("checksum"):
				if schema!=1 or calculate_checksum(JSON.stringify(decoded)) != payload.get("checksum"): return {}
	if decoded is Dictionary:
		var restored:Dictionary=decoded
		if restored.has(EXACT_FIELD):
			if schema!=SCHEMA_VERSION or not Exact.restore(restored,restored[EXACT_FIELD]):return {}
			if not restored.erase(EXACT_FIELD):return {}
	return decoded if Policy.valid(decoded) else {}

func _normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var result:Dictionary= {}
		for key:Variant in value:
			result[key] = _normalize_numbers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item:Variant in value:
			result.append(_normalize_numbers(item))
		return result
	if value is int or value is float:
		var number:float=value
		return number
	return value

func calculate_checksum(data: String) -> String:
	var ctx:HashingContext= HashingContext.new()
	if ctx.start(HashingContext.HASH_SHA256)!=OK:return ""
	if ctx.update((data + SECRET_SALT).to_utf8_buffer())!=OK:return ""
	var res:PackedByteArray= ctx.finish()
	return res.hex_encode()

# The exact bytes of a save file, so a player's answer can be bound to the body it was about.
func _text_digest(text: String) -> String:
	var ctx:HashingContext= HashingContext.new()
	if ctx.start(HashingContext.HASH_SHA256)!=OK:return ""
	if ctx.update(text.to_utf8_buffer())!=OK:return ""
	var res:PackedByteArray= ctx.finish()
	return res.hex_encode()
