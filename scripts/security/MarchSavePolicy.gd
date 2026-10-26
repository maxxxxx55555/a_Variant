extends RefCounted
const Guard = preload("res://scripts/security/SaveGuard.gd")
const ITEM_DIRS:Array[String]= ["weapons","armors","potions"]
const COMPANIONS:Array[String]= ["warrior_shield","archer_scout","healer_alchemist","mercenary_commander"]
const TREATIES:Array[String]= ["non_aggression","trade","alliance","peace","defensive_pact"]
const BUILDINGS:Array[String]= ["farm","housing","infirmary","well","market","sawmill","quarry","forge","barracks","hall"]
static func faction_id(value: Variant) -> bool:
	if not value is String:return false
	var id:String=value
	return resource_path("res://data/factions/"+id+".tres",["factions"])
static func resource_path(value: Variant, directories: Array = ITEM_DIRS) -> bool:
	if not value is String:return false
	var path:String=value
	if path.length()>160 or ".." in path or "\\" in path:return false
	for directory:String in directories:
		if path == "res://data/" + directory + "/" + path.get_file() and path.get_extension()=="tres":
			return ResourceLoader.exists(path)
	return false

static func item(value: Variant, slot: String = "") -> bool:
	if value == null: return not slot.is_empty()
	if not value is Dictionary:return false
	var record:Dictionary=value
	if not resource_path(record.get("resource_path")):return false
	if not Guard.numeric(record.get("count",1),1,10000,true): return false
	var path:String=record.resource_path
	var res:Resource=load(path)
	if not res is ItemData: return false
	if slot == "weapon" and not res is WeaponData: return false
	if slot in ["head","torso","legs"] and not res is ArmorData:return false
	if slot in ["head","torso","legs"]:
		var armor:ArmorData=res
		if armor.slot != slot: return false
	if record.has("weight") and not Guard.numeric(record.weight,0,1000): return false
	if record.has("durability") and not Guard.numeric(record.durability,0,100000): return false
	for name:String in ["id","name_key","desc_key","type"]:
		if record.has(name) and not record[name] is String: return false
	if record.has("rarity") and record.rarity not in ["common","uncommon","rare","epic","legendary"]: return false
	return true

static func vector(value: Variant, count: int = 3) -> bool:
	if not value is Array:return false
	var axes:Array=value
	if axes.size()!=count:return false
	for axis:Variant in axes:
		if not Guard.numeric(axis,-100000,100000): return false
	return true

static func refs(value: Variant) -> bool:
	if value is Dictionary:
		for field:Variant in value:
			if field in ["resource_path","path"] and not resource_path(value[field]): return false
			if field == "unit_res_path" and not resource_path(value[field],["units"]): return false
			if field == "res_path" and not resource_path(value[field],["factions"]): return false
			if field == "pos" and not vector(value[field]): return false
			if not refs(value[field]): return false
	elif value is Array:
		for entry:Variant in value:
			if not refs(entry): return false
	return true

