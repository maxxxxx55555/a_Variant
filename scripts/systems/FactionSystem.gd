extends Node

signal faction_relationship_changed(faction_id: String, new_relationship: float)
signal escalation_level_changed(faction_id: String, new_level: int)

var factions: Dictionary = {
	"woodland_freeholders": {
		"res_path": "res://data/factions/woodland_freeholders.tres",
		"relationship": 10.0,
		"threat": 0.0,
		"escalation_level": 0
	},
	"borderland_watch": {
		"res_path": "res://data/factions/borderland_watch.tres",
		"relationship": 0.0,
		"threat": 0.0,
		"escalation_level": 0
	},
	"iron_guild": {
		"res_path": "res://data/factions/iron_guild.tres",
		"relationship": 15.0,
		"threat": 0.0,
		"escalation_level": 0
	}
}

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(_on_day_passed)

func update_relationship(faction_id: String, delta_val: float) -> void:
	if factions.has(faction_id):
		var f = factions[faction_id]
		f["relationship"] = clamp(f["relationship"] + delta_val, -100.0, 100.0)
		faction_relationship_changed.emit(faction_id, f["relationship"])

func recalculate_threat(player_army_power: float) -> void:
	for fid in factions.keys():
		var f = factions[fid]
		var res = load(f["res_path"])
		var personality_mult = 1.2 if res and res.personality_type == "cautious" else 1.0
		var calculated_threat = max(0.0, (player_army_power * personality_mult) - f["relationship"])
		f["threat"] = calculated_threat

		var new_level = 0
		if calculated_threat > 80.0:
			new_level = 5 # War
		elif calculated_threat > 60.0:
			new_level = 4 # Incidents
		elif calculated_threat > 40.0:
			new_level = 3 # Diplomatic choice
		elif calculated_threat > 25.0:
			new_level = 2 # Mobilization
		elif calculated_threat > 10.0:
			new_level = 1 # Rising alarm

		if new_level != f["escalation_level"]:
			f["escalation_level"] = new_level
			escalation_level_changed.emit(fid, new_level)
			var fname = LocalizationManager.get_string(res.name_key) if res else fid
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.escalation_warning", {"faction": fname, "level": str(new_level)}), new_level >= 3)

func _on_day_passed(_day: int) -> void:
	var total_army_power = 0.0
	if ArmySystem:
		for sq in ArmySystem.squads:
			total_army_power += sq.get("count", 0) * 3.0
	recalculate_threat(total_army_power)
