extends Node

enum WeatherType { CLEAR, RAIN, FOG, STORM, SNOW }

var current_weather: WeatherType = WeatherType.CLEAR

# Weather modifiers
var archery_range_modifier: float = 1.0
var stealth_modifier: float = 1.0
var movement_speed_modifier: float = 1.0

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(_on_day_changed)

func _on_day_changed(day_number: int) -> void:
	# Randomize weather on new day based on season
	var current_season = TimeSystem.current_season_idx if TimeSystem else 0
	_determine_weather_for_season(current_season)

func _determine_weather_for_season(season: int) -> void:
	var roll = randf()
	var new_weather = WeatherType.CLEAR

	match season:
		0: # SPRING
			if roll < 0.4: new_weather = WeatherType.CLEAR
			elif roll < 0.8: new_weather = WeatherType.RAIN
			else: new_weather = WeatherType.FOG
		1: # SUMMER
			if roll < 0.7: new_weather = WeatherType.CLEAR
			elif roll < 0.9: new_weather = WeatherType.RAIN
			else: new_weather = WeatherType.STORM
		2: # AUTUMN
			if roll < 0.4: new_weather = WeatherType.CLEAR
			elif roll < 0.7: new_weather = WeatherType.RAIN
			elif roll < 0.9: new_weather = WeatherType.FOG
			else: new_weather = WeatherType.STORM
		3: # WINTER
			if roll < 0.3: new_weather = WeatherType.CLEAR
			elif roll < 0.8: new_weather = WeatherType.SNOW
			else: new_weather = WeatherType.FOG

	set_weather(new_weather)

func set_weather(weather: WeatherType) -> void:
	current_weather = weather
	match weather:
		WeatherType.CLEAR:
			archery_range_modifier = 1.0
			stealth_modifier = 1.0
			movement_speed_modifier = 1.0
		WeatherType.RAIN:
			archery_range_modifier = 0.85
			stealth_modifier = 1.1
			movement_speed_modifier = 1.0
		WeatherType.FOG:
			archery_range_modifier = 0.6
			stealth_modifier = 1.5
			movement_speed_modifier = 1.0
		WeatherType.STORM:
			archery_range_modifier = 0.5
			stealth_modifier = 1.2
			movement_speed_modifier = 0.9
		WeatherType.SNOW:
			archery_range_modifier = 0.8
			stealth_modifier = 1.2
			movement_speed_modifier = 0.85

	var weather_name = get_weather_string_key(weather)
	if LocalizationManager:
		var localized_name = LocalizationManager.get_string(weather_name)
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.weather_changed") + localized_name, false)

func get_weather_string_key(weather: WeatherType) -> String:
	match weather:
		WeatherType.CLEAR: return "weather.clear"
		WeatherType.RAIN: return "weather.rain"
		WeatherType.FOG: return "weather.fog"
		WeatherType.STORM: return "weather.storm"
		WeatherType.SNOW: return "weather.snow"
		_: return "weather.clear"
