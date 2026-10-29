extends Node
const FrameView=preload("res://scripts/ui/CouncilFrame.gd")
const MapView=preload("res://scripts/ui/MarchMap.gd")
const UITheme=preload("res://scripts/ui/MarchTheme.gd")

var council:FrameView
var map_view:MapView
var home_button:Button
var travel_button: Button
var map_details: Label
var building_buttons:Dictionary[String,Button] = {}
var craft_list: ItemList
var craft_button: Button
var resource_label: Label

func attach(parent:FrameView) -> void:
	council = parent
	var map_column:VBoxContainer= VBoxContainer.new()
	map_column.name = "Map"
	council.tabs.add_child(map_column)
	map_view = preload("res://scripts/ui/MarchMap.gd").new()
	map_column.add_child(map_view)
	# One connection is owned by this map panel.
	@warning_ignore("return_value_discarded")
	map_view.town_selected.connect(func(_id:Variant)->void: refresh())
	map_details = Label.new()
	map_details.add_theme_font_size_override("font_size", 20)
	map_details.add_theme_color_override("font_color", UITheme.MIST)
	map_column.add_child(map_details)
	var travel_row:HBoxContainer= HBoxContainer.new()
	travel_row.add_theme_constant_override("separation", 14)
	map_column.add_child(travel_row)
	travel_button = council.button(travel_row, "ui.travel", func()->void:
		# Disabled travel controls explain failure; the world owns successful transitions.
		@warning_ignore("return_value_discarded")
		CampaignSystem.travel(map_view.selected)
	)
	home_button = council.button(travel_row, "ui.travel_home", func()->void:
		# Disabled travel controls explain failure; the world owns successful transitions.
		@warning_ignore("return_value_discarded")
		CampaignSystem.travel("home")
	)
	home_button.tooltip_text = LocalizationManager.get_string("ui.travel_cost")
	var workshop:VBoxContainer= VBoxContainer.new()
	workshop.name = "Workshop"
	council.tabs.add_child(workshop)
	resource_label = Label.new()
	resource_label.add_theme_font_override("font", UITheme.body_font(500, 1))
	resource_label.add_theme_font_size_override("font_size", 20)
	resource_label.add_theme_color_override("font_color", UITheme.MIST)
	workshop.add_child(resource_label)
	var resource_rule:ColorRect= ColorRect.new()
	resource_rule.color = UITheme.LINE_SOFT
	resource_rule.custom_minimum_size.y = 1
	resource_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	workshop.add_child(resource_rule)
	var split:HBoxContainer= HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation", 26)
	workshop.add_child(split)
	# Ten buildings read as a two-column ledger; nothing needs scrolling to be seen.
	var buildings:GridContainer= GridContainer.new()
	buildings.columns = 1
	# The ledger keeps a fixed measure; the recipe list takes the remaining width.
	buildings.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	buildings.custom_minimum_size.x = 620
	buildings.add_theme_constant_override("h_separation", 12)
	buildings.add_theme_constant_override("v_separation", 8)
	split.add_child(buildings)
	for data:Dictionary in WorkshopSystem.definitions:
		var control:Button= Button.new()
		control.custom_minimum_size = Vector2(0, 46)
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control.alignment = HORIZONTAL_ALIGNMENT_LEFT
		control.add_theme_font_size_override("font_size", 17)
		buildings.add_child(control)
		building_buttons[data.id] = control
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		control.pressed.connect(func()->void:
			# AudioManager owns the voice and records the feedback acknowledgment.
			@warning_ignore("return_value_discarded")
			if not WorkshopSystem.build(str(data.id)):AudioManager.play_sfx("ui_error")
			refresh()
		)
	var crafting:VBoxContainer= VBoxContainer.new()
	crafting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crafting.add_theme_constant_override("separation", 12)
	split.add_child(crafting)
	craft_list = ItemList.new()
	craft_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	craft_list.add_theme_font_size_override("font_size", 16)
	craft_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crafting.add_child(craft_list)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	craft_list.item_selected.connect(func(_index:Variant)->void: refresh())
	craft_button = council.button(crafting, "ui.craft", func()->void:
		var selection:PackedInt32Array= craft_list.get_selected_items()
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		if selection.is_empty() or not WorkshopSystem.craft(str(WorkshopSystem.crafting[selection[0]].id)):AudioManager.play_sfx("ui_error")
		refresh()
	)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	WorkshopSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void: refresh())
	refresh()

