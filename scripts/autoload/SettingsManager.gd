extends Node

const SETTINGS_FILE = "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var ui_volume: float = 0.8
var mouse_sensitivity: float = 0.003
var camera_bobbing: bool = true
var camera_shake: bool = true
var language: String = "ru"

func _ready() -> void:
	load_settings()

func apply_settings() -> void:
	if AudioManager:
		AudioManager.set_bus_volume("Master", master_volume)
		AudioManager.set_bus_volume("Music", music_volume)
		AudioManager.set_bus_volume("SFX", sfx_volume)
		AudioManager.set_bus_volume("UI", ui_volume)
	if LocalizationManager:
		LocalizationManager.set_language(language)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "camera_bobbing", camera_bobbing)
	config.set_value("gameplay", "camera_shake", camera_shake)
	config.set_value("language", "lang", language)

	var err = config.save(SETTINGS_FILE)
	if err != OK:
		IntegrityLogger.log_anomaly("SettingsManager", "Failed to save settings: " + str(err))

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		ui_volume = config.get_value("audio", "ui_volume", 0.8)
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.003)
		camera_bobbing = config.get_value("gameplay", "camera_bobbing", true)
		camera_shake = config.get_value("gameplay", "camera_shake", true)
		language = config.get_value("language", "lang", "ru")
	call_deferred("apply_settings")
