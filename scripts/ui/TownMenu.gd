extends PanelContainer
const UITheme=preload("res://scripts/ui/MarchTheme.gd")

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
var faction_label:RichTextLabel

func page() -> VBoxContainer:
	var scroll:ScrollContainer=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box:VBoxContainer=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",14)
	scroll.add_child(box)
	return box

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The screen itself is a scrim; the readable surface is the centred card below.
	var scrim:StyleBoxFlat= StyleBoxFlat.new()
	scrim.bg_color = Color(UITheme.INK, 0.78)
	scrim.set_corner_radius_all(0)
	scrim.set_content_margin_all(0)
	add_theme_stylebox_override("panel", scrim)
	var frame:MarginContainer= MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 330)
	frame.add_theme_constant_override("margin_right", 330)
	frame.add_theme_constant_override("margin_top", 96)
	frame.add_theme_constant_override("margin_bottom", 120)
	add_child(frame)
	var card:PanelContainer= PanelContainer.new()
	card.name = "TownCard"
	var surface:StyleBoxFlat= UITheme.panel(UITheme.SLATE)
	surface.content_margin_left = 64
	surface.content_margin_right = 64
	surface.content_margin_top = 52
	surface.content_margin_bottom = 44
	card.add_theme_stylebox_override("panel", surface)
	var stack:VBoxContainer= VBoxContainer.new()
	frame.add_child(stack)
	stack.add_child(card)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size.y = 0
	var layout:VBoxContainer= VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	card.add_child(layout)
	var header:HBoxContainer= HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	layout.add_child(header)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_override("font", UITheme.display_font())
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", UITheme.BRASS)
	header.add_child(title_label)
	details=Button.new()
	details.name="TownDetails"
	details.custom_minimum_size=Vector2(190,60)
	details.add_theme_font_size_override("font_size", 20)
	header.add_child(details)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	action(header, "ui.close", func()->void: get_tree().current_scene.call("toggle_pause"))
	layout.add_child(_hairline(UITheme.LINE_SOFT))
	# The community's own account is always on the page; the manual stays behind a toggle.
	faction_label = RichTextLabel.new()
	faction_label.fit_content = true
	faction_label.bbcode_enabled = true
	faction_label.custom_minimum_size.y = 78
	faction_label.add_theme_font_size_override("normal_font_size", 21)
	faction_label.add_theme_font_size_override("bold_font_size", 21)
	faction_label.add_theme_color_override("default_color", UITheme.MIST)
	layout.add_child(faction_label)
	description = RichTextLabel.new()
	description.fit_content=true
	description.custom_minimum_size.y = 120
	description.bbcode_enabled = true
	description.add_theme_font_size_override("normal_font_size", 20)
	description.add_theme_color_override("default_color", UITheme.MIST_DIM)
	description.hide()
	layout.add_child(description)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	details.pressed.connect(func()->void: description.visible=not description.visible)
	resources_label = Label.new()
	resources_label.add_theme_font_override("font", UITheme.body_font(500, 1))
	resources_label.add_theme_font_size_override("font_size", 20)
	resources_label.add_theme_color_override("font_color", UITheme.MIST)
	layout.add_child(resources_label)
	layout.add_child(_hairline(UITheme.LINE_SOFT))
	tabs=TabContainer.new()
	tabs.name="TownTabs"
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	tabs.custom_minimum_size.y = 300
	layout.add_child(tabs)
	var journey:VBoxContainer=page()
	var trade:VBoxContainer=page()
	var siege_page:VBoxContainer=page()
	summary=Label.new()
	summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 22)
	summary.add_theme_color_override("font_color",UITheme.CHALK)
	journey.add_child(summary)
	journey.add_child(_spacer(4))
	journey.add_child(_hairline(UITheme.LINE_SOFT))
	journey.add_child(_spacer(4))
	delivery_button = action(journey, "town.deliver", func()->void:
		var ok:bool= CampaignSystem.deliver_supplies(current_faction())
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		if not ok:AudioManager.play_sfx("ui_error")
		message.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.treaty_failed")
		refresh()
	)
	report_button = action(journey, "town.report", func()->void: CampaignSystem.talk(town_id); refresh())
	var row:GridContainer= GridContainer.new()
	row.columns=2
	row.add_theme_constant_override("h_separation",18)
	row.add_theme_constant_override("v_separation",18)
	trade.add_child(row)
	for resource:String in ["food", "wood", "ore", "stone"]:
		var panel:PanelContainer=PanelContainer.new()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var field:StyleBoxFlat=UITheme.panel(UITheme.SLATE_RAISED, UITheme.LINE_SOFT)
		field.content_margin_left=26
		field.content_margin_right=26
		field.content_margin_top=22
		field.content_margin_bottom=22
		panel.add_theme_stylebox_override("panel",field)
		row.add_child(panel)
		var trade_column:VBoxContainer= VBoxContainer.new()
		trade_column.add_theme_constant_override("separation",12)
		panel.add_child(trade_column)
		var heading:Label=Label.new()
		heading.set_meta("resource_heading",resource)
		heading.add_theme_font_override("font", UITheme.body_font(500, 1))
		heading.add_theme_font_size_override("font_size", 22)
		heading.add_theme_color_override("font_color", UITheme.CHALK)
		trade_column.add_child(heading)
		for buying:bool in [true, false]:
			var control:Button= Button.new()
			control.custom_minimum_size.y=64
			control.set_meta("trade_resource", resource)
			control.set_meta("text_key", "ui.buy" if buying else "ui.sell")
			control.add_theme_font_size_override("font_size", 20)
			trade_column.add_child(control)
			# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
			@warning_ignore("return_value_discarded")
			control.pressed.connect(func()->void:
				var ok:bool= WorkshopSystem.trade(resource, 10, buying)
				# AudioManager owns the voice and records the feedback acknowledgment.
				@warning_ignore("return_value_discarded")
				if not ok:AudioManager.play_sfx("ui_error")
				message.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
				refresh()
			)
	siege_status = Label.new()
	siege_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	siege_status.add_theme_font_size_override("font_size", 21)
	siege_status.add_theme_color_override("font_color", UITheme.MIST)
	siege_page.add_child(siege_status)
	siege_page.add_child(_hairline(UITheme.LINE_SOFT))
	var siege_grid:GridContainer=GridContainer.new()
	siege_grid.columns=2
	siege_grid.add_theme_constant_override("h_separation",16)
	siege_grid.add_theme_constant_override("v_separation",16)
	siege_page.add_child(siege_grid)
	blockade_button = action(siege_grid, "siege.begin", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.begin(current_faction())
		refresh()
	, true)
	wait_button = action(siege_grid, "siege.wait", func()->void:
		if not get_tree().current_scene.call("in_combat"): TimeSystem.advance_day()
		refresh()
	, true)
	surrender_button = action(siege_grid, "siege.surrender", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.offer_surrender(current_faction())
		refresh()
	, true)
	retreat_button = action(siege_grid, "siege.lift", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.lift(current_faction())
		refresh()
	, true)
	assault_button = action(siege_grid, "siege.assault", func()->void:
		var ok:bool= CampaignSystem.start_assault(current_faction())
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		if not ok:AudioManager.play_sfx("ui_error")
		if ok: get_tree().current_scene.call("toggle_pause")
	, true)
	message = Label.new()
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 19)
	message.add_theme_color_override("font_color", UITheme.BRASS)
	layout.add_child(message)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: localize())
	localize()

