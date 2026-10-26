extends Node

const SETTINGS_FILE:String= "user://settings.cfg"
const Guard = preload("res://scripts/security/SaveGuard.gd")

var master_volume: float = 1.0
var music_volume: float = 0.3
var sfx_volume: float = 0.8
var ui_volume: float = 0.8
var msaa_quality:int=2
var mouse_sensitivity: float = 0.003
var camera_bobbing: bool = false
var camera_shake: bool = false
var reduced_motion: bool = false
var language: String = "ru"
var language_confirmed: bool = false

func _ready() -> void:
	load_settings()

func apply_settings() -> void:
	get_viewport().msaa_3d=clampi(msaa_quality,0,3) as Viewport.MSAA
	if AudioManager:
		AudioManager.set_bus_volume("Master", master_volume)
		AudioManager.set_bus_volume("Music", music_volume)
		AudioManager.set_bus_volume("SFX", sfx_volume)
		AudioManager.set_bus_volume("UI", ui_volume)
	if LocalizationManager:
		LocalizationManager.set_language(language)

func save_settings() -> void:
	var config:ConfigFile= ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "ui_volume", ui_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("graphics","msaa_quality",msaa_quality)
	config.set_value("gameplay", "camera_bobbing", camera_bobbing)
	config.set_value("gameplay", "camera_shake", camera_shake)
	config.set_value("gameplay", "reduced_motion", reduced_motion)
	config.set_value("language", "lang", language)
	config.set_value("language", "confirmed", language_confirmed)

	if not valid_settings(config) or not Guard.atomic_text(SETTINGS_FILE,config.encode_to_text()):
		IntegrityLogger.log_anomaly("SettingsManager", "Failed to save valid settings")

func valid_settings(config: ConfigFile) -> bool:
	if not Guard.numeric(config.get_value("graphics","msaa_quality",2),0,3,true):return false
	for field:String in ["master_volume","music_volume","sfx_volume","ui_volume"]:
		if not Guard.numeric(config.get_value("audio",field,0.5),0,1): return false
	if not Guard.numeric(config.get_value("controls","mouse_sensitivity",0.003),0.0001,0.1): return false
	for field:String in ["camera_bobbing","camera_shake","reduced_motion"]:
		if not config.get_value("gameplay",field,false) is bool: return false
	if config.get_value("language","lang","ru") not in ["ru","en"]: return false
	for section:String in config.get_sections():
		for field:String in config.get_section_keys(section):
			if not Guard.pure(config.get_value(section,field)): return false
	return true

func load_settings() -> void:
	var config:ConfigFile= ConfigFile.new()
	language="ru" if OS.get_locale_language()=="ru" else "en"
	var text:String=Guard.bounded_text(SETTINGS_FILE)
	var valid: bool=not text.is_empty() and text.length()<=65536 and Guard.safe_text(text)
	if valid: valid=config.parse(text)==OK and valid_settings(config)
	if valid:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.3)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		ui_volume = config.get_value("audio", "ui_volume", 0.8)
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.003)
		msaa_quality=config.get_value("graphics","msaa_quality",2)
		camera_bobbing = config.get_value("gameplay", "camera_bobbing", false)
		camera_shake = config.get_value("gameplay", "camera_shake", false)
		reduced_motion = config.get_value("gameplay", "reduced_motion", false)
		language = config.get_value("language", "lang", "ru")
		language_confirmed = config.get_value("language", "confirmed", true)==true
	if OS.get_environment("GAME_LANGUAGE") in ["ru","en"]:language=OS.get_environment("GAME_LANGUAGE")
	call_deferred("apply_settings")
