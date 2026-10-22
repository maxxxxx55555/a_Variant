extends Control

@onready var pop_label: Label = $MarginContainer/VBoxContainer/PopLabel
@onready var happy_bar: ProgressBar = $MarginContainer/VBoxContainer/HappyBar
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var forecast_label: Label = $MarginContainer/VBoxContainer/ForecastLabel
@onready var resources_label: Label = $MarginContainer/VBoxContainer/ResourcesLabel

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(func(_d): refresh_ui())
	refresh_ui()

func refresh_ui() -> void:
	if pop_label:
		pop_label.text = LocalizationManager.get_string("ui.population") + ": " + str(PopulationSystem.total_population) + " (" + str(PopulationSystem.available_workers) + " free)"
	if happy_bar:
		happy_bar.value = PopulationSystem.happiness
	if health_bar:
		health_bar.value = PopulationSystem.health
	if forecast_label:
		var days = EconomySystem.get_food_days_remaining()
		forecast_label.text = LocalizationManager.get_string("ui.food_forecast") + ": " + str(days) + " days"
	if resources_label:
		var food = EconomySystem.stockpiles.get("food", 0.0)
		var wood = EconomySystem.stockpiles.get("wood", 0.0)
		var ore = EconomySystem.stockpiles.get("ore", 0.0)
		var gold = EconomySystem.stockpiles.get("gold", 0.0)
		resources_label.text = "Food: %d | Wood: %d | Ore: %d | Gold: %d" % [food, wood, ore, gold]
