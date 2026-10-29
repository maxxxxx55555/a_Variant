extends Control
const IconView=preload("res://scripts/ui/IconSet.gd")
const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")

@onready var pop_label: Label = $MarginContainer/VBoxContainer/PopLabel
@onready var happy_bar: ProgressBar = $MarginContainer/VBoxContainer/HappyBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var forecast_label: Label = $MarginContainer/VBoxContainer/ForecastLabel
@onready var resources_label: Label = $MarginContainer/VBoxContainer/ResourcesLabel
var worker_inputs:Dictionary[String,SpinBox] = {}
var worker_labels:Dictionary[String,Label] = {}
var law_options:Dictionary[String,OptionButton] = {}
var law_labels:Dictionary[String,Label] = {}
var apply_button: Button
var wait_button: Button
var repair_button: Button
var tier_label: Label
var buildings_heading: Label
var buildings_strip: HBoxContainer
var building_tiles:Dictionary[String,PanelContainer] = {}
var building_pips:Dictionary[String,Array] = {}

func _ready() -> void:
	if TimeSystem:
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		TimeSystem.day_passed.connect(func(_d:Variant)->void: refresh_ui())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	WorkshopSystem.changed.connect(refresh_ui)
	tier_label = Label.new()
	tier_label.name = "TierBadge"
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_override("font", ThemeRef.heading_font(700))
	tier_label.add_theme_font_size_override("font_size", 24)
	var container: Node = $MarginContainer/VBoxContainer
	container.add_child(tier_label)
	container.move_child(tier_label, 0)
	build_buildings(container)
	build_controls()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: refresh_ui())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.equipment_updated.connect(refresh_ui)
	refresh_ui()

func build_buildings(container: Node) -> void:
	var row:HBoxContainer=HBoxContainer.new()
	row.name="BuildingRow"
	row.add_theme_constant_override("separation",18)
	container.add_child(row)
	container.move_child(row,1)
	var header:HBoxContainer=HBoxContainer.new()
	header.add_theme_constant_override("separation",8)
	row.add_child(header)
	var icon:TextureRect=IconView.rect("workshop",Color("c9a227"),Vector2(22,22),"BuildingsIcon")
	header.add_child(icon)
	buildings_heading=Label.new()
	buildings_heading.add_theme_color_override("font_color",Color("e8dcc3"))
	header.add_child(buildings_heading)
	buildings_strip=HBoxContainer.new()
	buildings_strip.name="BuildingStrip"
	buildings_strip.add_theme_constant_override("separation",8)
	buildings_strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(buildings_strip)
	for data:Dictionary in WorkshopSystem.definitions:
		var id:String=str(data.get("id",""))
		var tile:PanelContainer=PanelContainer.new()
		tile.name="Building_"+id
		tile.custom_minimum_size=Vector2(38,44)
		tile.mouse_filter=Control.MOUSE_FILTER_PASS
		buildings_strip.add_child(tile)
		var stack:VBoxContainer=VBoxContainer.new()
		stack.alignment=BoxContainer.ALIGNMENT_CENTER
		stack.add_theme_constant_override("separation",2)
		tile.add_child(stack)
		var picture:TextureRect=IconView.rect("building_"+id,Color("e8dcc3"),Vector2(22,22),id+"Icon")
		picture.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		stack.add_child(picture)
		var pips:HBoxContainer=HBoxContainer.new()
		pips.alignment=BoxContainer.ALIGNMENT_CENTER
		pips.add_theme_constant_override("separation",2)
		stack.add_child(pips)
		var marks:Array[ColorRect]=[]
		for index:int in 3:
			var pip:ColorRect=ColorRect.new()
			pip.custom_minimum_size=Vector2(6,3)
			pip.color=Color("46545d")
			pips.add_child(pip)
			marks.append(pip)
		building_pips[id]=marks
		building_tiles[id]=tile

