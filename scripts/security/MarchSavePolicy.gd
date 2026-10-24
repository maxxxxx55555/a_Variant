extends RefCounted
const Guard = preload("res://scripts/security/SaveGuard.gd")
const ITEM_DIRS := ["weapons","armors","potions"]
static func resource_path(value: Variant, directories: Array = ITEM_DIRS) -> bool:
	if not value is String or value.length()>160 or ".." in value or "\\" in value: return false
	for directory in directories:
		if value == "res://data/" + directory + "/" + value.get_file() and value.get_extension()=="tres":
			return ResourceLoader.exists(value)
	return false

static func item(value: Variant, slot: String = "") -> bool:
	if value == null: return not slot.is_empty()
	if not value is Dictionary or not resource_path(value.get("resource_path")): return false
	if not Guard.numeric(value.get("count",1),1,10000,true): return false
	var res: Resource = load(value.resource_path)
	if not res is ItemData: return false
	if slot == "weapon" and not res is WeaponData: return false
	if slot in ["head","torso","legs"] and (not res is ArmorData or res.slot != slot): return false
	if value.has("weight") and not Guard.numeric(value.weight,0,1000): return false
	if value.has("durability") and not Guard.numeric(value.durability,0,100000): return false
	return true

static func vector(value: Variant, count: int = 3) -> bool:
	if not value is Array or value.size()!=count: return false
	for axis in value:
		if not Guard.numeric(axis,-100000,100000): return false
	return true

static func refs(value: Variant) -> bool:
	if value is Dictionary:
		for field in value:
			if field in ["resource_path","path"] and not resource_path(value[field]): return false
			if field == "unit_res_path" and not resource_path(value[field],["units"]): return false
			if field == "res_path" and not resource_path(value[field],["factions"]): return false
			if field == "pos" and not vector(value[field]): return false
			if not refs(value[field]): return false
	elif value is Array:
		for entry in value:
			if not refs(entry): return false
	return true

static func world(data: Dictionary) -> bool:
	for name in ["player_pos","enemy_pos"]:
		if data.has(name) and not vector(data[name]): return false
	if data.has("player_rotation") and not vector(data.player_rotation,2): return false
	for name in ["enemy_alive","armor_pickup_exists"]:
		if data.has(name) and not data[name] is bool: return false
	if data.has("enemy_hp") and not Guard.numeric(data.enemy_hp,0,1000000): return false
	for name in ["pickups","campaign_actors","companions","army_actors"]:
		if not data.has(name): continue
		if not data[name] is Array or data[name].size()>2000: return false
		for actor in data[name]:
			if not actor is Dictionary: return false
			if name == "pickups" and (not resource_path(actor.get("path")) or not Guard.numeric(actor.get("count",1),1,10000,true)): return false
			if name != "pickups" and not actor.has("id"): return false
	return true

static func simulation(data: Dictionary) -> bool:
	for name in ["day","week","population","sick","crisis_days","army_next_id"]:
		if data.has(name) and not Guard.numeric(data[name],0,1000000,true): return false
	for name in ["season","weather"]:
		if data.has(name) and not Guard.numeric(data[name],0,3 if name=="season" else 4,true): return false
	for name in ["seconds","strength_buff","poison"]:
		if data.has(name) and not Guard.numeric(data[name],0,1.0e12): return false
	for name in ["happiness","health"]:
		if data.has(name) and not Guard.numeric(data[name],0,100): return false
	for name in ["jobs","stockpiles","laws","factions","treaties","treaty_expiry","campaign","buildings","timed_effects"]:
		if data.has(name) and not data[name] is Dictionary: return false
	for name in ["army","quests_active","quests_completed"]:
		if data.has(name) and not data[name] is Array: return false
	for name in ["quests_active","quests_completed"]:
		for id in data.get(name,[]):
			if not id is String: return false
	for faction in data.get("factions",{}).values():
		if not faction is Dictionary or not resource_path(faction.get("res_path"),["factions"]): return false
		if not Guard.numeric(faction.get("relationship"),-100,100) or not Guard.numeric(faction.get("threat"),0,1.0e12) or not Guard.numeric(faction.get("escalation_level"),0,5,true): return false
	if data.has("jobs"):
		for job in ["farmers","woodcutters","miners","guards","blacksmiths"]:
			if not Guard.numeric(data.jobs.get(job),0,1000000,true): return false
	if data.has("stockpiles"):
		for stock in ["food","wood","ore","stone","gold"]:
			if not Guard.numeric(data.stockpiles.get(stock),0,1.0e12): return false
	if data.has("laws"):
		if data.laws.get("taxes") not in ["low","normal","high"] or data.laws.get("rations") not in ["half","full"] or data.laws.get("conscription") not in ["voluntary","forced"]: return false
	for squad in data.get("army",[]):
		if not squad is Dictionary or not resource_path(squad.get("unit_res_path"),["units"]): return false
		if not Guard.numeric(squad.get("count"),0,1000000,true) or not Guard.numeric(squad.get("squad_id"),1,1000000,true): return false
		if not Guard.numeric(squad.get("morale"),0,100) or squad.get("order") not in ["follow","hold","attack","retreat"] or squad.get("formation") not in ["line","shield_wall","loose"]: return false
		if not vector(squad.get("target")): return false
	if data.has("campaign"):
		var campaign: Dictionary = data.campaign
		for name in ["visited","roads","deliveries","reports","explored","fallen","conquests","assaults","completed","companions"]:
			if campaign.has(name) and not campaign[name] is Array: return false
			for id in campaign.get(name,[]):
				if not id is String: return false
		for name in ["active","iron_mode","iron_dead"]:
			if campaign.has(name) and not campaign[name] is bool: return false
		if campaign.get("announced_ending","") not in ["","diplomatic","military","mixed"]: return false
		if not Guard.numeric(campaign.get("difficulty",1),0,3,true): return false
		if campaign.has("sieges") and not campaign.sieges is Dictionary: return false
	return true

static func valid(data: Variant) -> bool:
	if not data is Dictionary or not Guard.pure(data,0,[0]) or not refs(data): return false
	for name in ["hp","stamina"]:
		if data.has(name) and not Guard.numeric(data[name],0,10000): return false
	if data.has("inventory"):
		if not data.inventory is Array or data.inventory.size()>1000: return false
		for entry in data.inventory:
			if not item(entry): return false
	if data.has("equipment"):
		if not data.equipment is Dictionary: return false
		for slot in data.equipment:
			if slot not in ["head","torso","legs","weapon"] or not item(data.equipment[slot],slot): return false
	if data.has("world") and (not data.world is Dictionary or not world(data.world)): return false
	if data.has("simulation") and (not data.simulation is Dictionary or not simulation(data.simulation)): return false
	return true
