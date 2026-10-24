extends Node

var player_hp: float = 100.0
var max_hp: float = 100.0
var player_stamina: float = 100.0
var max_stamina: float = 100.0

var inventory: Array = []
var equipment: Dictionary = {
	"head": null,
	"torso": null,
	"legs": null,
	"weapon": null
}

var current_defense: float = 0.0

func _ready() -> void:
	recalculate_stats()

func clamp_values() -> void:
	max_hp = max(10.0, max_hp)
	player_hp = clamp(player_hp, 0.0, max_hp)
	max_stamina = max(10.0, max_stamina)
	player_stamina = clamp(player_stamina, 0.0, max_stamina)

func recalculate_stats() -> void:
	var total_def: float = 0.0
	for slot in ["head", "torso", "legs"]:
		var armor = equipment[slot]
		if armor and armor.has("resource_path"):
			var res = load(armor["resource_path"])
			if res and res.get("defense"):
				total_def += res.get("defense") * (0.5 if armor.get("durability", res.get("durability")) <= 0 else 1.0)
	current_defense = max(0.0, total_def)

func add_item(item_resource: Resource, count: int = 1) -> bool:
	if not item_resource or not item_resource.resource_path:
		IntegrityLogger.log_anomaly("GameState", "Attempted to add invalid item resource")
		return false
	var item_dict = {
		"id": item_resource.resource_path.get_file().get_basename(),
		"resource_path": item_resource.resource_path,
		"name_key": item_resource.get("name_key"),
		"desc_key": item_resource.get("desc_key"),
		"weight": item_resource.get("weight"),
		"rarity": item_resource.get("rarity"),
		"type": item_resource.get("type"),
		"count": count
	}
	if item_resource is WeaponData or item_resource is ArmorData:
		item_dict["durability"] = item_resource.durability
	inventory.append(item_dict)
	EventBus.inventory_updated.emit()
	if AudioManager:
		AudioManager.play_sound("pickup")
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.picked_up", {"item": LocalizationManager.get_string(item_resource.get("name_key"))}), false)
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

func use_potion(item_index: int) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item = inventory[item_index]
	var res = load(item.get("resource_path", ""))
	if not res or res.get("type") != "potion":
		return false

	var heal = res.get("heal_amount")
	if res.id == "stamina_potion" or heal == 0.0:
		if player_stamina >= max_stamina:
			EventBus.notification_posted.emit("Stamina is already full!", true)
			return false
		player_stamina = min(max_stamina, player_stamina + 50.0)
		EventBus.player_stamina_changed.emit(player_stamina, max_stamina)
	else:
		if player_hp >= max_hp:
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.hp_full"), true)
			return false
		player_hp = min(max_hp, player_hp + heal)
		EventBus.player_hp_changed.emit(player_hp, max_hp)

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
	player_stamina = min(max_stamina, player_stamina + amount)
	clamp_values()
	EventBus.player_stamina_changed.emit(player_stamina, max_stamina)

func consume_stamina(amount: float) -> bool:
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
