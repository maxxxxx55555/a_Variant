extends Node

signal treaty_signed(faction_id: String, treaty_type: String)
var active_treaties: Dictionary = {}
var treaty_expiry: Dictionary = {}
var terms: Dictionary = {}

func _ready() -> void:
	terms = BuildIntegrity.read_json("res://data/balance/diplomacy.json")
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	TimeSystem.day_passed.connect(_on_day_passed)

func propose_treaty(faction_id: String, treaty_type: String) -> bool:
	if not FactionSystem.factions.has(faction_id) or not terms.has(treaty_type):
		return false
	if has_treaty(faction_id, treaty_type):
		return false
	var faction: Dictionary = FactionSystem.factions[faction_id]
	var price: Dictionary = terms[treaty_type]
	if faction.relationship < price.relationship or EconomySystem.stockpiles.gold < price.gold:
		return false
	if faction.escalation_level >= 5 and treaty_type != "peace":
		return false
	EconomySystem.stockpiles.gold -= price.gold
	if not active_treaties.has(faction_id):
		active_treaties[faction_id] = []
	var treaties:Array=active_treaties[faction_id]
	treaties.append(treaty_type)
	var duration:int=price.days
	treaty_expiry[faction_id + ":" + treaty_type] = TimeSystem.current_day+duration
	if treaty_type == "peace":
		faction.escalation_level = 0
		var relationship:float=faction.relationship
		faction.relationship=maxf(-10,relationship)
	else:
		FactionSystem.update_relationship(faction_id, 5)
	treaty_signed.emit(faction_id, treaty_type)
	EventBus.settlement_updated.emit()
	var faction_path:String=faction.res_path
	var data:FactionData=load(faction_path) as FactionData
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.treaty_signed", {"faction": LocalizationManager.get_string(data.name_key), "treaty": LocalizationManager.get_string("treaty." + treaty_type)}), false)
	return true

func has_treaty(faction_id: String, treaty_type: String) -> bool:
	if not active_treaties.has(faction_id) or treaty_type not in active_treaties[faction_id]:
		return false
	var expires:int=treaty_expiry.get(faction_id+":"+treaty_type,0)
	return TimeSystem.current_day<expires

func give_gift(faction_id: String, gold: int) -> bool:
	if not FactionSystem.factions.has(faction_id) or gold <= 0 or EconomySystem.stockpiles.gold < gold:
		return false
	EconomySystem.stockpiles.gold -= gold
	FactionSystem.update_relationship(faction_id, minf(15, gold * 0.1))
	EventBus.settlement_updated.emit()
	return true

func _on_day_passed(_day: int) -> void:
	for faction:String in active_treaties:
		var valid: Array = []
		for treaty:String in active_treaties[faction]:
			if has_treaty(faction, treaty):
				valid.append(treaty)
		active_treaties[faction] = valid
