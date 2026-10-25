extends Node

var council: Control
var map_view: Control
var home_button:Button
var travel_button: Button
var map_details: Label
var building_buttons: Dictionary = {}
var craft_list: ItemList
var craft_button: Button
var resource_label: Label

func attach(parent: Control) -> void:
	council = parent
	var map_column := VBoxContainer.new()
	map_column.name = "Map"
	council.tabs.add_child(map_column)
	map_view = preload("res://scripts/ui/MarchMap.gd").new()
	map_column.add_child(map_view)
	map_view.town_selected.connect(func(_id): refresh())
	map_details = Label.new()
	map_column.add_child(map_details)
	travel_button = council.button(map_column, "ui.travel", func(): CampaignSystem.travel(map_view.selected))
	home_button = council.button(map_column, "ui.travel_home", func(): CampaignSystem.travel("home"))
	home_button.tooltip_text = LocalizationManager.get_string("ui.travel_cost")
	var workshop := VBoxContainer.new()
	workshop.name = "Workshop"
	council.tabs.add_child(workshop)
	resource_label = Label.new()
	workshop.add_child(resource_label)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workshop.add_child(split)
	var scrolling := ScrollContainer.new()
	scrolling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scrolling.custom_minimum_size.x = 700
	split.add_child(scrolling)
	var buildings := VBoxContainer.new()
	buildings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buildings.add_theme_constant_override("separation", 14)
	scrolling.add_child(buildings)
	for data in WorkshopSystem.definitions:
		var control := Button.new()
		buildings.add_child(control)
		building_buttons[data.id] = control
		control.pressed.connect(func(): WorkshopSystem.build(data.id); refresh())
	var crafting := VBoxContainer.new()
	crafting.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(crafting)
	craft_list = ItemList.new()
	craft_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	crafting.add_child(craft_list)
	craft_list.item_selected.connect(func(_index): refresh())
	craft_button = council.button(crafting, "ui.craft", func():
		var selection := craft_list.get_selected_items()
		if not selection.is_empty(): WorkshopSystem.craft(WorkshopSystem.crafting[selection[0]].id)
		refresh()
	)
	CampaignSystem.changed.connect(refresh)
	WorkshopSystem.changed.connect(refresh)
	EventBus.language_changed.connect(func(_language): refresh())
	refresh()

func costs(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for resource in cost:
		parts.append(str(int(cost[resource])) + " " + LocalizationManager.get_string("ui." + resource))
	return ", ".join(parts)

func refresh() -> void:
	if not is_instance_valid(map_view): return
	council.tabs.set_tab_title(3, LocalizationManager.get_string("ui.map"))
	council.tabs.set_tab_title(4, LocalizationManager.get_string("ui.workshop"))
	map_view.queue_redraw()
	var world:Node=get_tree().current_scene
	var fighting:bool=world!=null and world.has_method("in_combat") and world.in_combat()
	var town := CampaignSystem.town(map_view.selected)
	map_details.text = LocalizationManager.get_string(town.name) + " · " + LocalizationManager.get_string("ui.danger") + " " + str(int(town.danger)) + "/5 · " + LocalizationManager.get_string("ui.travel_cost")
	travel_button.disabled = town.id not in CampaignSystem.roads or not CampaignSystem.can_pay(CampaignSystem.definition.travel_cost) or fighting
	travel_button.tooltip_text=LocalizationManager.get_string("ui.travel_requirements") if travel_button.disabled else LocalizationManager.get_string("ui.travel_cost")
	home_button.disabled=not CampaignSystem.can_pay(CampaignSystem.definition.travel_cost) or fighting
	home_button.tooltip_text=travel_button.tooltip_text if home_button.disabled else LocalizationManager.get_string("ui.travel_cost")
	for data in WorkshopSystem.definitions:
		var level: int = WorkshopSystem.levels.get(data.id, 0)
		var cost: Dictionary = data.cost.duplicate()
		for resource in cost: cost[resource] *= level + 1
		building_buttons[data.id].text = LocalizationManager.get_string(data.name) + " " + str(level) + "/3 · " + costs(cost)
		building_buttons[data.id].disabled = level >= 3 or not CampaignSystem.can_pay(cost)
		building_buttons[data.id].tooltip_text=LocalizationManager.get_string("ui.max_level" if level>=3 else "ui.resources_required") if building_buttons[data.id].disabled else ""
	var selected := craft_list.get_selected_items()
	craft_list.clear()
	for blueprint in WorkshopSystem.crafting:
		var item: Resource = load(blueprint.result)
		craft_list.add_item(LocalizationManager.get_string(item.name_key) + " · " + costs(blueprint.cost))
	if not selected.is_empty(): craft_list.select(selected[0])
	craft_button.disabled = selected.is_empty() or WorkshopSystem.levels.get("forge", 0) < 1
	if not selected.is_empty():
		var blueprint:Dictionary=WorkshopSystem.crafting[selected[0]]
		craft_button.disabled=craft_button.disabled or not CampaignSystem.can_pay(blueprint.cost) or not GameState.can_add_item(load(blueprint.result))
	craft_button.tooltip_text=LocalizationManager.get_string("ui.craft_requirements") if craft_button.disabled else ""
	resource_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(EconomySystem.stockpiles.food), "wood": int(EconomySystem.stockpiles.wood), "ore": int(EconomySystem.stockpiles.ore), "gold": int(EconomySystem.stockpiles.gold)})
