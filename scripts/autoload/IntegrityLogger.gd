extends Node

const LOG_PATH = "user://integrity.log"

func log_anomaly(system_name: String, message: String, details: Dictionary = {}) -> void:
	var timestamp = Time.get_datetime_string_from_system(true)
	var log_entry = "[%s] [%s] %s %s\n" % [timestamp, system_name, message, str(details) if not details.is_empty() else ""]
	print_rich("[color=red][INTEGRITY ANOMALY][/color] ", log_entry.strip_edges())

	var file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_string(log_entry)
		file.close()

func log_info(system_name: String, message: String) -> void:
	var timestamp = Time.get_datetime_string_from_system(true)
	var log_entry = "[%s] [%s] [INFO] %s\n" % [timestamp, system_name, message]
	print(log_entry.strip_edges())