static func world(data: Dictionary) -> bool:
	for name:String in ["player_pos","enemy_pos"]:
		if data.has(name) and not vector(data[name]): return false
	if data.has("player_rotation") and not vector(data.player_rotation,2): return false
	for name:String in ["enemy_alive","armor_pickup_exists"]:
		if data.has(name) and not data[name] is bool: return false
	if data.has("enemy_hp") and not Guard.numeric(data.enemy_hp,0,1000000): return false
	for name:String in ["pickups","campaign_actors","companions","army_actors"]:
		if not data.has(name): continue
		if not data[name] is Array:return false
		var actors:Array=data[name]
		if actors.size()>2000:return false
		var seen:Dictionary= {}
		for actor_value:Variant in actors:
			if not actor_value is Dictionary:return false
			var actor:Dictionary=actor_value
			if not vector(actor.get("pos")): return false
			if name == "pickups" and (not resource_path(actor.get("path")) or not Guard.numeric(actor.get("count",1),1,10000,true)): return false
			if name == "campaign_actors":
				if not actor.get("id") is String:return false
				var actor_id:String=actor.id
				if actor_id.is_empty() or actor_id.length()>160:return false
				if not Guard.numeric(actor.get("hp"),0,1000000): return false
				for field:String in ["max_hp","damage","speed","cooldown"]:
					if actor.has(field) and not Guard.numeric(actor[field],-1.0e12 if field=="cooldown" else 0.0,1.0e12): return false
				if actor.has("max_hp") and actor.max_hp<=0: return false
				if actor.has("enraged") and not actor.enraged is bool: return false
			if name == "companions":
				if not actor.get("id") is String or actor.get("id") not in COMPANIONS or not Guard.numeric(actor.get("health"),-1000000,1000000) or not Guard.numeric(actor.get("downed"),-1000,1.0e12): return false
			if name == "army_actors":
				if not Guard.numeric(actor.get("id"),1,1000000,true) or not Guard.numeric(actor.get("index"),0,3,true) or not Guard.numeric(actor.get("health"),-1000000,1000000): return false
			if name != "pickups":
				var key:String= str(actor.id)+":"+str(actor.get("index",0))
				if seen.has(key): return false
				seen[key] = true
	if data.has("tutorial"):
		if not data.tutorial is Dictionary: return false
		var tutorial:Dictionary=data.tutorial
		for flag:Variant in tutorial.values():
			if not flag is bool: return false
	return true

