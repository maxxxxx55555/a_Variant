extends Control

@onready var pop_label: Label = $MarginContainer/VBoxContainer/PopLabel
@onready var happy_bar: ProgressBar = $MarginContainer/VBoxContainer/HappyBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var forecast_label: Label = $MarginContainer/VBoxContainer/ForecastLabel
@onready var resources_label: Label = $MarginContainer/VBoxContainer/ResourcesLabel
var worker_inputs: Dictionary = {}
var worker_labels: Dictionary = {}
var law_options: Dictionary = {}
var law_labels: Dictionary = {}
var apply_button: Button
var wait_button: Button
var repair_button: Button

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(func(_d): refresh_ui())
	build_controls()
	EventBus.language_changed.connect(func(_lang): refresh_ui())
	EventBus.equipment_updated.connect(refresh_ui)
	refresh_ui()

func build_controls() -> void:
	var container := $MarginContainer/VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 20)
	container.add_child(grid)
	for job in PopulationSystem.jobs:
		var column := VBoxContainer.new()
		grid.add_child(column)
		var label := Label.new()
		column.add_child(label)
		worker_labels[job] = label
		var input := SpinBox.new()
		input.min_value = 0
		input.max_value = 1000
		input.step = 1
		column.add_child(input)
		worker_inputs[job] = input
	apply_button = Button.new()
	container.add_child(apply_button)
	apply_button.pressed.connect(apply_jobs)
	var law_row := HBoxContainer.new()
	law_row.add_theme_constant_override("separation", 24)
	container.add_child(law_row)
	var values := {"taxes": ["low", "normal", "high"], "rations": ["half", "full"], "conscription": ["voluntary", "forced"]}
	for law in values:
		var column := VBoxContainer.new()
		law_row.add_child(column)
		var label := Label.new()
		column.add_child(label)
		law_labels[law] = label
		var option := OptionButton.new()
		column.add_child(option)
		law_options[law] = option
		option.item_selected.connect(func(index):
			SettlementSystem.set_law(law, values[law][index])
			refresh_ui()
		)
	wait_button = Button.new()
	container.add_child(wait_button)
	wait_button.pressed.connect(func(): TimeSystem.advance_day(); refresh_ui())
	repair_button = Button.new()
	container.add_child(repair_button)
	repair_button.pressed.connect(func(): GameState.repair_equipment(); refresh_ui())

func apply_jobs() -> void:
	var assignment := {}
	var count := 0
	for job in worker_inputs:
		assignment[job] = int(worker_inputs[job].value)
		count += assignment[job]
	if count > PopulationSystem.total_population - PopulationSystem.sick_citizens - ArmySystem.get_total_soldiers():
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.workers_invalid"), true)
		return
	PopulationSystem.update_worker_assignments(assignment)
	refresh_ui()

func refresh_ui() -> void:
	if pop_label:
		pop_label.text = LocalizationManager.get_string("ui.population") + ": " + str(PopulationSystem.total_population) + " (" + str(PopulationSystem.available_workers) + " " + LocalizationManager.get_string("ui.free_workers") + ")"
	if happy_bar:
		happy_bar.value = PopulationSystem.happiness
	if health_bar:
		health_bar.value = PopulationSystem.health
	if forecast_label:
		var days = EconomySystem.get_food_days_remaining()
		forecast_label.text = LocalizationManager.get_string("ui.food_forecast") + ": " + (str(days) if days < 999 else "∞")
	if resources_label:
		var food = EconomySystem.stockpiles.get("food", 0.0)
		var wood = EconomySystem.stockpiles.get("wood", 0.0)
		var ore = EconomySystem.stockpiles.get("ore", 0.0)
		var gold = EconomySystem.stockpiles.get("gold", 0.0)
		resources_label.text = LocalizationManager.get_string("ui.resource_summary", {"food": int(food), "wood": int(wood), "ore": int(ore), "gold": int(gold)})
	$MarginContainer/VBoxContainer/HappyLabel.text = LocalizationManager.get_string("ui.happiness")
	$MarginContainer/VBoxContainer/HealthLabel.text = LocalizationManager.get_string("ui.health")
	for job in worker_inputs:
		worker_labels[job].text = LocalizationManager.get_string("job." + job)
		worker_inputs[job].value = PopulationSystem.jobs[job]
	apply_button.text = LocalizationManager.get_string("ui.apply_jobs")
	wait_button.text = LocalizationManager.get_string("ui.wait_day") + " · " + LocalizationManager.get_string("ui.day") + " " + str(TimeSystem.current_day)
	var repair_cost := GameState.get_repair_cost()
	repair_button.text = LocalizationManager.get_string("ui.repair", {"cost": int(repair_cost)})
	repair_button.disabled = repair_cost <= 0 or EconomySystem.stockpiles.gold < repair_cost
	repair_button.tooltip_text=LocalizationManager.get_string("ui.repair_requirements") if repair_button.disabled else ""
	var values := {"taxes": ["low", "normal", "high"], "rations": ["half", "full"], "conscription": ["voluntary", "forced"]}
	for law in law_options:
		law_labels[law].text = LocalizationManager.get_string("law." + law)
		var option: OptionButton = law_options[law]
		option.clear()
		for value in values[law]:
			option.add_item(LocalizationManager.get_string("law." + value))
		option.select(values[law].find(SettlementSystem.current_laws[law]))
