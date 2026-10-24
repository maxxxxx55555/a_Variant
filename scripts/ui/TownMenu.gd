extends PanelContainer

var town_id: String = ""
var title_label: Label
var description: RichTextLabel
var resources_label: Label
var delivery_button: Button
var report_button: Button
var assault_button: Button
var blockade_button: Button
var wait_button: Button
var surrender_button: Button
var retreat_button: Button
var siege_status: Label
var message: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("191f20")
	style.content_margin_left = 70
	style.content_margin_right = 70
	style.content_margin_top = 45
	style.content_margin_bottom = 45
	add_theme_stylebox_override("panel", style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 34)
	header.add_child(title_label)
	action(header, "ui.close", func(): get_tree().current_scene.toggle_pause())
	description = RichTextLabel.new()
	description.custom_minimum_size.y = 190
	description.bbcode_enabled = true
	column.add_child(description)
	resources_label = Label.new()
	column.add_child(resources_label)
	delivery_button = action(column, "ui.deliver", func():
		var ok := CampaignSystem.deliver_supplies(CampaignSystem.town(town_id).faction)
		message.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.treaty_failed")
		refresh()
	)
	report_button = action(column, "ui.report", func(): CampaignSystem.talk(town_id); refresh())
	var row := HBoxContainer.new()
	column.add_child(row)
	for resource in ["food", "wood", "ore", "stone"]:
		var trade_column := VBoxContainer.new()
		row.add_child(trade_column)
		for buying in [true, false]:
			var control := Button.new()
			control.text = LocalizationManager.get_string("ui.buy" if buying else "ui.sell") + " 10 " + LocalizationManager.get_string("ui." + resource)
			control.set_meta("trade_resource", resource)
			control.set_meta("text_key", "ui.buy" if buying else "ui.sell")
			trade_column.add_child(control)
			control.pressed.connect(func():
				var ok := WorkshopSystem.trade(resource, 10, buying)
				message.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
				refresh()
			)
	siege_status = Label.new()
	siege_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(siege_status)
	blockade_button = action(column, "siege.begin", func():
		SiegeSystem.begin(CampaignSystem.town(town_id).faction)
		refresh()
	)
	wait_button = action(column, "siege.wait", func():
		if not get_tree().current_scene.in_combat(): TimeSystem.advance_day()
		refresh()
	)
	surrender_button = action(column, "siege.surrender", func():
		SiegeSystem.offer_surrender(CampaignSystem.town(town_id).faction)
		refresh()
	)
	retreat_button = action(column, "siege.lift", func():
		SiegeSystem.lift(CampaignSystem.town(town_id).faction)
		refresh()
	)
	assault_button = action(column, "siege.assault", func():
		var ok := CampaignSystem.start_assault(CampaignSystem.town(town_id).faction)
		if ok: get_tree().current_scene.toggle_pause()
	)
	message = Label.new()
	column.add_child(message)
	CampaignSystem.changed.connect(refresh)
	EventBus.language_changed.connect(func(_lang): localize())

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	parent.add_child(control)
	control.pressed.connect(func(): AudioManager.play_sound("ui_click"); callback.call())
	return control

func localize() -> void:
	for control in find_children("*", "Button", true, false):
		if control.has_meta("text_key"):
			control.text = LocalizationManager.get_string(control.get_meta("text_key"))
			if control.has_meta("trade_resource"):
				control.text += " 10 " + LocalizationManager.get_string("ui." + control.get_meta("trade_resource"))
	refresh()

func open(id: String) -> void:
	town_id = id
	CampaignSystem.talk(id)
	refresh()
	show()

func refresh() -> void:
	if town_id.is_empty() or not is_instance_valid(description): return
	var town := CampaignSystem.town(town_id)
	var faction: Dictionary = CampaignSystem.definition.factions.filter(func(f): return f.id == town.faction)[0]
	title_label.text = LocalizationManager.get_string(town.name)
	description.text = "[b]" + LocalizationManager.get_string(faction.name) + "[/b]\n" + LocalizationManager.get_string(faction.story) + "\n\n" + LocalizationManager.get_string("ui.town_help")
	resources_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(EconomySystem.stockpiles.food), "wood": int(EconomySystem.stockpiles.wood), "ore": int(EconomySystem.stockpiles.ore), "gold": int(EconomySystem.stockpiles.gold)})
	delivery_button.disabled = town.faction in CampaignSystem.deliveries or not CampaignSystem.can_pay(CampaignSystem.definition.delivery_cost)
	var siege: Dictionary = SiegeSystem.states.get(town.faction, {})
	var blockading: bool = siege.get("phase", "") == "blockade"
	blockade_button.disabled = CampaignSystem.bound(town.faction) or not siege.is_empty() or ArmySystem.get_total_soldiers() < 3 or not CampaignSystem.can_pay(SiegeSystem.SETUP)
	wait_button.disabled = not blockading or get_tree().current_scene.in_combat()
	surrender_button.disabled = not blockading or siege.get("supplies", 100) > 0 or siege.get("morale", 100) > 30
	retreat_button.disabled = not blockading
	assault_button.disabled = not blockading or siege.get("days", 0) < 1 or ArmySystem.get_total_soldiers() < 3 or not CampaignSystem.can_pay(SiegeSystem.ASSAULT)
	siege_status.text = LocalizationManager.get_string("siege.help") if siege.is_empty() else LocalizationManager.get_string("siege.status", {"days": siege.days, "supplies": int(siege.supplies), "morale": int(siege.morale), "wall": int(siege.wall_hp)})
	report_button.disabled = not CampaignSystem.bound(town.faction)
	if siege.get("phase", "") == "assault": siege_status.text += "\n" + LocalizationManager.get_string("siege.breach_help")
	if CampaignSystem.bound(town.faction): siege_status.text = LocalizationManager.get_string("siege.secured")