static func simulation(data: Dictionary) -> bool:
	for name:String in ["day","week","population","sick","crisis_days","army_next_id"]:
		if data.has(name) and not Guard.numeric(data[name],0,1000000,true): return false
	for name:String in ["season","weather"]:
		if data.has(name) and not Guard.numeric(data[name],0,3 if name=="season" else 4,true): return false
	for name:String in ["seconds","strength_buff","poison"]:
		if data.has(name) and not Guard.numeric(data[name],0,1.0e12): return false
	for name:String in ["happiness","health"]:
		if data.has(name) and not Guard.numeric(data[name],0,100): return false
	for name:String in ["jobs","stockpiles","laws","factions","treaties","treaty_expiry","campaign","buildings","timed_effects"]:
		if data.has(name) and not data[name] is Dictionary: return false
	for name:String in ["army","quests_active","quests_completed"]:
		if data.has(name) and not data[name] is Array: return false
	for name:String in ["quests_active","quests_completed"]:
		for id:Variant in data.get(name,[]):
			if not id is String: return false
	for id:Variant in data.get("factions",{}):
		var faction_value:Variant=data.factions[id]
		if not faction_value is Dictionary:return false
		var faction:Dictionary=faction_value
		if not resource_path(faction.get("res_path"),["factions"]):return false
		if faction.res_path != "res://data/factions/"+id+".tres": return false
		if not Guard.numeric(faction.get("relationship"),-100,100) or not Guard.numeric(faction.get("threat"),0,1.0e12) or not Guard.numeric(faction.get("escalation_level"),0,5,true): return false
		if faction.has("desired_escalation") and not Guard.numeric(faction.desired_escalation,0,5,true): return false
	for effect:Variant in data.get("timed_effects",{}):
		var entry_value:Variant=data.timed_effects[effect]
		if effect not in ["damage","defense","movement"] or not entry_value is Dictionary:return false
		var entry:Dictionary=entry_value
		if not Guard.numeric(entry.get("seconds"),0,1.0e12) or not Guard.numeric(entry.get("value"),0,100000): return false
	for id:Variant in data.get("buildings",{}):
		if not id is String or id not in BUILDINGS or not Guard.numeric(data.buildings[id],0,3,true): return false
	for id:Variant in data.get("treaties",{}):
		if not faction_id(id) or not data.treaties[id] is Array: return false
		var seen:Dictionary= {}
		for treaty:Variant in data.treaties[id]:
			if not treaty is String or treaty not in TREATIES or seen.has(treaty): return false
			seen[treaty] = true
	for id:Variant in data.get("treaty_expiry",{}):
		if not id is String:return false
		var expiry_key:String=id
		var parts:PackedStringArray=expiry_key.split(":")
		if parts.size()!=2 or not faction_id(parts[0]) or parts[1] not in TREATIES or not Guard.numeric(data.treaty_expiry[id],0,10000000,true): return false
	if data.has("jobs"):
		var jobs:Dictionary=data.jobs
		for job:String in ["farmers","woodcutters","miners","guards","blacksmiths"]:
			if not Guard.numeric(jobs.get(job),0,1000000,true): return false
	if data.has("stockpiles"):
		var stocks:Dictionary=data.stockpiles
		for stock:String in ["food","wood","ore","stone","gold"]:
			if not Guard.numeric(stocks.get(stock),0,1.0e12): return false
	if data.has("laws"):
		var laws:Dictionary=data.laws
		if laws.get("taxes") not in ["low","normal","high"] or laws.get("rations") not in ["half","full"] or laws.get("conscription") not in ["voluntary","forced"]: return false
	var squad_ids:Dictionary= {}
	for squad_value:Variant in data.get("army",[]):
		if not squad_value is Dictionary:return false
		var squad:Dictionary=squad_value
		if not resource_path(squad.get("unit_res_path"),["units"]):return false
		if not Guard.numeric(squad.get("count"),0,1000000,true) or not Guard.numeric(squad.get("squad_id"),1,1000000,true): return false
		if not Guard.numeric(squad.get("morale"),0,100) or squad.get("order") not in ["follow","hold","attack","retreat"] or squad.get("formation") not in ["line","shield_wall","loose"]: return false
		if not vector(squad.get("target")): return false
		if squad_ids.has(squad.squad_id): return false
		squad_ids[squad.squad_id] = true
		for field:String in ["experience_level","low_morale_days"]:
			if squad.has(field) and not Guard.numeric(squad[field],0,1000000,true): return false
	if data.has("campaign"):
		var campaign: Dictionary = data.campaign
		for name:String in ["visited","roads","deliveries","reports","explored","fallen","conquests","assaults","completed","companions"]:
			if campaign.has(name) and not campaign[name] is Array: return false
			for id:Variant in campaign.get(name,[]):
				if not id is String: return false
		for name:String in ["active","iron_mode","iron_dead"]:
			if campaign.has(name) and not campaign[name] is bool: return false
		if campaign.get("announced_ending","") not in ["","diplomatic","military","mixed"]: return false
		if not Guard.numeric(campaign.get("difficulty",1),0,3,true): return false
		if not Guard.numeric(campaign.get("brewed",0),0,10000000,true): return false
		for id:Variant in campaign.get("companions",[]):
			if not id is String or id not in COMPANIONS: return false
		for field:String in ["deliveries","reports","conquests","assaults"]:
			for id:Variant in campaign.get(field,[]):
				if not faction_id(id): return false
		if campaign.has("sieges") and not campaign.sieges is Dictionary: return false
		for id:Variant in campaign.get("sieges",{}):
			var siege_value:Variant=campaign.sieges[id]
			if not faction_id(id) or not siege_value is Dictionary:return false
			var siege:Dictionary=siege_value
			if siege.get("phase","blockade") not in ["blockade","assault","captured"]:return false
			for field:String in ["supplies","morale","wall_hp","days"]:
				if siege.has(field) and not Guard.numeric(siege[field],0,1000000,field=="days"): return false
	return true

static func valid(value:Variant)->bool:
	if not value is Dictionary or not Guard.pure(value,0,[0]) or not refs(value):return false
	var data:Dictionary=value
	for name:String in ["hp","stamina"]:
		if data.has(name) and not Guard.numeric(data[name],0,10000): return false
	if data.has("inventory"):
		if not data.inventory is Array:return false
		var inventory:Array=data.inventory
		if inventory.size()>1000:return false
		for entry:Variant in inventory:
			if not item(entry): return false
	if data.has("equipment"):
		if not data.equipment is Dictionary: return false
		for slot:Variant in data.equipment:
			if slot not in ["head","torso","legs","weapon"]:return false
			var slot_name:String=slot
			if not item(data.equipment[slot],slot_name):return false
	if data.has("world"):
		if not data.world is Dictionary:return false
		var world_data:Dictionary=data.world
		if not world(world_data):return false
	if data.has("simulation"):
		if not data.simulation is Dictionary:return false
		var simulation_data:Dictionary=data.simulation
		if not simulation(simulation_data):return false
	return true
