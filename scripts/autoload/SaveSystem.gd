extends Node

const SAVE_PATH = "user://savegame.json"
const BACKUP_PATH = "user://savegame.bak"
const SCHEMA_VERSION = 2
const SECRET_SALT = "OathsOfTheMarch_v1_Salt"

func save_game(game_data: Dictionary) -> bool:
	var data_str = JSON.stringify(_normalize_numbers(game_data))
	var checksum = calculate_checksum(data_str)

	var payload = {
		"version": SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"checksum": checksum,
		"data": game_data
	}

	var final_json = JSON.stringify(payload)

	if not _read_valid_save(SAVE_PATH).is_empty():
		if DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH) != OK:
			return false

	var file = FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if not file:
		IntegrityLogger.log_anomaly("SaveSystem", "Failed to open save file for writing")
		return false

	file.store_string(final_json)
	file.close()
	if DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH) != OK:
		return false
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_saved"), false)
	return true

func load_game() -> Dictionary:
	var data := _read_valid_save(SAVE_PATH)
	if data.is_empty():
		data = try_load_backup()
	if not data.is_empty():
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_loaded"), false)
	return data

func _read_valid_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		return {}

	var payload = json.data
	if not payload is Dictionary or not payload.has("checksum") or not payload.has("data"):
		return {}
	if not payload["data"] is Dictionary or payload.get("version", 0) < 1 or payload.get("version", 0) > SCHEMA_VERSION:
		return {}

	var recorded_checksum = payload["checksum"]
	var data_dict = payload["data"]
	var data_str = JSON.stringify(_normalize_numbers(data_dict))

	if calculate_checksum(data_str) != recorded_checksum:
		# Legacy files used the engine's original JSON numeric representation.
		if payload.get("version") != 1 or calculate_checksum(JSON.stringify(data_dict)) != recorded_checksum:
			IntegrityLogger.log_anomaly("SaveSystem", "Invalid save checksum: " + path)
			return {}
	return data_dict

func try_load_backup() -> Dictionary:
	var data := _read_valid_save(BACKUP_PATH)
	if not data.is_empty():
		DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
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
