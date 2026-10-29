extends Control
const ItemIcons=preload("res://scripts/ui/ItemIcons.gd")
const LootStyle=preload("res://scripts/ui/LootStyle.gd")
const IconView=preload("res://scripts/ui/IconSet.gd")
const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")

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
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.inventory_updated.connect(refresh_inventory)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.equipment_updated.connect(refresh_equipment)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(localize_inventory)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	item_list.item_selected.connect(_on_item_selected)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	equip_button.pressed.connect(_on_equip_pressed)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	use_button.pressed.connect(_on_use_pressed)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	drop_button.pressed.connect(_on_drop_pressed)

	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	head_btn.pressed.connect(func()->void: GameState.unequip_item("head"))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	torso_btn.pressed.connect(func()->void: GameState.unequip_item("torso"))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	legs_btn.pressed.connect(func()->void: GameState.unequip_item("legs"))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	weapon_btn.pressed.connect(func()->void: GameState.unequip_item("weapon"))

	IconView.apply(head_btn,"slot_head",20)
	IconView.apply(torso_btn,"slot_torso",20)
	IconView.apply(legs_btn,"slot_legs",20)
	IconView.apply(weapon_btn,"slot_weapon",20)
	IconView.apply(equip_button,"inventory",20)
	IconView.apply(use_button,"potion",20)
	IconView.apply(drop_button,"close",20)
	refresh_inventory()
	refresh_equipment()

func refresh_inventory() -> void:
	equip_button.text = LocalizationManager.get_string("ui.equip")
	use_button.text = LocalizationManager.get_string("ui.use")
	drop_button.text = LocalizationManager.get_string("ui.drop")
	item_list.fixed_icon_size=Vector2i(36,36)
	item_list.clear()
	for item:Dictionary in GameState.inventory:
		var name_key:String= item.get("name_key", "")
		var count:int= item.get("count", 1)
		var display_name:String= LocalizationManager.get_string(name_key)
		if count > 1:
			display_name += " x" + str(count)
		# This list owns the row; selection is managed separately.
		@warning_ignore("return_value_discarded")
		item_list.add_item(display_name,ItemIcons.for_record(item))
		item_list.set_item_custom_fg_color(item_list.item_count - 1, LootStyle.color_for(item))
	clear_card()

func refresh_equipment() -> void:
	head_btn.text = get_slot_text("head")
	torso_btn.text = get_slot_text("torso")
	legs_btn.text = get_slot_text("legs")
	weapon_btn.text = get_slot_text("weapon")
	_refresh_equipment_slot(head_btn, "head")
	_refresh_equipment_slot(torso_btn, "torso")
	_refresh_equipment_slot(legs_btn, "legs")
	_refresh_equipment_slot(weapon_btn, "weapon")

func _refresh_equipment_slot(button:Button, slot_name:String) -> void:
	var slot_record:Variant=GameState.equipment.get(slot_name)
	button.disabled=slot_record==null
	button.tooltip_text=LocalizationManager.get_string("ui.empty" if button.disabled else "ui.unequip")
	var slot_color:Color = Color("E8DCC3") if slot_record == null else LootStyle.color_for(slot_record)
	button.add_theme_color_override("font_color", slot_color)
	button.add_theme_color_override("font_hover_color", slot_color.lightened(0.2))
	button.add_theme_color_override("font_focus_color", slot_color)
	button.add_theme_color_override("icon_normal_color", slot_color)
	button.add_theme_color_override("icon_hover_color", slot_color.lightened(0.2))
	button.add_theme_color_override("icon_disabled_color", Color("61717a"))
	_apply_slot_surface(button, slot_color if slot_record != null else ThemeRef.EDGE)

func _apply_slot_surface(button: Button, accent: Color) -> void:
	var normal:StyleBoxFlat=ThemeRef.panel(Color(0.09,0.11,0.13,0.94),accent)
	normal.set_border_width_all(2)
	var hover:StyleBoxFlat=ThemeRef.panel(Color(0.13,0.16,0.19,0.96),accent.lightened(0.18))
	hover.set_border_width_all(2)
	button.add_theme_stylebox_override("normal",normal)
	button.add_theme_stylebox_override("hover",hover)
	button.add_theme_stylebox_override("pressed",ThemeRef.panel(Color(0.07,0.09,0.11,0.98),accent))

func get_slot_text(slot_name: String) -> String:
	var slot_title:String= LocalizationManager.get_string("ui.slot_" + slot_name)
	var eq:Dictionary={}
	if GameState.equipment.get(slot_name)!=null:eq=GameState.equipment.get(slot_name)
	if eq and eq.get("resource_path"):
		var path:String=eq.get("resource_path")
		var res:ItemData=load(path) as ItemData
		if res:
			var item_name:String= LocalizationManager.get_string(str(res.get("name_key")))
			return slot_title + ": " + item_name + " [" + LocalizationManager.get_string("ui.unequip") + "]"
	return slot_title + ": [" + LocalizationManager.get_string("ui.empty") + "]"

func _on_item_selected(index: int) -> void:
	selected_index = index
	update_card(index)

