extends Node

var player_hp: float = 100.0
var max_hp: float = 100.0
var player_stamina: float = 100.0
var max_stamina: float = 100.0

var max_carry_weight: float = 40.0
var strength_buff_timer: float = 0.0
var timed_effects: Dictionary = {}
var poison_timer: float = 0.0
var poison_tick: float = 0.0

var inventory: Array = []
const MAX_INVENTORY_ENTRIES:int= 1000
var equipment: Dictionary = {
	"head": null,
	"torso": null,
	"legs": null,
	"weapon": null
}

var current_defense: float = 0.0

func _ready() -> void:
	recalculate_stats()

func _process(delta: float) -> void:
	if strength_buff_timer > 0:
		strength_buff_timer = maxf(0,strength_buff_timer-delta)
	for effect:Variant in timed_effects.keys():
		timed_effects[effect].seconds -= delta
		if timed_effects[effect].seconds <= 0:
			# Expiration is idempotent if another effect listener already removed the key.
			@warning_ignore("return_value_discarded")
			timed_effects.erase(effect)
			recalculate_stats()
	if poison_timer > 0 and player_hp > 0:
		poison_timer = maxf(0, poison_timer - delta)
		poison_tick += delta
		if poison_tick >= 1:
			poison_tick = 0
			take_damage(2)

func get_damage_modifier() -> float:
	return maxf(1.35 if strength_buff_timer > 0 else 1.0, effect_value("damage",1.0))

func clamp_values() -> void:
	max_hp = max(10.0, max_hp)
	player_hp = clamp(player_hp, 0.0, max_hp)
	max_stamina = max(10.0, max_stamina)
	player_stamina = clamp(player_stamina, 0.0, max_stamina)

func recalculate_stats() -> void:
	# Legacy saves may contain only the equipped slots.
	for slot:String in ["head","torso","legs","weapon"]:
		if not equipment.has(slot): equipment[slot] = null
	var total_def: float = 0.0
	for slot:String in ["head", "torso", "legs"]:
		var armor:Dictionary=equipment[slot] if equipment[slot]!=null else {}
		if armor and armor.has("resource_path"):
			var res:ArmorData=load(str(armor["resource_path"])) as ArmorData
			if res and res.get("defense"):
				total_def += res.defense*(0.5 if armor.get("durability",res.durability)<=0 else 1.0)
	current_defense = maxf(0.0,total_def+effect_value("defense",0.0))

func get_total_weight() -> float:
	var total: float = 0.0
	for item:Dictionary in inventory:
		var w:float=0.0
		if item.get("weight")!=null:w=item.get("weight")
		var cnt:int=item.get("count",1)
		total += float(w) * cnt
	for slot:String in equipment.keys():
		var item:Dictionary=equipment[slot] if equipment[slot]!=null else {}
		if item:
			var w:float=0.0
			if item.get("weight")!=null:w=item.get("weight")
			total += float(w)
	return total

func is_encumbered() -> bool:
	return get_total_weight() > max_carry_weight

func get_speed_modifier() -> float:
	return (0.6 if is_encumbered() else 1.0) * effect_value("movement",1.0) * WeatherSystem.movement_speed_modifier

func stack_index(item_resource: Resource, count: int) -> int:
	if item_resource is EquipmentData: return -1
	for index:int in inventory.size():
		var item:Dictionary=inventory[index]
		if item.get("resource_path")==item_resource.resource_path and item.get("count",1)+count<=10000:
			return index
	return -1

func can_add_item(item_resource: Resource, count: int = 1) -> bool:
	return item_resource is ItemData and not item_resource.resource_path.is_empty() and count>0 and count<=10000 and (inventory.size()<MAX_INVENTORY_ENTRIES or stack_index(item_resource,count)>=0)

func item_record(item_resource: Resource, count: int) -> Dictionary:
	var data:ItemData=item_resource as ItemData
	if data==null:return {}
	var w:float=data.weight
	var item_dict:Dictionary= {
		"id": item_resource.resource_path.get_file().get_basename(),
		"resource_path": item_resource.resource_path,
		"name_key": item_resource.get("name_key"),
		"desc_key": item_resource.get("desc_key"),
		"weight": float(w),
		"rarity": item_resource.get("rarity"),
		"type": item_resource.get("type"),
		"durability": item_resource.get("durability") if item_resource.get("durability") != null else 100.0,
		"count": count
	}
	if item_resource is EquipmentData:
		item_dict["durability"] = (item_resource as EquipmentData).durability
	return item_dict

