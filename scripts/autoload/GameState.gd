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
const MAX_INVENTORY_ENTRIES := 1000
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
	for effect in timed_effects.keys():
		timed_effects[effect].seconds -= delta
		if timed_effects[effect].seconds <= 0:
			timed_effects.erase(effect)
			recalculate_stats()
	if poison_timer > 0 and player_hp > 0:
		poison_timer = maxf(0, poison_timer - delta)
		poison_tick += delta
		if poison_tick >= 1:
			poison_tick = 0
			take_damage(2)

func get_damage_modifier() -> float:
	return maxf(1.35 if strength_buff_timer > 0 else 1.0, timed_effects.get("damage", {}).get("value", 1.0))

func clamp_values() -> void:
	max_hp = max(10.0, max_hp)
	player_hp = clamp(player_hp, 0.0, max_hp)
	max_stamina = max(10.0, max_stamina)
	player_stamina = clamp(player_stamina, 0.0, max_stamina)

func recalculate_stats() -> void:
	# Legacy saves may contain only the equipped slots.
	for slot in ["head","torso","legs","weapon"]:
		if not equipment.has(slot): equipment[slot] = null
	var total_def: float = 0.0
	for slot in ["head", "torso", "legs"]:
		var armor = equipment[slot]
		if armor and armor.has("resource_path"):
			var res = load(armor["resource_path"])
			if res and res.get("defense"):
				total_def += res.get("defense") * (0.5 if armor.get("durability", res.get("durability")) <= 0 else 1.0)
	current_defense = max(0.0, total_def + timed_effects.get("defense", {}).get("value", 0.0))

func get_total_weight() -> float:
	var total: float = 0.0
	for item in inventory:
		var w = item.get("weight")
		if w == null:
			w = 0.0
		var cnt = item.get("count", 1)
		total += float(w) * cnt
	for slot in equipment.keys():
		var item = equipment[slot]
		if item:
			var w = item.get("weight")
			if w == null:
				w = 0.0
			total += float(w)
	return total

func is_encumbered() -> bool:
	return get_total_weight() > max_carry_weight

func get_speed_modifier() -> float:
	return (0.6 if is_encumbered() else 1.0) * timed_effects.get("movement", {}).get("value", 1.0) * WeatherSystem.movement_speed_modifier

func stack_index(item_resource: Resource, count: int) -> int:
	if item_resource is WeaponData or item_resource is ArmorData: return -1
	for index in inventory.size():
		if inventory[index].get("resource_path")==item_resource.resource_path and inventory[index].get("count",1)+count<=10000:
			return index
	return -1

func can_add_item(item_resource: Resource, count: int = 1) -> bool:
	return item_resource is ItemData and not item_resource.resource_path.is_empty() and count>0 and count<=10000 and (inventory.size()<MAX_INVENTORY_ENTRIES or stack_index(item_resource,count)>=0)