func update_card(index: int) -> void:
	if index < 0 or index >= GameState.inventory.size():
		clear_card()
		return

	var item:Dictionary=GameState.inventory[index]
	var path:String=item.get("resource_path","")
	var res:ItemData=load(path) as ItemData
	if not res:
		clear_card()
		return

	var name_str:String= LocalizationManager.get_string(str(res.get("name_key")))
	var desc_str:String= LocalizationManager.get_string(str(res.get("desc_key")))
	var type_str:String= res.get("type")
	var weight:float= res.get("weight")
	var rarity:String= res.get("rarity")

	var text:String= "[b]" + name_str + "[/b]\n"
	text += LocalizationManager.get_string("ui.stats.rarity") + ": [color=#" + LootStyle.color_of(rarity).to_html(false) + "]" + LocalizationManager.get_string("ui.rarity." + rarity) + "[/color]\n"
	text += LocalizationManager.get_string("ui.stats.weight") + ": " + str(weight) + " " + LocalizationManager.get_string("ui.unit.weight") + "\n\n"
	text += desc_str + "\n\n"
	if res is WeaponData or res is ArmorData:
		var equipment:EquipmentData=res
		text += LocalizationManager.get_string("ui.stats.durability") + ": " + str(item.get("durability", equipment.durability)) + "/" + str(equipment.durability) + "\n"

	# Stat comparisons
	equip_button.visible = false
	use_button.visible = false
	if type_str == "weapon":
		var dmg:float= res.get("damage")
		var spd:float= res.get("speed")
		var reach:float= res.get("reach")
		var stamina_cost:float= res.get("stamina_cost")

		var equipped_weapon:Dictionary={}
		if GameState.equipment.get("weapon")!=null:equipped_weapon=GameState.equipment.get("weapon")
		var curr_dmg:float= 0.0
		var curr_spd:float= 1.0
		var curr_reach:float= 2.0
		var curr_stamina:float= 10.0
		if equipped_weapon and equipped_weapon.get("resource_path"):
			var equipped_path:String=equipped_weapon.get("resource_path")
			var eq_res:WeaponData=load(equipped_path) as WeaponData
			if eq_res:
				curr_dmg = eq_res.get("damage")
				curr_spd = eq_res.get("speed")
				curr_reach = eq_res.get("reach")
				curr_stamina = eq_res.get("stamina_cost")

		var d_dmg:float= dmg - curr_dmg
		text += LocalizationManager.get_string("ui.stats.damage") + ": " + str(dmg) + " (" + format_delta(d_dmg, true) + ")\n"
		var d_spd:float= spd - curr_spd
		text += LocalizationManager.get_string("ui.stats.speed") + ": " + str(spd) + " (" + format_delta(d_spd, true) + ")\n"
		var d_reach:float= reach - curr_reach
		text += LocalizationManager.get_string("ui.stats.reach") + ": " + str(reach) + " " + LocalizationManager.get_string("ui.unit.reach") + " (" + format_delta(d_reach, true) + ")\n"
		var d_stamina:float= stamina_cost - curr_stamina
		text += LocalizationManager.get_string("ui.stats.stamina_cost") + ": " + str(stamina_cost) + " (" + format_delta(-d_stamina, true) + ")\n"

		equip_button.visible = true
		use_button.visible = false
	elif type_str == "armor":
		var def:float= res.get("defense")
		var slot:String= res.get("slot")
		var equipped_armor:Dictionary={}
		if GameState.equipment.get(slot)!=null:equipped_armor=GameState.equipment.get(slot)
		var current_def:float= 0.0
		if equipped_armor and equipped_armor.get("resource_path"):
			var equipped_path:String=equipped_armor.get("resource_path")
			var eq_res:ArmorData=load(equipped_path) as ArmorData
			if eq_res:
				current_def = eq_res.get("defense")
		var delta:float= def - current_def
		text += LocalizationManager.get_string("ui.stats.defense") + ": " + str(def) + " (" + format_delta(delta, true) + ")\n"
		equip_button.visible = true
		use_button.visible = false
	elif type_str == "potion":
		var heal:float= res.get("heal_amount")
		text += LocalizationManager.get_string("ui.stats.heal_amount") + ": +" + str(heal) + " " + LocalizationManager.get_string("ui.unit.health") + "\n"
		equip_button.visible = false
		use_button.visible = true

	drop_button.visible = true
	item_card_label.text = text

func format_delta(delta: float, higher_is_better: bool) -> String:
	var sign_str:String= "+" if delta >= 0 else ""
	var color_str:String= "[color=green]" if (delta >= 0 if higher_is_better else delta <= 0) else "[color=red]"
	return color_str + sign_str + str(snapped(delta, 0.1)) + "[/color]"

func clear_card() -> void:
	item_card_label.text = ""
	equip_button.visible = false
	use_button.visible = false
	drop_button.visible = false
	selected_index = -1

func _on_equip_pressed() -> void:
	if selected_index >= 0:
		# The system emits the localized result and owns success audio; no additional UI transaction follows.
		@warning_ignore("return_value_discarded")
		GameState.equip_item(selected_index)

func _on_use_pressed() -> void:
	if selected_index >= 0:
		# The system emits the localized result and owns success audio; no additional UI transaction follows.
		@warning_ignore("return_value_discarded")
		GameState.use_potion(selected_index)

func _on_drop_pressed() -> void:
	if selected_index >= 0 and selected_index < GameState.inventory.size():
		GameState.inventory.remove_at(selected_index)
		selected_index = -1
		clear_card()
		EventBus.inventory_updated.emit()

func localize_inventory(_language:String) -> void:
	var selection:int=selected_index
	refresh_inventory()
	refresh_equipment()
	if selection>=0 and selection<GameState.inventory.size():
		item_list.select(selection)
		_on_item_selected(selection)
