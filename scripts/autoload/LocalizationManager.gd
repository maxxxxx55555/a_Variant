extends Node

var current_language: String = "ru"
var translations: Dictionary = {}

func _ready() -> void:
	load_translations()

func load_translations() -> void:
	translations.clear()
	# CSV is an imported resource in release packs, so its source bytes are
	# unavailable there. Keep the editable CSV and ship the compiled catalog.
	var catalog := FileAccess.open("res://data/balance/localization.json", FileAccess.READ)
	if catalog:
		var decoded = JSON.parse_string(catalog.get_as_text())
		if decoded is Dictionary:
			translations = decoded
			return
	push_error("Compiled localization catalog is missing or invalid")
	var ru_file = FileAccess.open("res://data/strings/ru.csv", FileAccess.READ)
	if ru_file:
		parse_csv(ru_file, "ru")
		ru_file.close()
	else:
		IntegrityLogger.log_anomaly("LocalizationManager", "Failed to open ru.csv")

	var en_file = FileAccess.open("res://data/strings/en.csv", FileAccess.READ)
	if en_file:
		parse_csv(en_file, "en")
		en_file.close()
	else:
		IntegrityLogger.log_anomaly("LocalizationManager", "Failed to open en.csv")

func parse_csv(file: FileAccess, lang: String) -> void:
	var is_header = true
	var lang_col = 1 if lang == "ru" else 2
	while not file.eof_reached():
		var line = file.get_csv_line()
		if is_header or line.size() < 3 or line[0].strip_edges().is_empty():
			is_header = false
			continue
		var key = line[0].strip_edges()
		var val = line[lang_col].strip_edges()
		if not translations.has(key):
			translations[key] = {}
		translations[key][lang] = val

func get_string(key: String, params: Dictionary = {}) -> String:
	if not translations.has(key):
		IntegrityLogger.log_anomaly("LocalizationManager", "Missing localization key: " + key)
		return key

	var lang_dict = translations[key]
	var text = lang_dict.get(current_language, lang_dict.get("en", key))

	for p_key in params:
		text = text.replace("{" + str(p_key) + "}", str(params[p_key]))
	return text

func set_language(lang: String) -> void:
	if lang in ["ru", "en"]:
		current_language = lang
		EventBus.language_changed.emit(lang)
	else:
		IntegrityLogger.log_anomaly("LocalizationManager", "Unsupported language requested: " + lang)