func item_record(item_resource: Resource, count: int) -> Dictionary:
	var w = item_resource.get("weight")
	if w == null:
		w = 0.0
	var item_dict = {
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
	if item_resource is WeaponData or item_resource is ArmorData:
		item_dict["durability"] = item_resource.durability
	return item_dict

func restore_items(saved_inventory: Array, saved_equipment: Dictionary) -> void:
	inventory = []
	equipment = {"head":null,"torso":null,"legs":null,"weapon":null}
	for entry in saved_inventory:
		var resource: Resource = load(entry.resource_path)
		var normalized := item_record(resource,int(entry.get("count",1)))
		if resource is WeaponData or resource is ArmorData:
			normalized.durability = clampf(entry.get("durability",resource.durability),0,resource.durability)
		inventory.append(normalized)
	for slot in equipment:
		var entry: Variant = saved_equipment.get(slot)
		if entry == null: continue
		var resource: Resource = load(entry.resource_path)
		equipment[slot] = item_record(resource,1)
		equipment[slot].durability = clampf(entry.get("durability",resource.durability),0,resource.durability)

func add_item(item_resource: Resource, count: int = 1) -> bool:
	if count <= 0 or count > 10000: return false
	if not item_resource or not item_resource.resource_path:
		IntegrityLogger.log_anomaly("GameState", "Attempted to add invalid item resource")
		return false
	if not can_add_item(item_resource,count):
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.inventory_full"),true)
		return false
	var item_dict := item_record(item_resource,count)
	var stack := stack_index(item_resource,count)
	if stack >= 0: inventory[stack]["count"] += count
	else: inventory.append(item_dict)
	EventBus.inventory_updated.emit()
	if AudioManager:
		AudioManager.play_sound("pickup")
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.picked_up", {"item": LocalizationManager.get_string(item_resource.get("name_key"))}), false)

	if is_encumbered():
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.encumbered_warning"), true)

	return true

func equip_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item = inventory[item_index]
	var res = load(item.get("resource_path", ""))
	if not res:
		return false

	var type = res.get("type")
	if type == "weapon":
		if equipment["weapon"] != null:
			inventory.append(equipment["weapon"])
		equipment["weapon"] = item
		inventory.remove_at(item_index)
	elif type == "armor":
		var slot = res.get("slot")
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
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.equipped", {"item": LocalizationManager.get_string(res.get("name_key"))}), false)
	return true

func unequip_item(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot] == null:
		return false
	if inventory.size()>=MAX_INVENTORY_ENTRIES:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.inventory_full"),true)
		return false
	var item = equipment[slot]
	equipment[slot] = null
	inventory.append(item)
	recalculate_stats()
	EventBus.inventory_updated.emit()
	EventBus.equipment_updated.emit()
	var res = load(item.get("resource_path", ""))
	if res:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.unequipped", {"item": LocalizationManager.get_string(res.get("name_key"))}), false)
	return true

func repair_item(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item = inventory[item_index]
	var resource: Resource = load(item.resource_path)
	if not (resource is WeaponData or resource is ArmorData):
		return false
	var cost := ceilf(maxf(0, resource.durability - item.get("durability", resource.durability)) * resource.repair_cost_per_point)
	if cost <= 0 or EconomySystem.stockpiles.gold < cost:
		return false
	EconomySystem.stockpiles.gold -= cost
	item["durability"] = resource.durability
	EventBus.inventory_updated.emit()
	if AudioManager:
		AudioManager.play_sound("ui_click")
	var name_key = item.get("name_key", "")
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.repaired", {"item": LocalizationManager.get_string(name_key)}), false)
	return true

func use_potion(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item = inventory[item_index]
	var res = load(item.get("resource_path", ""))
	if not res or res.get("type") != "potion":
		return false

	var useful := false
	var stamina: float = 50.0 if res.id == "stamina_potion" else res.stamina_amount
	if stamina > 0 and player_stamina < max_stamina:
		player_stamina = minf(max_stamina, player_stamina + stamina)
		EventBus.player_stamina_changed.emit(player_stamina, max_stamina)
		useful = true
	if res.heal_amount > 0 and player_hp < max_hp:
		player_hp = minf(max_hp, player_hp + res.heal_amount)
		EventBus.player_hp_changed.emit(player_hp, max_hp)
		useful = true
	var damage_boost: float = 1.35 if res.id == "strength_potion" else res.damage_multiplier
	for entry in [["damage", damage_boost, 1.0], ["defense", res.defense_bonus, 0.0], ["movement", res.movement_multiplier, 1.0]]:
		if entry[1] > entry[2]:
			timed_effects[entry[0]] = {"value": entry[1], "seconds": res.effect_duration}
			useful = true
	if res.id == "antidote_potion" and poison_timer > 0:
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
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.potion_used", {"item": LocalizationManager.get_string(res.get("name_key"))}), false)
	return true

func take_damage(raw_damage: float) -> void:
	var effective_mitigation = current_defense / (current_defense + 100.0)
	var final_damage = max(1.0, raw_damage * (1.0 - effective_mitigation))
	player_hp -= final_damage
	for slot in ["head", "torso", "legs"]:
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
	var item = equipment.get(slot)
	if item:
		var resource = load(item.resource_path)
		item["durability"] = maxf(0, item.get("durability", resource.durability) - amount)
		recalculate_stats()
		EventBus.equipment_updated.emit()

func get_repair_cost() -> float:
	var cost := 0.0
	for item in equipment.values():
		if item:
			var resource = load(item.resource_path)
			cost += maxf(0, resource.durability - item.get("durability", resource.durability)) * resource.repair_cost_per_point
	return ceilf(cost)

func repair_equipment() -> bool:
	var cost := get_repair_cost()
	if cost <= 0 or EconomySystem.stockpiles.gold < cost:
		return false
	EconomySystem.stockpiles.gold -= cost
	for item in equipment.values():
		if item:
			item["durability"] = load(item.resource_path).durability
	recalculate_stats()
	EventBus.equipment_updated.emit()
	EventBus.settlement_updated.emit()
	return true
