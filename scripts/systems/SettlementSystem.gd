extends Node

var current_laws: Dictionary = {
	"taxes": "normal", # low, normal, high
	"rations": "full", # half, full
	"conscription": "voluntary" # voluntary, forced
}

var buildings: Array[Resource] = []

func set_law(law_name: String, value: String) -> void:
	var allowed:Dictionary= {"taxes": ["low", "normal", "high"], "rations": ["half", "full"], "conscription": ["voluntary", "forced"]}
	if allowed.has(law_name) and value in allowed[law_name]:
		current_laws[law_name] = value
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.law_changed"), false)
		EventBus.settlement_updated.emit()
