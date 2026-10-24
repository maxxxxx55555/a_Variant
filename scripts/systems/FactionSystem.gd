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
		var expansion: float = CampaignSystem.conquests.size() * 6.0
		var calculated_threat = max(0.0, (player_army_power * personality_mult) + expansion - f["relationship"])
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

		f["desired_escalation"] = new_level

func _on_day_passed(_day: int) -> void:
	recalculate_threat(ArmySystem.get_army_power())
	for fid in factions:
		var faction: Dictionary = factions[fid]
		var desired: int = faction.get("desired_escalation", 0)
		if DiplomacySystem.has_treaty(fid, "peace") or DiplomacySystem.has_treaty(fid, "alliance"):
			desired = mini(desired, 1)
		var previous: int = faction.escalation_level
		faction.escalation_level = previous + clampi(desired - previous, -1, 1)
		if faction.escalation_level != previous:
			escalation_level_changed.emit(fid, faction.escalation_level)
			var data = load(faction.res_path)
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.escalation_warning", {"faction": LocalizationManager.get_string(data.name_key), "level": str(faction.escalation_level)}), faction.escalation_level >= 3)
