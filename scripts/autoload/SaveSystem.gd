extends Node

const SAVE_PATH = "user://savegame.json"
const BACKUP_PATH = "user://savegame.bak"
const SCHEMA_VERSION = 1
const SECRET_SALT = "OathsOfTheMarch_v1_Salt"

func save_game(game_data: Dictionary) -> bool:
	var payload = {
		"version": SCHEMA_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"data": game_data
	}

	var json_str = JSON.stringify(payload)
	var checksum = calculate_checksum(json_str)
	payload["checksum"] = checksum

	var final_json = JSON.stringify(payload)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		IntegrityLogger.log_anomaly("SaveSystem", "Failed to open save file for writing")
		return false

	file.store_string(final_json)
	file.close()
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_saved"), false)
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(BACKUP_PATH):
			IntegrityLogger.log_anomaly("SaveSystem", "Save file missing, attempting restore from backup")
			DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
		else:
			return {}

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}

	var json_str = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		IntegrityLogger.log_anomaly("SaveSystem", "Corrupted save JSON, restoring backup")
		return try_load_backup()

	var payload = json.data
	if not payload is Dictionary or not payload.has("checksum") or not payload.has("data"):
		IntegrityLogger.log_anomaly("SaveSystem", "Invalid save format, restoring backup")
		return try_load_backup()

	var recorded_checksum = payload["checksum"]
	payload.erase("checksum")

	var raw_payload_str = JSON.stringify(payload)
	if calculate_checksum(raw_payload_str) != recorded_checksum:
		IntegrityLogger.log_anomaly("SaveSystem", "Save checksum mismatch, data modified or corrupted!")
		return try_load_backup()

	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.game_loaded"), false)
	return payload["data"]

func try_load_backup() -> Dictionary:
	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.copy_absolute(BACKUP_PATH, SAVE_PATH)
		return load_game()
	return {}

func calculate_checksum(data: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((data + SECRET_SALT).to_utf8_buffer())
	var res = ctx.finish()
	return res.hex_encode()