func restore_items(saved_inventory: Array, saved_equipment: Dictionary) -> void:
	inventory = []
	equipment = {"head":null,"torso":null,"legs":null,"weapon":null}
	for entry:Dictionary in saved_inventory:
		var resource:ItemData=load(str(entry.resource_path)) as ItemData
		var count:int=entry.get("count",1)
		var normalized:Dictionary=item_record(resource,count)
		if resource is EquipmentData:
			var equipped:EquipmentData=resource as EquipmentData
			var durability:float=entry.get("durability",equipped.durability)
			normalized.durability=clampf(durability,0,equipped.durability)
		inventory.append(normalized)
	for slot:String in equipment:
		if saved_equipment.get(slot)==null:continue
		var entry:Dictionary=saved_equipment[slot]
		var resource:ItemData=load(str(entry.resource_path)) as ItemData
		equipment[slot] = item_record(resource,1)
		var equipped:EquipmentData=resource as EquipmentData
		var durability:float=entry.get("durability",equipped.durability)
		equipment[slot].durability=clampf(durability,0,equipped.durability)

func add_item(item_resource: Resource, count: int = 1) -> bool:
	if count <= 0 or count > 10000: return false
	if not item_resource or not item_resource.resource_path:
		IntegrityLogger.log_anomaly("GameState", "Attempted to add invalid item resource")
		return false
	if not can_add_item(item_resource,count):
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.inventory_full"),true)
		return false
	var item_dict:Dictionary= item_record(item_resource,count)
	var stack:int= stack_index(item_resource,count)
	if stack >= 0: inventory[stack]["count"] += count
	else: inventory.append(item_dict)
	EventBus.inventory_updated.emit()
	if AudioManager:
		AudioManager.play_sound("pickup")
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.picked_up", {"item": LocalizationManager.get_string(str(item_resource.get("name_key")))}), false)

	if is_encumbered():
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.encumbered_warning"), true)

	return true

func equip_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item:Dictionary=inventory[item_index]
	var res:ItemData=load(str(item.get("resource_path",""))) as ItemData
	if not res:
		return false

	var type:String=res.type
	if type == "weapon":
		if equipment["weapon"] != null:
			inventory.append(equipment["weapon"])
		equipment["weapon"] = item
		inventory.remove_at(item_index)
	elif type == "armor":
		var armor:ArmorData=res as ArmorData
		if armor==null:return false
		var slot:String=armor.slot
		if slot in ["head", "torso", "legs"]:
			if equipment[slot] != null:
				inventory.append(equipment[slot])
			equipment[slot] = item
			inventory.remove_at(item_index)
	else:
		return false

	recalculate_stats()
	EventBus.inventory_updated.emit()
	EventBus.equipment_updated.emit()
	if AudioManager:
		AudioManager.play_sound("ui_click")
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.equipped", {"item": LocalizationManager.get_string(res.name_key)}), false)
	return true

func unequip_item(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot] == null:
		return false
	if inventory.size()>=MAX_INVENTORY_ENTRIES:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.inventory_full"),true)
		return false
	var item:Dictionary=equipment[slot] if equipment[slot]!=null else {}
	equipment[slot] = null
	inventory.append(item)
	recalculate_stats()
	EventBus.inventory_updated.emit()
	EventBus.equipment_updated.emit()
	var res:ItemData=load(str(item.get("resource_path",""))) as ItemData
	if res:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.unequipped", {"item": LocalizationManager.get_string(res.name_key)}), false)
	return true

