extends Node

signal changed()

const SETUP:Dictionary= {"food": 12, "wood": 8, "gold": 15}
const DAILY:Dictionary= {"food": 6, "gold": 2}
const ASSAULT:Dictionary= {"wood": 10, "food": 5}
var states: Dictionary = {}

func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	TimeSystem.day_passed.connect(_on_day_passed)

func begin(id: String) -> bool:
	if not CampaignSystem.sieges_allowed:
		EventBus.notification_posted.emit(LocalizationManager.get_string("siege.peace_forbidden"), true)
		return false
	if not CampaignSystem.faction_exists(id) or CampaignSystem.bound(id) or states.has(id) or ArmySystem.get_total_soldiers() < 3:
		return false
	# A single field army cannot blockade several distant cities simultaneously.
	for state:Variant in states.values():
		if state.phase in ["blockade", "assault"]: return false
	if not CampaignSystem.pay(SETUP): return false
	states[id] = {"phase": "blockade", "supplies": 100.0, "morale": 100.0, "wall_hp": 180.0, "days": 0}
	FactionSystem.update_relationship(id, -100)
	FactionSystem.factions[id].escalation_level = 5
	changed.emit()
	CampaignSystem.refresh()
	return true

func _on_day_passed(_day: int) -> void:
	for id:String in states.keys():
		var state: Dictionary = states[id]
		if state.phase != "blockade": continue
		if ArmySystem.get_total_soldiers() < 3 or not CampaignSystem.pay(DAILY):
			# The blockade exists and its phase was checked above.
			@warning_ignore("return_value_discarded")
			lift(id)
			EventBus.notification_posted.emit(LocalizationManager.get_string("siege.unsupplied"), true)
			continue
		state.days += 1
		var supplies:float=state.supplies
		state.supplies=maxf(0,supplies-35)
		var morale:float=state.morale
		state.morale=maxf(0,morale-25)
	changed.emit()

func launch_assault(id: String) -> bool:
	if not states.has(id) or states[id].phase != "blockade" or states[id].days < 1 or ArmySystem.get_total_soldiers() < 3:
		return false
	if not CampaignSystem.pay(ASSAULT): return false
	states[id].phase = "assault"
	if id not in CampaignSystem.assaults: CampaignSystem.assaults.append(id)
	var world:Node= get_tree().current_scene
	if world and world.has_method("spawn_garrison"):
		# CampaignWorld scene protocol; runtime guard avoids an autoload/preload cycle.
		@warning_ignore("unsafe_method_access")
		world.spawn_garrison(id)
		@warning_ignore("unsafe_method_access")
		world.sync_siege_gates()
	changed.emit()
	CampaignSystem.refresh()
	return true

func damage_gate(id: String, amount: float) -> bool:
	if not is_finite(amount) or amount <= 0 or not states.has(id) or states[id].phase != "assault" or states[id].wall_hp <= 0:
		return false
	var wall_hp:float=states[id].wall_hp
	states[id].wall_hp=maxf(0,wall_hp-amount)
	# Capture remains idempotent until both the gate and garrison are cleared.
	@warning_ignore("return_value_discarded")
	CampaignSystem.capture_faction(id)
	changed.emit()
	return true

func offer_surrender(id: String) -> bool:
	if not states.has(id) or states[id].phase != "blockade" or states[id].supplies > 0 or states[id].morale > 30 or ArmySystem.get_total_soldiers() < 3:
		return false
	states[id].wall_hp = 0
	states[id].phase = "assault"
	if id not in CampaignSystem.assaults: CampaignSystem.assaults.append(id)
	for guard:Variant in CampaignSystem.camp_ids(id, true):
		if guard not in CampaignSystem.fallen: CampaignSystem.fallen.append(guard)
	var captured:bool=CampaignSystem.capture_faction(id)
	changed.emit()
	return captured

func lift(id: String) -> bool:
	if not states.has(id) or states[id].phase != "blockade": return false
	# This keyed blockade was checked at entry.
	@warning_ignore("return_value_discarded")
	states.erase(id)
	changed.emit()
	return true

func breached(id: String) -> bool:
	return states.has(id) and states[id].phase == "assault" and states[id].wall_hp <= 0

func capture_state() -> Dictionary:
	return states.duplicate(true)

func restore_state(data: Dictionary) -> void:
	states.clear()
	for id:String in data:
		if not CampaignSystem.faction_exists(id) or not data[id] is Dictionary: continue
		var state: Dictionary = data[id]
		var supplies:float=state.get("supplies",100)
		var morale:float=state.get("morale",100)
		var wall_hp:float=state.get("wall_hp",180)
		var days:int=state.get("days",0)
		states[id]={"phase":str(state.get("phase","blockade")),"supplies":clampf(supplies,0,100),"morale":clampf(morale,0,100),"wall_hp":clampf(wall_hp,0,180),"days":maxi(0,days)}
	# Existing rc.2 battles had no gates. Preserve their earned progress.
	for id:String in CampaignSystem.assaults:
		if not states.has(id): states[id] = {"phase": "assault", "supplies": 0.0, "morale": 0.0, "wall_hp": 0.0, "days": 1}
	changed.emit()
