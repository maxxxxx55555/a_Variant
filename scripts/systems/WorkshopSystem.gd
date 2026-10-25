extends Node

signal changed()

var definitions: Array = []
var crafting: Array = []
var equipment: Array = []
var levels: Dictionary = {}
const PRICES={"food":2.0,"wood":3.0,"ore":5.0,"stone":4.0}

func price_for(resource:String,quantity:int,buying:bool) -> float:
	return float(PRICES.get(resource,0.0))*quantity*(1.0 if buying else 0.65)

func _ready() -> void:
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/buildings.json"))
	crafting = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/crafting.json"))
	equipment = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/equipment.json"))
	TimeSystem.day_passed.connect(_on_day)

func build(id: String) -> bool:
	for definition in definitions:
		if definition.id == id:
			var level: int = levels.get(id, 0)
			if level >= int(definition.max_level):
				return false
			var cost: Dictionary = definition.cost.duplicate()
			for resource in cost:
				cost[resource] *= level + 1
			if not CampaignSystem.pay(cost):
				return false
			levels[id] = level + 1
			AudioManager.play_sound("upgrade")
			changed.emit()
			EventBus.settlement_updated.emit()
			return true
	return false

func craft(id: String) -> bool:
	for blueprint in crafting:
		if blueprint.id == id and levels.get("forge", 0) > 0 and GameState.can_add_item(load(blueprint.result)) and CampaignSystem.pay(blueprint.cost):
			GameState.add_item(load(blueprint.result))
			AudioManager.play_sfx("hit_metal", "SFX_UI")
			changed.emit()
			return true
	return false

func trade(resource: String, quantity: int, buying: bool) -> bool:
	if not PRICES.has(resource) or quantity <= 0 or quantity > 1000:
		return false
	var price: float = price_for(resource,quantity,buying)
	if buying:
		if not CampaignSystem.pay({"gold": price}):
			return false
		EconomySystem.stockpiles[resource] += quantity
	else:
		if not CampaignSystem.pay({resource: quantity}):
			return false
		EconomySystem.stockpiles.gold += price
	changed.emit()
	EventBus.settlement_updated.emit()
	AudioManager.play_sound("coin" if buying else "sale")
	return true

func _on_day(_day: int) -> void:
	var housing: int = 25
	for definition in definitions:
		var level: int = levels.get(definition.id, 0)
		for resource in definition.daily:
			var bonus: float = definition.daily[resource] * level
			if resource == "food": bonus *= [1.0, 1.1, 0.9, 0.6][TimeSystem.current_season_idx]
			if resource == "housing": housing += int(bonus)
			elif resource == "health": PopulationSystem.health = minf(100, PopulationSystem.health + bonus)
			elif resource == "happiness": PopulationSystem.happiness = minf(100, PopulationSystem.happiness + bonus)
			else: EconomySystem.stockpiles[resource] += bonus
	if PopulationSystem.total_population < housing and PopulationSystem.happiness >= 60 and PopulationSystem.health >= 60 and EconomySystem.stockpiles.food >= 30:
		PopulationSystem.total_population += 1
		PopulationSystem.reconcile_workers()
	changed.emit()
	EventBus.settlement_updated.emit()
