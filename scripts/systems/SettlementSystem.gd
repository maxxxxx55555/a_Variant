extends Node

var current_laws: Dictionary = {
	"taxes": "normal", # low, normal, high
	"rations": "full", # half, full
	"conscription": "voluntary" # voluntary, forced
}

var buildings: Array[Resource] = []

func set_law(law_name: String, value: String) -> void:
	if current_laws.has(law_name):
		current_laws[law_name] = value
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.law_updated", {"law": law_name, "val": value}), false)
