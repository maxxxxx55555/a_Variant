extends Node

signal tutorial_step_triggered(step_id: String, title: String, message: String)

var completed_tutorials: Dictionary = {}
var is_tutorial_enabled: bool = true

func _ready() -> void:
	pass

func trigger_tutorial(step_id: String) -> void:
	if not is_tutorial_enabled or completed_tutorials.has(step_id):
		return

	completed_tutorials[step_id] = true
	var title_key = "tutorial." + step_id + ".title"
	var desc_key = "tutorial." + step_id + ".desc"

	var title = LocalizationManager.get_string(title_key)
	var desc = LocalizationManager.get_string(desc_key)

	tutorial_step_triggered.emit(step_id, title, desc)
	EventBus.notification_posted.emit("[TUTORIAL] " + title + ": " + desc, false)

func reset_tutorials() -> void:
	completed_tutorials.clear()