func use_potion(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item:Dictionary=inventory[item_index]
	var res:ItemData=load(str(item.get("resource_path",""))) as ItemData
	var potion:PotionData=res as PotionData
	if potion==null or potion.type!="potion":
		return false

	var useful:bool= false
	var stamina: float = 50.0 if potion.id == "stamina_potion" else potion.stamina_amount
	if stamina > 0 and player_stamina < max_stamina:
		player_stamina = minf(max_stamina, player_stamina + stamina)
		EventBus.player_stamina_changed.emit(player_stamina, max_stamina)
		useful = true
	if potion.heal_amount > 0 and player_hp < max_hp:
		player_hp = minf(max_hp, player_hp + potion.heal_amount)
		EventBus.player_hp_changed.emit(player_hp, max_hp)
		useful = true
	var damage_boost: float = 1.35 if potion.id == "strength_potion" else potion.damage_multiplier
	for entry:Variant in [["damage", damage_boost, 1.0], ["defense", potion.defense_bonus, 0.0], ["movement", potion.movement_multiplier, 1.0]]:
		if entry[1] > entry[2]:
			timed_effects[entry[0]] = {"value": entry[1], "seconds": potion.effect_duration}
			useful = true
	if potion.id == "antidote_potion" and poison_timer > 0:
		poison_timer = 0
		useful = true
	if not useful:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.hp_full"), true)
		return false
	recalculate_stats()

	if AudioManager:
		AudioManager.play_sound("potion")

	item["count"] -= 1
	if item["count"] <= 0:
		inventory.remove_at(item_index)

	EventBus.inventory_updated.emit()
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.potion_used", {"item": LocalizationManager.get_string(res.name_key)}), false)
	return true

func take_damage(raw_damage: float) -> void:
	if not is_finite(raw_damage) or raw_damage<=0:return
	var effective_mitigation:float= current_defense / (current_defense + 100.0)
	var final_damage:float=maxf(1.0, raw_damage * (1.0 - effective_mitigation))
	player_hp -= final_damage
	for slot:String in ["head", "torso", "legs"]:
		wear_equipment(slot, 1.0)
	clamp_values()
	EventBus.player_hp_changed.emit(player_hp, max_hp)
	if player_hp <= 0:
		EventBus.player_died.emit()

func restore_stamina(amount: float) -> void:
	if not is_finite(amount) or amount < 0: return
	player_stamina = min(max_stamina, player_stamina + amount)
	clamp_values()
	EventBus.player_stamina_changed.emit(player_stamina, max_stamina)

func consume_stamina(amount: float) -> bool:
	if not is_finite(amount) or amount < 0: return false
	if player_stamina >= amount:
		player_stamina -= amount
		clamp_values()
		EventBus.player_stamina_changed.emit(player_stamina, max_stamina)
		return true
	return false

func wear_equipment(slot: String, amount: float) -> void:
	if not is_finite(amount) or amount<=0:return
	var item:Dictionary=equipment.get(slot) if equipment.get(slot)!=null else {}
	if item:
		var resource:EquipmentData=load(str(item.resource_path)) as EquipmentData
		var remaining:float=item.get("durability",resource.durability)
		item["durability"]=maxf(0,remaining-amount)
		recalculate_stats()
		EventBus.equipment_updated.emit()

func get_repair_cost() -> float:
	var cost:float= 0.0
	for value:Variant in equipment.values():
		var item:Dictionary=value if value!=null else {}
		if item:
			var resource:EquipmentData=load(str(item.resource_path)) as EquipmentData
			var remaining:float=item.get("durability",resource.durability)
			cost+=maxf(0,resource.durability-remaining)*resource.repair_cost_per_point
	return ceilf(cost)

func repair_equipment() -> bool:
	var cost:float= get_repair_cost()
	if cost <= 0 or EconomySystem.stockpiles.gold < cost:
		return false
	EconomySystem.stockpiles.gold -= cost
	for value:Variant in equipment.values():
		var item:Dictionary=value if value!=null else {}
		if item:
			var resource:EquipmentData=load(str(item.resource_path)) as EquipmentData
			item["durability"]=resource.durability
	recalculate_stats()
	EventBus.equipment_updated.emit()
	EventBus.settlement_updated.emit()
	return true

func effect_value(key:String,fallback:float)->float:
	var effect:Dictionary=timed_effects.get(key,{})
	var amount:float=effect.get("value",fallback)
	return amount