func costs(cost: Dictionary) -> String:
	var parts:PackedStringArray= PackedStringArray()
	for resource:String in cost:
		var amount:float=cost[resource]
		if parts.append(str(int(amount))+" "+LocalizationManager.get_string("ui."+resource)):return ""
	return ", ".join(parts)

func refresh() -> void:
	if not is_instance_valid(map_view): return
	council.tabs.set_tab_title(3, LocalizationManager.get_string("ui.map"))
	council.tabs.set_tab_title(4, LocalizationManager.get_string("ui.workshop"))
	map_view.queue_redraw()
	var world:Node=get_tree().current_scene
	var fighting:bool=world!=null and world.has_method("in_combat") and world.call("in_combat")
	var town:Dictionary=CampaignSystem.town(map_view.selected)
	var danger:int=town.danger
	var travel_cost:Dictionary=CampaignSystem.definition.travel_cost
	map_details.text = LocalizationManager.get_string(str(town.name)) + " · " + LocalizationManager.get_string("ui.danger") + " " + str(danger) + "/5 · " + LocalizationManager.get_string("ui.travel_cost")
	travel_button.disabled = town.id not in CampaignSystem.roads or not CampaignSystem.can_pay(travel_cost) or fighting
	travel_button.tooltip_text=LocalizationManager.get_string("ui.travel_requirements") if travel_button.disabled else LocalizationManager.get_string("ui.travel_cost")
	home_button.disabled=not CampaignSystem.can_pay(travel_cost) or fighting
	home_button.tooltip_text=travel_button.tooltip_text if home_button.disabled else LocalizationManager.get_string("ui.travel_cost")
	for data:Dictionary in WorkshopSystem.definitions:
		var level: int = WorkshopSystem.levels.get(data.id, 0)
		var base_cost:Dictionary=data.cost
		var cost:Dictionary=base_cost.duplicate()
		for resource:String in cost: cost[resource] *= level + 1
		building_buttons[data.id].text = LocalizationManager.get_string(str(data.name)) + "  " + str(level) + "/3 · " + costs(cost)
		building_buttons[data.id].disabled = level >= 3 or not CampaignSystem.can_pay(cost)
		building_buttons[data.id].tooltip_text=LocalizationManager.get_string("ui.max_level" if level>=3 else "ui.resources_required") if building_buttons[data.id].disabled else ""
	var selected:PackedInt32Array= craft_list.get_selected_items()
	craft_list.clear()
	for blueprint:Dictionary in WorkshopSystem.crafting:
		var result_path:String=blueprint.result
		var item:ItemData=load(result_path) as ItemData
		var recipe_cost:Dictionary=blueprint.cost
		# This list owns the row; selection is managed separately.
		@warning_ignore("return_value_discarded")
		craft_list.add_item(LocalizationManager.get_string(str(item.name_key)) + " · " + costs(recipe_cost))
	if not selected.is_empty(): craft_list.select(selected[0])
	craft_button.disabled = selected.is_empty() or WorkshopSystem.levels.get("forge", 0) < 1
	if not selected.is_empty():
		var blueprint:Dictionary=WorkshopSystem.crafting[selected[0]]
		var recipe_cost:Dictionary=blueprint.cost
		var result_path:String=blueprint.result
		craft_button.disabled=craft_button.disabled or not CampaignSystem.can_pay(recipe_cost) or not GameState.can_add_item(load(result_path))
	craft_button.tooltip_text=LocalizationManager.get_string("ui.craft_requirements") if craft_button.disabled else ""
	var food:float=EconomySystem.stockpiles.food
	var wood:float=EconomySystem.stockpiles.wood
	var ore:float=EconomySystem.stockpiles.ore
	var gold:float=EconomySystem.stockpiles.gold
	resource_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(food), "wood": int(wood), "ore": int(ore), "gold": int(gold)})
