extends RefCounted
const Guard = preload("res://scripts/security/SaveGuard.gd")
const ITEM_DIRS := ["weapons","armors","potions"]
const COMPANIONS := ["warrior_shield","archer_scout","healer_alchemist","mercenary_commander"]
const TREATIES := ["non_aggression","trade","alliance","peace","defensive_pact"]
const BUILDINGS := ["farm","housing","infirmary","well","market","sawmill","quarry","forge","barracks","hall"]
static func faction_id(value: Variant) -> bool:
	return value is String and resource_path("res://data/factions/"+value+".tres",["factions"])
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
	for name in ["id","name_key","desc_key","type"]:
		if value.has(name) and not value[name] is String: return false
	if value.has("rarity") and value.rarity not in ["common","uncommon","rare","epic","legendary"]: return false
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
		var seen := {}
		for actor in data[name]:
			if not actor is Dictionary: return false
			if not vector(actor.get("pos")): return false
			if name == "pickups" and (not resource_path(actor.get("path")) or not Guard.numeric(actor.get("count",1),1,10000,true)): return false
			if name == "campaign_actors":
				if not actor.get("id") is String or actor.id.is_empty() or actor.id.length()>160: return false
				if not Guard.numeric(actor.get("hp"),0,1000000): return false
				for field in ["max_hp","damage","speed","cooldown"]:
					if actor.has(field) and not Guard.numeric(actor[field],-1.0e12 if field=="cooldown" else 0,1.0e12): return false
				if actor.has("max_hp") and actor.max_hp<=0: return false
				if actor.has("enraged") and not actor.enraged is bool: return false
			if name == "companions":
				if actor.get("id") not in COMPANIONS or not Guard.numeric(actor.get("health"),-1000000,1000000) or not Guard.numeric(actor.get("downed"),-1000,1.0e12): return false
			if name == "army_actors":
				if not Guard.numeric(actor.get("id"),1,1000000,true) or not Guard.numeric(actor.get("index"),0,3,true) or not Guard.numeric(actor.get("health"),-1000000,1000000): return false
			if name != "pickups":
				var key := str(actor.id)+":"+str(actor.get("index",0))
				if seen.has(key): return false
				seen[key] = true
	if data.has("tutorial"):
		if not data.tutorial is Dictionary: return false
		for flag in data.tutorial.values():
			if not flag is bool: return false
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
	for id in data.get("factions",{}):
		var faction: Variant = data.factions[id]
		if not faction is Dictionary or not resource_path(faction.get("res_path"),["factions"]): return false
		if faction.res_path != "res://data/factions/"+id+".tres": return false
		if not Guard.numeric(faction.get("relationship"),-100,100) or not Guard.numeric(faction.get("threat"),0,1.0e12) or not Guard.numeric(faction.get("escalation_level"),0,5,true): return false
		if faction.has("desired_escalation") and not Guard.numeric(faction.desired_escalation,0,5,true): return false
	for effect in data.get("timed_effects",{}):
		var entry: Variant = data.timed_effects[effect]
		if effect not in ["damage","defense","movement"] or not entry is Dictionary: return false
		if not Guard.numeric(entry.get("seconds"),0,1.0e12) or not Guard.numeric(entry.get("value"),0,100000): return false
	for id in data.get("buildings",{}):
		if id not in BUILDINGS or not Guard.numeric(data.buildings[id],0,3,true): return false
	for id in data.get("treaties",{}):
		if not faction_id(id) or not data.treaties[id] is Array: return false
		var seen := {}
		for treaty in data.treaties[id]:
			if treaty not in TREATIES or seen.has(treaty): return false
			seen[treaty] = true
	for id in data.get("treaty_expiry",{}):
		var parts: PackedStringArray = id.split(":")
		if parts.size()!=2 or not faction_id(parts[0]) or parts[1] not in TREATIES or not Guard.numeric(data.treaty_expiry[id],0,10000000,true): return false
	if data.has("jobs"):
		for job in ["farmers","woodcutters","miners","guards","blacksmiths"]:
			if not Guard.numeric(data.jobs.get(job),0,1000000,true): return false
	if data.has("stockpiles"):
		for stock in ["food","wood","ore","stone","gold"]:
			if not Guard.numeric(data.stockpiles.get(stock),0,1.0e12): return false
	if data.has("laws"):
		if data.laws.get("taxes") not in ["low","normal","high"] or data.laws.get("rations") not in ["half","full"] or data.laws.get("conscription") not in ["voluntary","forced"]: return false
	var squad_ids := {}
	for squad in data.get("army",[]):
		if not squad is Dictionary or not resource_path(squad.get("unit_res_path"),["units"]): return false
		if not Guard.numeric(squad.get("count"),0,1000000,true) or not Guard.numeric(squad.get("squad_id"),1,1000000,true): return false
		if not Guard.numeric(squad.get("morale"),0,100) or squad.get("order") not in ["follow","hold","attack","retreat"] or squad.get("formation") not in ["line","shield_wall","loose"]: return false
		if not vector(squad.get("target")): return false
		if squad_ids.has(squad.squad_id): return false
		squad_ids[squad.squad_id] = true
		for field in ["experience_level","low_morale_days"]:
			if squad.has(field) and not Guard.numeric(squad[field],0,1000000,true): return false
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
		if not Guard.numeric(campaign.get("brewed",0),0,10000000,true): return false
		for id in campaign.get("companions",[]):
			if id not in COMPANIONS: return false
		for field in ["deliveries","reports","conquests","assaults"]:
			for id in campaign.get(field,[]):
				if not faction_id(id): return false
		if campaign.has("sieges") and not campaign.sieges is Dictionary: return false
		for id in campaign.get("sieges",{}):
			var siege: Variant = campaign.sieges[id]
			if not faction_id(id) or not siege is Dictionary or siege.get("phase","blockade") not in ["blockade","assault","captured"]: return false
			for field in ["supplies","morale","wall_hp","days"]:
				if siege.has(field) and not Guard.numeric(siege[field],0,1000000,field=="days"): return false
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
