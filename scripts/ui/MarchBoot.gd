extends Control
func _ready() -> void:
	MarchTransition.go_to.call_deferred("res://scenes/ui/main_menu.tscn")
