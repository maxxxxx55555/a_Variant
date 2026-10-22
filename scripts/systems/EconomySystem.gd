extends Node

var stockpiles: Dictionary = {
	"food": 150.0,
	"wood": 80.0,
	"ore": 40.0,
	"stone": 50.0,
	"gold": 200.0
}

var daily_net: Dictionary = {
	"food": 0.0,
	"wood": 0.0,
	"ore": 0.0,
	"stone": 0.0
}

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(_on_day_passed)

func _on_day_passed(_day: int) -> void:
	# Calculate production based on population jobs
	var farmers = PopulationSystem.jobs.get("farmers", 0)
	var woodcutters = PopulationSystem.jobs.get("woodcutters", 0)
	var miners = PopulationSystem.jobs.get("miners", 0)

	var food_prod = farmers * 2.5
	var wood_prod = woodcutters * 2.0
	var ore_prod = miners * 1.5

	# Daily consumption (1 food per citizen)
	var food_cons = PopulationSystem.total_population * 1.0

	daily_net["food"] = food_prod - food_cons
	daily_net["wood"] = wood_prod
	daily_net["ore"] = ore_prod

	stockpiles["food"] = max(0.0, stockpiles["food"] + daily_net["food"])
	stockpiles["wood"] = max(0.0, stockpiles["wood"] + daily_net["wood"])
	stockpiles["ore"] = max(0.0, stockpiles["ore"] + daily_net["ore"])

func get_food_days_remaining() -> int:
	var food_cons = PopulationSystem.total_population * 1.0
	if food_cons <= 0:
		return 999
	return int(stockpiles["food"] / food_cons)
