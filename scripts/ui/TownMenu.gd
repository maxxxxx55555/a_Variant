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
var tabs:TabContainer
var details:Button
var summary:Label

func page() -> VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box:=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",22)
	scroll.add_child(box)
	return box

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17232b")
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
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 34)
	header.add_child(title_label)
	details=Button.new()
	details.name="TownDetails"
	details.custom_minimum_size=Vector2(190,64)
	header.add_child(details)
	action(header, "ui.close", func(): get_tree().current_scene.toggle_pause())
	description = RichTextLabel.new()
	description.fit_content=true
	description.custom_minimum_size.y = 150
	description.bbcode_enabled = true
	description.hide()
	layout.add_child(description)
	details.pressed.connect(func(): description.visible=not description.visible)
	resources_label = Label.new()
	layout.add_child(resources_label)
	tabs=TabContainer.new()
	tabs.name="TownTabs"
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(tabs)
	var journey:=page()
	var trade:=page()
	var siege_page:=page()
	summary=Label.new()
	summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_color_override("font_color",Color("b6c2c5"))
	journey.add_child(summary)
	delivery_button = action(journey, "town.deliver", func():
		var ok := CampaignSystem.deliver_supplies(CampaignSystem.town(town_id).faction)
		message.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.treaty_failed")
		refresh()
	)
	report_button = action(journey, "town.report", func(): CampaignSystem.talk(town_id); refresh())
	var row := GridContainer.new()
	row.columns=2
	row.add_theme_constant_override("h_separation",22)
	row.add_theme_constant_override("v_separation",22)
	trade.add_child(row)
	for resource in ["food", "wood", "ore", "stone"]:
		var panel:=PanelContainer.new()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",preload("res://scripts/ui/MarchTheme.gd").panel(Color("24343e")))
		row.add_child(panel)
		var trade_column := VBoxContainer.new()
		trade_column.add_theme_constant_override("separation",15)
		panel.add_child(trade_column)
		var heading:=Label.new()
		heading.set_meta("resource_heading",resource)
		heading.add_theme_font_size_override("font_size",29)
		trade_column.add_child(heading)
		for buying in [true, false]:
			var control := Button.new()
			control.custom_minimum_size.y=68
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
	siege_page.add_child(siege_status)
	var siege_grid:=GridContainer.new()
	siege_grid.columns=2
	siege_grid.add_theme_constant_override("h_separation",20)
	siege_grid.add_theme_constant_override("v_separation",20)
	siege_page.add_child(siege_grid)
	blockade_button = action(siege_grid, "siege.begin", func():
		SiegeSystem.begin(CampaignSystem.town(town_id).faction)
		refresh()
	)
	wait_button = action(siege_grid, "siege.wait", func():
		if not get_tree().current_scene.in_combat(): TimeSystem.advance_day()
		refresh()
	)
	surrender_button = action(siege_grid, "siege.surrender", func():
		SiegeSystem.offer_surrender(CampaignSystem.town(town_id).faction)
		refresh()
	)
	retreat_button = action(siege_grid, "siege.lift", func():
		SiegeSystem.lift(CampaignSystem.town(town_id).faction)
		refresh()
	)
	assault_button = action(siege_grid, "siege.assault", func():
		var ok := CampaignSystem.start_assault(CampaignSystem.town(town_id).faction)
		if ok: get_tree().current_scene.toggle_pause()
	)
	message = Label.new()
	layout.add_child(message)
	CampaignSystem.changed.connect(refresh)
	EventBus.language_changed.connect(func(_lang): localize())
	localize()

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	control.size_flags_horizontal=Control.SIZE_SHRINK_END if key=="ui.close" else Control.SIZE_EXPAND_FILL
	control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	control.custom_minimum_size.y=64 if key=="ui.close" else 78
	if key=="ui.close":
		control.autowrap_mode=TextServer.AUTOWRAP_OFF
		control.custom_minimum_size.x=140
	parent.add_child(control)
	control.pressed.connect(func(): AudioManager.play_sound("ui_click"); callback.call())
	return control

func localize() -> void:
	for index in 3: tabs.set_tab_title(index,LocalizationManager.get_string(["town.journey","town.trade","town.siege"][index]))
	details.text=LocalizationManager.get_string("town.details")
	for control in find_children("*", "Button", true, false):
		if control.has_meta("text_key"):
			control.text = LocalizationManager.get_string(control.get_meta("text_key"))
			if control.has_meta("trade_resource"):
				trade_caption(control)
	refresh()

func trade_caption(control:Button) -> void:
	var buying:bool=control.get_meta("text_key")=="ui.buy"
	var price:float=WorkshopSystem.price_for(control.get_meta("trade_resource"),10,buying)
	control.disabled=not CampaignSystem.can_pay({"gold":price} if buying else {control.get_meta("trade_resource"):10})
	control.text=LocalizationManager.get_string(control.get_meta("text_key"))+" 10 · "+str(snappedf(price,0.1))+" "+LocalizationManager.get_string("town.coin")
	control.tooltip_text=control.text+" · "+LocalizationManager.get_string("ui."+control.get_meta("trade_resource"))

func open(id: String) -> void:
	town_id = id
	tabs.current_tab=0
	description.hide()
	CampaignSystem.talk(id)
	refresh()
	show()

func refresh() -> void:
	if town_id.is_empty() or not is_instance_valid(description): return
	var town := CampaignSystem.town(town_id)
	var faction: Dictionary = CampaignSystem.definition.factions.filter(func(f): return f.id == town.faction)[0]
	title_label.text = LocalizationManager.get_string(town.name)
	summary.text=LocalizationManager.get_string("town.next")
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
	for label in find_children("*","Label",true,false):
		if label.has_meta("resource_heading"):
			var resource:String=label.get_meta("resource_heading")
			label.text=LocalizationManager.get_string("ui."+resource)+" · "+str(int(EconomySystem.stockpiles[resource]))
	for control in find_children("*","Button",true,false):
		if control.has_meta("trade_resource"): trade_caption(control)