func _spacer(height: int) -> Control:
	var gap:Control = Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

func _hairline(color: Color) -> ColorRect:
	var bar:ColorRect = ColorRect.new()
	bar.color = color
	bar.custom_minimum_size.y = 1
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar

func action(parent: Node, key: String, callback: Callable, full_width: bool = false) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	if key=="ui.close":
		control.size_flags_horizontal=Control.SIZE_SHRINK_END
		control.custom_minimum_size=Vector2(140,60)
		control.autowrap_mode=TextServer.AUTOWRAP_OFF
		control.add_theme_font_size_override("font_size", 20)
	elif full_width:
		control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		control.custom_minimum_size.y=66
		control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		control.add_theme_font_size_override("font_size", 20)
	else:
		# Journey actions read as ledger entries rather than full-bleed slabs.
		control.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
		control.custom_minimum_size=Vector2(560,62)
		control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		control.alignment=HORIZONTAL_ALIGNMENT_LEFT
		control.add_theme_font_size_override("font_size", 21)
	parent.add_child(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

func localize() -> void:
	for index:int in 3: tabs.set_tab_title(index,LocalizationManager.get_string(str(["town.journey","town.trade","town.siege"][index])))
	details.text=LocalizationManager.get_string("town.details")
	for control:Button in find_children("*", "Button", true, false):
		if control.has_meta("text_key"):
			control.text = LocalizationManager.get_string(str(control.get_meta("text_key")))
			if control.has_meta("trade_resource"):
				trade_caption(control)
	refresh()

func trade_caption(control:Button) -> void:
	var buying:bool=control.get_meta("text_key")=="ui.buy"
	var price:float=WorkshopSystem.price_for(str(control.get_meta("trade_resource")),10,buying)
	control.disabled=not CampaignSystem.can_pay({"gold":price} if buying else {control.get_meta("trade_resource"):10})
	control.text=LocalizationManager.get_string(str(control.get_meta("text_key")))+" 10 · "+str(snappedf(price,0.1))+" "+LocalizationManager.get_string("town.coin")
	control.tooltip_text=(LocalizationManager.get_string("ui.resources_required")+" · " if control.disabled else "")+control.text+" · "+LocalizationManager.get_string("ui."+str(control.get_meta("trade_resource")))

func open(id: String) -> void:
	town_id = id
	tabs.current_tab=0
	description.hide()
	CampaignSystem.talk(id)
	refresh()
	show()

func refresh() -> void:
	if town_id.is_empty() or not is_instance_valid(description): return
	var town:Dictionary= CampaignSystem.town(town_id)
	var factions:Array=CampaignSystem.definition.factions
	var faction:Dictionary=factions.filter(func(f:Dictionary)->bool:return f.id==town.faction)[0]
	var faction_id:String=town.faction
	var delivery_cost:Dictionary=CampaignSystem.definition.delivery_cost
	title_label.text = LocalizationManager.get_string(str(town.name))
	summary.text=LocalizationManager.get_string("town.next")
	faction_label.text = "[color=#d9bf8b][b]" + LocalizationManager.get_string(str(faction.name)) + "[/b][/color]\n" + LocalizationManager.get_string(str(faction.story))
	description.text = LocalizationManager.get_string("ui.town_help")
	var food:float=EconomySystem.stockpiles.food
	var wood:float=EconomySystem.stockpiles.wood
	var ore:float=EconomySystem.stockpiles.ore
	var gold:float=EconomySystem.stockpiles.gold
	resources_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(food), "wood": int(wood), "ore": int(ore), "gold": int(gold)})
	delivery_button.disabled = town.faction in CampaignSystem.deliveries or not CampaignSystem.can_pay(delivery_cost)
	var siege: Dictionary = SiegeSystem.states.get(town.faction, {})
	var blockading: bool = siege.get("phase", "") == "blockade"
	blockade_button.disabled = CampaignSystem.bound(faction_id) or not siege.is_empty() or ArmySystem.get_total_soldiers() < 3 or not CampaignSystem.can_pay(SiegeSystem.SETUP)
	wait_button.disabled = not blockading or get_tree().current_scene.call("in_combat")
	surrender_button.disabled = not blockading or siege.get("supplies", 100) > 0 or siege.get("morale", 100) > 30
	retreat_button.disabled = not blockading
	assault_button.disabled = not blockading or siege.get("days", 0) < 1 or ArmySystem.get_total_soldiers() < 3 or not CampaignSystem.can_pay(SiegeSystem.ASSAULT)
	var supplies:float=siege.get("supplies",0)
	var morale:float=siege.get("morale",0)
	var wall:float=siege.get("wall_hp",0)
	siege_status.text = LocalizationManager.get_string("siege.help") if siege.is_empty() else LocalizationManager.get_string("siege.status", {"days": siege.days, "supplies": int(supplies), "morale": int(morale), "wall": int(wall)})
	report_button.disabled = not CampaignSystem.bound(faction_id)
	delivery_button.tooltip_text=LocalizationManager.get_string("ui.delivery_requirements") if delivery_button.disabled else ""
	report_button.tooltip_text=LocalizationManager.get_string("ui.report_requirements") if report_button.disabled else ""
	for pair:Array in [[blockade_button,"siege.begin_requirements"],[wait_button,"siege.wait_requirements"],[surrender_button,"siege.surrender_requirements"],[retreat_button,"siege.lift_requirements"],[assault_button,"siege.assault_requirements"]]:
		var button:Button=pair[0]
		button.tooltip_text=LocalizationManager.get_string(str(pair[1])) if button.disabled else ""
	if siege.get("phase", "") == "assault": siege_status.text += "\n" + LocalizationManager.get_string("siege.breach_help")
	if CampaignSystem.bound(faction_id): siege_status.text = LocalizationManager.get_string("siege.secured")
	for label:Label in find_children("*","Label",true,false):
		if label.has_meta("resource_heading"):
			var resource:String=label.get_meta("resource_heading")
			var amount:float=EconomySystem.stockpiles[resource]
			label.text=LocalizationManager.get_string("ui."+resource)+" · "+str(int(amount))
	for control:Button in find_children("*","Button",true,false):
		if control.has_meta("trade_resource"): trade_caption(control)

func current_faction()->String:
	return CampaignSystem.town(town_id).faction
