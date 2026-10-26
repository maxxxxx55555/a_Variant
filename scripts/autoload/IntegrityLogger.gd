extends Node

const LOG_PATH:String= "user://integrity.log"

func log_anomaly(system_name: String, message: String, details: Dictionary = {}) -> void:
	var timestamp:String= Time.get_datetime_string_from_system(true)
	var log_entry:String= "[%s] [%s] %s %s\n" % [timestamp, system_name, message, str(details) if not details.is_empty() else ""]
	print_rich("[color=red][INTEGRITY ANOMALY][/color] ", log_entry.strip_edges())

	var file:FileAccess= FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if file:
		file.seek_end()
		if not file.store_string(log_entry):
			printerr("Integrity log write failed: ", file.get_error())
		file.close()
