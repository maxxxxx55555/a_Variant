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
	var food_cons = PopulationSystem.total_population * (0.5 if SettlementSystem.current_laws.rations == "half" else 1.0)

	daily_net["food"] = food_prod - food_cons
	daily_net["wood"] = wood_prod
	daily_net["ore"] = ore_prod

	stockpiles["food"] = max(0.0, stockpiles["food"] + daily_net["food"])
	stockpiles["wood"] = max(0.0, stockpiles["wood"] + daily_net["wood"])
	stockpiles["ore"] = max(0.0, stockpiles["ore"] + daily_net["ore"])
	var tax_rates := {"low": 0.25, "normal": 0.5, "high": 1.0}
	stockpiles["gold"] += PopulationSystem.total_population * tax_rates[SettlementSystem.current_laws.taxes]
	if food_prod < food_cons and stockpiles["food"] <= 0:
		PopulationSystem.health = maxf(0, PopulationSystem.health - 5)
		PopulationSystem.happiness = maxf(0, PopulationSystem.happiness - 8)
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.starvation"), true)
	EventBus.settlement_updated.emit()

func get_food_days_remaining() -> int:
	var food_cons = PopulationSystem.total_population * (0.5 if SettlementSystem.current_laws.rations == "half" else 1.0)
	var net_consumption: float = food_cons - PopulationSystem.jobs.get("farmers", 0) * 2.5
	if net_consumption <= 0:
		return 999
	return int(stockpiles["food"] / net_consumption)
