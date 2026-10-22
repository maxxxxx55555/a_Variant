extends Control

@onready var item_list: ItemList = $MarginContainer/HBoxContainer/LeftPanel/ItemList
@onready var item_card_label: RichTextLabel = $MarginContainer/HBoxContainer/RightPanel/ItemCardLabel
@onready var equip_button: Button = $MarginContainer/HBoxContainer/RightPanel/ButtonContainer/EquipButton
@onready var use_button: Button = $MarginContainer/HBoxContainer/RightPanel/ButtonContainer/UseButton
@onready var drop_button: Button = $MarginContainer/HBoxContainer/RightPanel/ButtonContainer/DropButton

@onready var head_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/EquipSlots/HeadBtn
@onready var torso_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/EquipSlots/TorsoBtn
@onready var legs_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/EquipSlots/LegsBtn
@onready var weapon_btn: Button = $MarginContainer/HBoxContainer/LeftPanel/EquipSlots/WeaponBtn

var selected_index: int = -1

func _ready() -> void:
	EventBus.inventory_updated.connect(refresh_inventory)
	EventBus.equipment_updated.connect(refresh_equipment)
	EventBus.language_changed.connect(func(_lang): refresh_inventory(); refresh_equipment())
	item_list.item_selected.connect(_on_item_selected)
	equip_button.pressed.connect(_on_equip_pressed)
	use_button.pressed.connect(_on_use_pressed)
	drop_button.pressed.connect(_on_drop_pressed)

	head_btn.pressed.connect(func(): GameState.unequip_item("head"))
	torso_btn.pressed.connect(func(): GameState.unequip_item("torso"))
	legs_btn.pressed.connect(func(): GameState.unequip_item("legs"))
	weapon_btn.pressed.connect(func(): GameState.unequip_item("weapon"))

	refresh_inventory()
	refresh_equipment()

func refresh_inventory() -> void:
	item_list.clear()
	for item in GameState.inventory:
		var name_key = item.get("name_key", "")
		var count = item.get("count", 1)
		var display_name = LocalizationManager.get_string(name_key)
		if count > 1:
			display_name += " x" + str(count)
		item_list.add_item(display_name)
	clear_card()

func refresh_equipment() -> void:
	head_btn.text = get_slot_text("head")
	torso_btn.text = get_slot_text("torso")
	legs_btn.text = get_slot_text("legs")
	weapon_btn.text = get_slot_text("weapon")

func get_slot_text(slot_name: String) -> String:
	var slot_title = LocalizationManager.get_string("ui.slot_" + slot_name)
	var eq = GameState.equipment.get(slot_name)
	if eq and eq.get("resource_path"):
		var res = load(eq.get("resource_path"))
		if res:
			var item_name = LocalizationManager.get_string(res.get("name_key"))
			return slot_title + ": " + item_name + " [" + LocalizationManager.get_string("ui.unequip") + "]"
	return slot_title + ": [None]"

func _on_item_selected(index: int) -> void:
	selected_index = index
	update_card(index)

func update_card(index: int) -> void:
	if index < 0 or index >= GameState.inventory.size():
		clear_card()
		return

	var item = GameState.inventory[index]
	var res = load(item.get("resource_path", ""))
	if not res:
		clear_card()
		return

	var name_str = LocalizationManager.get_string(res.get("name_key"))
	var desc_str = LocalizationManager.get_string(res.get("desc_key"))
	var type_str = res.get("type")
	var weight = res.get("weight")
	var rarity = res.get("rarity")

	var text = "[b]" + name_str + "[/b]\n"
	text += LocalizationManager.get_string("ui.stats.rarity") + ": " + LocalizationManager.get_string("ui.rarity." + rarity) + "\n"
	text += LocalizationManager.get_string("ui.stats.weight") + ": " + str(weight) + " kg\n\n"
	text += desc_str + "\n\n"

	# Stat comparisons
	if type_str == "weapon":
		var dmg = res.get("damage")
		var spd = res.get("speed")
		var reach = res.get("reach")
		var stamina_cost = res.get("stamina_cost")

		var equipped_weapon = GameState.equipment.get("weapon")
		var curr_dmg = 0.0
		var curr_spd = 1.0
		var curr_reach = 2.0
		var curr_stamina = 10.0
		if equipped_weapon and equipped_weapon.get("resource_path"):
			var eq_res = load(equipped_weapon.get("resource_path"))
			if eq_res:
				curr_dmg = eq_res.get("damage")
				curr_spd = eq_res.get("speed")
				curr_reach = eq_res.get("reach")
				curr_stamina = eq_res.get("stamina_cost")

		var d_dmg = dmg - curr_dmg
		text += LocalizationManager.get_string("ui.stats.damage") + ": " + str(dmg) + " (" + format_delta(d_dmg, true) + ")\n"
		var d_spd = spd - curr_spd
		text += LocalizationManager.get_string("ui.stats.speed") + ": " + str(spd) + " (" + format_delta(d_spd, true) + ")\n"
		var d_reach = reach - curr_reach
		text += LocalizationManager.get_string("ui.stats.reach") + ": " + str(reach) + " m (" + format_delta(d_reach, true) + ")\n"
		var d_stamina = stamina_cost - curr_stamina
		text += LocalizationManager.get_string("ui.stats.stamina_cost") + ": " + str(stamina_cost) + " (" + format_delta(-d_stamina, true) + ")\n"

		equip_button.visible = true
		use_button.visible = false
	elif type_str == "armor":
		var def = res.get("defense")
		var slot = res.get("slot")
		var equipped_armor = GameState.equipment.get(slot)
		var current_def = 0.0
		if equipped_armor and equipped_armor.get("resource_path"):
			var eq_res = load(equipped_armor.get("resource_path"))
			if eq_res:
				current_def = eq_res.get("defense")
		var delta = def - current_def
		text += LocalizationManager.get_string("ui.stats.defense") + ": " + str(def) + " (" + format_delta(delta, true) + ")\n"
		equip_button.visible = true
		use_button.visible = false
	elif type_str == "potion":
		var heal = res.get("heal_amount")
		text += LocalizationManager.get_string("ui.stats.heal_amount") + ": +" + str(heal) + " HP\n"
		equip_button.visible = false
		use_button.visible = true

	drop_button.visible = true
	item_card_label.text = text

func format_delta(delta: float, higher_is_better: bool) -> String:
	var sign_str = "+" if delta >= 0 else ""
	var color_str = "[color=green]" if (delta >= 0 if higher_is_better else delta <= 0) else "[color=red]"
	return color_str + sign_str + str(snapped(delta, 0.1)) + "[/color]"

func clear_card() -> void:
	item_card_label.text = ""
	equip_button.visible = false
	use_button.visible = false
	drop_button.visible = false
	selected_index = -1

func _on_equip_pressed() -> void:
	if selected_index >= 0:
		GameState.equip_item(selected_index)

func _on_use_pressed() -> void:
	if selected_index >= 0:
		GameState.use_potion(selected_index)

func _on_drop_pressed() -> void:
	if selected_index >= 0 and selected_index < GameState.inventory.size():
		GameState.inventory.remove_at(selected_index)
		selected_index = -1
		clear_card()
		EventBus.inventory_updated.emit()
