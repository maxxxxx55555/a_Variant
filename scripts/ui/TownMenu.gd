extends PanelContainer
const IconView=preload("res://scripts/ui/IconSet.gd")
const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const FactionView=preload("res://scripts/ui/FactionStyle.gd")
const MotionView=preload("res://scripts/ui/UIMotion.gd")

var town_id: String = ""
var faction_band: ColorRect
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
	var scroll:ScrollContainer=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box:VBoxContainer=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",22)
	scroll.add_child(box)
	return box

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style:StyleBoxFlat= ThemeRef.panel(Color("171c21"),Color("c9a227"))
	style.content_margin_left = 70
	style.content_margin_right = 70
	style.content_margin_top = 45
	style.content_margin_bottom = 45
	add_theme_stylebox_override("panel", style)
	var layout:VBoxContainer= VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	add_child(layout)
	var header:HBoxContainer= HBoxContainer.new()
	layout.add_child(header)
	header.add_child(IconView.rect("town",Color("c9a227"),Vector2(28,28),"TownIcon"))
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_font_override("font",ThemeRef.heading_font(700))
	title_label.add_theme_color_override("font_color",Color("e8dcc3"))
	header.add_child(title_label)
	details=Button.new()
	details.name="TownDetails"
	details.custom_minimum_size=Vector2(190,64)
	header.add_child(details)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	action(header, "ui.close", func()->void: get_tree().current_scene.call("toggle_pause"))
	faction_band=ColorRect.new()
	faction_band.name="FactionBand"
	faction_band.custom_minimum_size=Vector2(0,4)
	faction_band.color=Color("c9a227")
	layout.add_child(faction_band)
	description = RichTextLabel.new()
	description.fit_content=true
	description.custom_minimum_size.y = 150
	description.bbcode_enabled = true
	description.hide()
	layout.add_child(description)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	details.pressed.connect(func()->void: description.visible=not description.visible)
	resources_label = Label.new()
	layout.add_child(resources_label)
	tabs=TabContainer.new()
	tabs.name="TownTabs"
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	layout.add_child(tabs)
	var journey:VBoxContainer=page()
	var trade:VBoxContainer=page()
	var siege_page:VBoxContainer=page()
	summary=Label.new()
	summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_color_override("font_color",Color("91a0a7"))
	journey.add_child(summary)
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
	row.add_theme_constant_override("h_separation",22)
	row.add_theme_constant_override("v_separation",22)
	trade.add_child(row)
	for resource:String in ["food", "wood", "ore", "stone"]:
		var panel:PanelContainer=PanelContainer.new()
		panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override("panel",ThemeRef.panel(Color(0.10,0.12,0.14,0.9),Color("46545d")))
		row.add_child(panel)
		var trade_column:VBoxContainer= VBoxContainer.new()
		trade_column.add_theme_constant_override("separation",15)
		panel.add_child(trade_column)
		var heading:Label=Label.new()
		heading.set_meta("resource_heading",resource)
		heading.add_theme_font_size_override("font_size",29)
		trade_column.add_child(heading)
		for buying:bool in [true, false]:
			var control:Button= Button.new()
			control.custom_minimum_size.y=68
			control.set_meta("trade_resource", resource)
			control.set_meta("text_key", "ui.buy" if buying else "ui.sell")
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
	siege_page.add_child(siege_status)
	var siege_grid:GridContainer=GridContainer.new()
	siege_grid.columns=2
	siege_grid.add_theme_constant_override("h_separation",20)
	siege_grid.add_theme_constant_override("v_separation",20)
	siege_page.add_child(siege_grid)
	blockade_button = action(siege_grid, "siege.begin", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.begin(current_faction())
		refresh()
	)
	wait_button = action(siege_grid, "siege.wait", func()->void:
		if not get_tree().current_scene.call("in_combat"): TimeSystem.advance_day()
		refresh()
	)
	surrender_button = action(siege_grid, "siege.surrender", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.offer_surrender(current_faction())
		refresh()
	)
	retreat_button = action(siege_grid, "siege.lift", func()->void:
		# The refreshed panel derives the authoritative result and disabled reasons.
		@warning_ignore("return_value_discarded")
		SiegeSystem.lift(current_faction())
		refresh()
	)
	assault_button = action(siege_grid, "siege.assault", func()->void:
		var ok:bool= CampaignSystem.start_assault(current_faction())
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		if not ok:AudioManager.play_sfx("ui_error")
		if ok: get_tree().current_scene.call("toggle_pause")
	)
	message = Label.new()
	layout.add_child(message)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: localize())
	localize()

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	control.size_flags_horizontal=Control.SIZE_SHRINK_END if key=="ui.close" else Control.SIZE_EXPAND_FILL
	control.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	control.custom_minimum_size.y=64 if key=="ui.close" else 78
	if key=="ui.close":
		control.autowrap_mode=TextServer.AUTOWRAP_OFF
		control.custom_minimum_size.x=140
	parent.add_child(control)
	var icons:Dictionary={"ui.close":"close","town.deliver":"food","town.report":"journal","siege.begin":"siege","siege.wait":"pause","siege.surrender":"oath","siege.lift":"exit","siege.assault":"army"}
	if icons.has(key):IconView.apply(control,str(icons[key]),20)
	MotionView.attach(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

func localize() -> void:
	for index:int in 3: tabs.set_tab_title(index,LocalizationManager.get_string(str(["town.journey","town.trade","town.siege"][index])))
	tabs.set_tab_icon(0,IconView.texture("town"))
	tabs.set_tab_icon(1,IconView.texture("diplomacy"))
	tabs.set_tab_icon(2,IconView.texture("siege"))
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
	var accent:Color=FactionView.color(faction_id)
	title_label.text = LocalizationManager.get_string(str(town.name))
	title_label.add_theme_color_override("font_color",FactionView.text_color(faction_id))
	if is_instance_valid(faction_band):faction_band.color=accent
	summary.text=LocalizationManager.get_string("town.next")
	description.text = "[b]" + LocalizationManager.get_string(str(faction.name)) + "[/b]\n" + LocalizationManager.get_string(str(faction.story)) + "\n\n" + LocalizationManager.get_string("ui.town_help")
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