func build_controls() -> void:
	var container:Node= $MarginContainer/VBoxContainer
	var grid:GridContainer= GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 20)
	container.add_child(grid)
	for job:String in PopulationSystem.jobs:
		var column:VBoxContainer= VBoxContainer.new()
		grid.add_child(column)
		var label:Label= Label.new()
		column.add_child(label)
		worker_labels[job] = label
		var input:SpinBox= SpinBox.new()
		input.min_value = 0
		input.max_value = 1000
		input.step = 1
		column.add_child(input)
		worker_inputs[job] = input
	apply_button = Button.new()
	container.add_child(apply_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	apply_button.pressed.connect(apply_jobs)
	var law_row:HBoxContainer= HBoxContainer.new()
	law_row.add_theme_constant_override("separation", 24)
	container.add_child(law_row)
	var values:Dictionary= {"taxes": ["low", "normal", "high"], "rations": ["half", "full"], "conscription": ["voluntary", "forced"]}
	for law:String in values:
		var column:VBoxContainer= VBoxContainer.new()
		law_row.add_child(column)
		var label:Label= Label.new()
		column.add_child(label)
		law_labels[law] = label
		var option:OptionButton= OptionButton.new()
		column.add_child(option)
		law_options[law] = option
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		option.item_selected.connect(func(index:int)->void:
			SettlementSystem.set_law(law,str(values[law][index]))
			refresh_ui()
		)
	wait_button = Button.new()
	container.add_child(wait_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	wait_button.pressed.connect(func()->void: TimeSystem.advance_day(); refresh_ui())
	repair_button = Button.new()
	container.add_child(repair_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	repair_button.pressed.connect(func()->void: GameState.repair_equipment(); refresh_ui())

func apply_jobs() -> void:
	var assignment:Dictionary= {}
	var count:int= 0
	for job:String in worker_inputs:
		assignment[job] = int(worker_inputs[job].value)
		count += assignment[job]
	if count > PopulationSystem.total_population - PopulationSystem.sick_citizens - ArmySystem.get_total_soldiers():
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.workers_invalid"), true)
		return
	PopulationSystem.update_worker_assignments(assignment)
	refresh_ui()

func refresh_ui() -> void:
	if tier_label:
		var tier: int = WorkshopSystem.tier()
		tier_label.text = LocalizationManager.get_string("settlement.tier_badge", {"name": LocalizationManager.get_string("settlement.tier." + str(tier)), "level": tier})
		tier_label.add_theme_color_override("font_color", Color("C9A227") if tier >= 3 else Color("E8DCC3") if tier >= 1 else Color("9aa8a8"))
	if buildings_heading:
		buildings_heading.text=LocalizationManager.get_string("settlement.buildings")
	for data:Dictionary in WorkshopSystem.definitions:
		var id:String=str(data.get("id",""))
		if not building_tiles.has(id):continue
		@warning_ignore("unsafe_call_argument")
		var level:int=int(WorkshopSystem.levels.get(id,0))
		var building_name:String=LocalizationManager.get_string(str(data.get("name","")))
		building_tiles[id].tooltip_text=building_name+" · "+str(level)+"/3"
		building_tiles[id].modulate=Color.WHITE if level>0 else Color(0.72,0.75,0.77,0.9)
		var surface:StyleBoxFlat=ThemeRef.panel(Color(0.10,0.12,0.14,0.9),Color("c9a227") if level>0 else Color("46545d"))
		surface.set_border_width_all(1)
		building_tiles[id].add_theme_stylebox_override("panel",surface)
		var marks:Array=building_pips.get(id,[])
		for index:int in marks.size():
			@warning_ignore("unsafe_cast")
			var mark:ColorRect=marks[index] as ColorRect
			mark.color=Color("c9a227") if index<level else Color("46545d")
	if pop_label:
		pop_label.text = LocalizationManager.get_string("ui.population") + ": " + str(PopulationSystem.total_population) + " (" + str(PopulationSystem.available_workers) + " " + LocalizationManager.get_string("ui.free_workers") + ")"
	if happy_bar:
		happy_bar.value = PopulationSystem.happiness
		happy_bar.add_theme_stylebox_override("fill", _meter_fill(PopulationSystem.happiness))
	if health_bar:
		health_bar.value = PopulationSystem.health
		health_bar.add_theme_stylebox_override("fill", _meter_fill(PopulationSystem.health))
	if forecast_label:
		var days:int= EconomySystem.get_food_days_remaining()
		forecast_label.text = LocalizationManager.get_string("ui.food_forecast") + ": " + (str(days) if days < 999 else "∞")
	if resources_label:
		var food:float= EconomySystem.stockpiles.get("food", 0.0)
		var wood:float= EconomySystem.stockpiles.get("wood", 0.0)
		var ore:float= EconomySystem.stockpiles.get("ore", 0.0)
		var gold:float= EconomySystem.stockpiles.get("gold", 0.0)
		resources_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(food), "wood": int(wood), "ore": int(ore), "gold": int(gold)})
	($MarginContainer/VBoxContainer/HappyLabel as Label).text = LocalizationManager.get_string("ui.happiness")
	($MarginContainer/VBoxContainer/HealthLabel as Label).text = LocalizationManager.get_string("ui.health")
	for job:String in worker_inputs:
		worker_labels[job].text = LocalizationManager.get_string("job." + job)
		worker_inputs[job].value = PopulationSystem.jobs[job]
	apply_button.text = LocalizationManager.get_string("ui.apply_jobs")
	wait_button.text = LocalizationManager.get_string("ui.wait_day") + " · " + LocalizationManager.get_string("ui.day") + " " + str(TimeSystem.current_day)
	var repair_cost:float= GameState.get_repair_cost()
	repair_button.text = LocalizationManager.get_string("ui.repair", {"cost": int(repair_cost)})
	repair_button.disabled = repair_cost <= 0 or EconomySystem.stockpiles.gold < repair_cost
	repair_button.tooltip_text=LocalizationManager.get_string("ui.repair_requirements") if repair_button.disabled else ""
	var values:Dictionary= {"taxes": ["low", "normal", "high"], "rations": ["half", "full"], "conscription": ["voluntary", "forced"]}
	for law:String in law_options:
		law_labels[law].text = LocalizationManager.get_string("law." + law)
		var option: OptionButton = law_options[law]
		option.clear()
		for value:String in values[law]:
			option.add_item(LocalizationManager.get_string("law." + value))
		var law_values:Array=values[law]
		option.select(law_values.find(SettlementSystem.current_laws[law]))

func _meter_fill(value: float) -> StyleBoxFlat:
	var color: Color = ThemeRef.DANGER
	if value >= 60.0: color = ThemeRef.SAGE
	elif value >= 35.0: color = ThemeRef.BRASS
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	return fill
