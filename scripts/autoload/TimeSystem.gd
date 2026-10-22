extends Node

var game_time_seconds: float = 0.0

func _process(delta: float) -> void:
	game_time_seconds += delta
