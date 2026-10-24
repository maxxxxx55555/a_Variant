extends Node

const SAVE_PATH = "user://savegame.json"
const BACKUP_PATH = "user://savegame.bak"
const SCHEMA_VERSION = 4
const SECRET_SALT = "OathsOfTheMarch_v1_Salt"
const Guard = preload("res://scripts/security/SaveGuard.gd")
const Policy = preload("res://scripts/security/MarchSavePolicy.gd")
var selected_slot: int = 0

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
	var newest := 0
	var stamp := 0
	for index in 7:
		var path := slot_path(index)
		var data := _read_valid_save(path)
		var valid_path := path
		if data.is_empty():
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
	var body := JSON.stringify(data,"",true,true)
	var auth := Guard.signature(body,context)
	if auth.is_empty(): return ""
	return JSON.stringify({"version":SCHEMA_VERSION,"timestamp":Time.get_unix_time_from_system(),"checksum":calculate_checksum(body),"data":body,"auth":auth},"",true,true)

func _store(path: String, data: Dictionary) -> bool:
	if not Policy.valid(data): return false
	var encoded := _encoded(data,purpose(path))
	if encoded.is_empty(): return false
	var previous := _read_valid_save(path)
	if previous.is_empty(): previous = _read_valid_save(backup_path(path))
	if not previous.is_empty() and path != slot_path(6):
		if not Guard.atomic_text(backup_path(path),_encoded(previous,purpose(path))): return false
	elif FileAccess.file_exists(path) and previous.is_empty():
		if DirAccess.copy_absolute(path,path+".rejected") != OK: return false
	if not Guard.atomic_text(path,encoded): return false
	return Guard.lock(purpose(path))

func save_game(game_data: Dictionary, autosave: bool = false) -> bool:
	var path := slot_path(6 if CampaignSystem.active and CampaignSystem.iron_mode else 5 if autosave else selected_slot)
	if not _store(path,game_data): return false
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_saved"),false)
	return true

func _load_path(path: String) -> Dictionary:
	var data := _read_valid_save(path)
	var recovered := false
	if data.is_empty() and path != slot_path(6):
		data = _read_valid_save(backup_path(path))
		recovered = true
	if not data.is_empty() and (recovered or not Guard.locked(purpose(path))): _store(path,data)
	return data

func load_game() -> Dictionary:
	var data := _load_path(slot_path(selected_slot))
	if not data.is_empty(): EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_loaded"),false)
	return data

func _read_valid_save(path: String) -> Dictionary:
	var text := Guard.bounded_text(path)
	if text.is_empty() or not Guard.safe_text(text): return {}
	var payload: Variant = JSON.parse_string(text)
	if not payload is Dictionary: return {}
	var version: Variant = payload.get("version",0)
	if not Guard.numeric(version,1,SCHEMA_VERSION,true): return {}
	var decoded: Variant
	if int(version) == SCHEMA_VERSION:
		if not payload.get("data") is String or not Guard.authentic(payload.data,purpose(path),payload.get("auth")): return {}
		if not Guard.safe_text(payload.data): return {}
		decoded = JSON.parse_string(payload.data)
	else:
		if Guard.locked(purpose(path)): return {}
		if int(version) == 3:
			if not payload.get("data") is String or calculate_checksum(payload.data) != payload.get("checksum"): return {}
			if not Guard.safe_text(payload.data): return {}
			decoded = JSON.parse_string(payload.data)
		else:
			if not payload.get("data") is Dictionary: return {}
			decoded = payload.data
			if calculate_checksum(JSON.stringify(_normalize_numbers(decoded))) != payload.get("checksum"):
				if int(version)!=1 or calculate_checksum(JSON.stringify(decoded)) != payload.get("checksum"): return {}
	return decoded if Policy.valid(decoded) else {}

func try_load_backup() -> Dictionary:
	var data := _read_valid_save(BACKUP_PATH)
	if not data.is_empty(): _store(SAVE_PATH,data)
	return data

func _normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _normalize_numbers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_normalize_numbers(item))
		return result
	if value is int or value is float:
		return float(value)
	return value

func calculate_checksum(data: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((data + SECRET_SALT).to_utf8_buffer())
	var res = ctx.finish()
	return res.hex_encode()
