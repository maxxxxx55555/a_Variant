extends Node

signal treaty_signed(faction_id: String, treaty_type: String)

var active_treaties: Dictionary = {} # faction_id -> Array of treaty_type

func propose_treaty(faction_id: String, treaty_type: String) -> bool:
	if not active_treaties.has(faction_id):
		active_treaties[faction_id] = []

	var treaties: Array = active_treaties[faction_id]
	if treaty_type in treaties:
		return false

	treaties.append(treaty_type)
	if FactionSystem:
		FactionSystem.update_relationship(faction_id, 15.0)

	treaty_signed.emit(faction_id, treaty_type)

	var f_data = FactionSystem.factions.get(faction_id) if FactionSystem else null
	var res = load(f_data["res_path"]) if f_data else null
	var faction_name = LocalizationManager.get_string(res.name_key) if res else faction_id
	var treaty_str = LocalizationManager.get_string("treaty." + treaty_type)
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.treaty_signed", {"faction": faction_name, "treaty": treaty_str}), false)
	return true

func has_treaty(faction_id: String, treaty_type: String) -> bool:
	if active_treaties.has(faction_id):
		return treaty_type in active_treaties[faction_id]
	return false
