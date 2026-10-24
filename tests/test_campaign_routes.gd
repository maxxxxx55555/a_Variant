extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scenario := preload("res://scripts/verification/CampaignRoute.gd").new()
	root.add_child(scenario)
