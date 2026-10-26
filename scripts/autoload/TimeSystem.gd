extends Node

signal day_passed(day_number: int)
signal season_changed(new_season: String)

var game_time_seconds: float = 0.0
var day_duration_seconds: float = 1080.0 # 18 minutes default
var current_day: int = 1
var current_week: int = 1
var current_season_idx: int = 0
var seasons: Array[String] = ["spring", "summer", "autumn", "winter"]
var current_weather: String = "clear"

func _process(delta: float) -> void:
	game_time_seconds += delta
	while game_time_seconds >= day_duration_seconds:
		game_time_seconds -= day_duration_seconds
		advance_day()

func advance_day() -> void:
	current_day += 1

	# Whole weeks intentionally discard the fractional remainder.
	@warning_ignore("integer_division")
	current_week = int((current_day - 1) / 7) + 1

	if (current_day - 1) % 28 == 0:
		current_season_idx = (current_season_idx + 1) % seasons.size()
		season_changed.emit(seasons[current_season_idx])
	day_passed.emit(current_day)
