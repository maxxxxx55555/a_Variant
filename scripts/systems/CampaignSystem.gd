extends Node

signal changed()
signal campaign_finished(route: String)

var definition: Dictionary = {}
var visited: Array = []
var roads: Array = ["home", "greenhaven"]
var deliveries: Array = []
var reports: Array = []
var explored: Array = []
var fallen: Array = []
var conquests: Array = []
var assaults: Array = []
var completed: Array = []
var companions: Array = []
var brewed: int = 0
var difficulty: int = 1
var iron_mode: bool = false
var iron_dead: bool = false
var active: bool = false
var announced_ending: String = ""
var check_timer: float = 0
var pending_load: Dictionary = {}

func _ready() -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://data/balance/campaign.json"))
	for faction in definition.factions:
		if not FactionSystem.factions.has(faction.id):
			FactionSystem.factions[faction.id] = {"res_path": "res://data/factions/" + faction.id + ".tres", "relationship": faction.relationship, "threat": 0.0, "escalation_level": 0}
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.potion_brewed.connect(func(_recipe): brewed += 1; refresh())
	FactionSystem.faction_relationship_changed.connect(func(_id, _value): refresh())
	TimeSystem.day_passed.connect(func(_day): refresh())

func new_campaign(level: int, iron: bool) -> void:
	visited.clear()
	roads = ["home", "greenhaven"]
	deliveries.clear()
	reports.clear()
	explored.clear()
	fallen.clear()
	conquests.clear()
	assaults.clear()
	completed.clear()
	companions.clear()
	brewed = 0
	difficulty = clampi(level, 0, 3)
	iron_mode = iron
	iron_dead = false
	announced_ending = ""
	active = true
	GameState.inventory.clear()
	GameState.equipment = {"head": null, "torso": null, "legs": null, "weapon": null}
	GameState.player_hp = GameState.max_hp
	GameState.player_stamina = GameState.max_stamina
	GameState.strength_buff_timer = 0
	GameState.timed_effects.clear()
	GameState.poison_timer = 0
	GameState.recalculate_stats()
	TimeSystem.current_day = 1
	TimeSystem.current_week = 1
	TimeSystem.current_season_idx = 0
	TimeSystem.game_time_seconds = 0
	PopulationSystem.total_population = 25
	PopulationSystem.sick_citizens = 0
	PopulationSystem.happiness = 70
	PopulationSystem.health = 85
	PopulationSystem.low_happiness_days = 0
	PopulationSystem.jobs = {"farmers": 8, "woodcutters": 5, "miners": 3, "guards": 2, "blacksmiths": 2}
	EconomySystem.stockpiles = {"food": 150.0, "wood": 80.0, "ore": 40.0, "stone": 50.0, "gold": 200.0}
	ArmySystem.squads.clear()
	ArmySystem.next_squad_id = 1
	PopulationSystem.reconcile_workers()
	SettlementSystem.current_laws = {"taxes": "normal", "rations": "full", "conscription": "voluntary"}
	WorkshopSystem.levels.clear()
	DiplomacySystem.active_treaties.clear()
	DiplomacySystem.treaty_expiry.clear()
	for faction in definition.factions:
		FactionSystem.factions[faction.id] = {"res_path": "res://data/factions/" + faction.id + ".tres", "relationship": faction.relationship, "threat": 0.0, "escalation_level": 0}
	changed.emit()

func town(id: String) -> Dictionary:
	for data in definition.towns:
		if data.id == id:
			return data
	return {}

func faction_exists(id: String) -> bool:
	for data in definition.factions:
		if data.id == id:
			return true
	return false

func bound(id: String) -> bool:
	return id in conquests or DiplomacySystem.has_treaty(id, "alliance")

func talk(id: String) -> void:
	var data := town(id)
	if data.is_empty():
		return
	if id not in visited:
		visited.append(id)
		FactionSystem.update_relationship(data.faction, 5)
	if id not in roads:
		roads.append(id)
	if bound(data.faction) and data.faction not in reports:
		reports.append(data.faction)
	refresh()

func can_pay(cost: Dictionary) -> bool:
	for resource in cost:
		if cost[resource] < 0 or EconomySystem.stockpiles.get(resource, 0) < cost[resource]:
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for resource in cost:
		EconomySystem.stockpiles[resource] -= cost[resource]
	EventBus.settlement_updated.emit()
	return true

func deliver_supplies(id: String) -> bool:
	if not faction_exists(id) or id in deliveries or not pay(definition.delivery_cost):
		return false
	deliveries.append(id)
	FactionSystem.update_relationship(id, 20)
	refresh()
	return true

func camp_ids(id: String, garrison: bool = false) -> Array:
	var result: Array = []
	for index in 3:
		result.append(id + ("_guard_" if garrison else "_raider_") + str(index))
	return result

func camp_cleared(id: String, garrison: bool = false) -> bool:
	for enemy_id in camp_ids(id, garrison):
		if enemy_id not in fallen:
			return false
	return faction_exists(id)

func start_assault(id: String) -> bool:
	var world := get_tree().current_scene
	if not faction_exists(id) or bound(id) or id in assaults or not world or not world.has_method("spawn_garrison"):
		return false
	assaults.append(id)
	FactionSystem.update_relationship(id, -100)
	FactionSystem.factions[id].escalation_level = 5
	world.spawn_garrison(id)
	refresh()
	return true

func capture_faction(id: String) -> bool:
	if id not in assaults or id in conquests or not camp_cleared(id, true):
		return false
	conquests.append(id)
	EconomySystem.stockpiles.gold += 100
	refresh()
	return true

func _on_enemy_died(enemy: Node) -> void:
	if not active or not enemy.has_meta("campaign_id"):
		return
	var id: String = enemy.get_meta("campaign_id")
	if id in fallen:
		return
	fallen.append(id)
	var faction: String = enemy.get_meta("faction_id", "")
	EconomySystem.stockpiles.gold += 12 + difficulty * 3
	if camp_cleared(faction):
		FactionSystem.update_relationship(faction, 20)
	if camp_cleared(faction, true):
		capture_faction(faction)
	GameState.add_item(load("res://data/potions/healing_herb.tres"), 2)
	var loot: Array = WorkshopSystem.equipment
	if fallen.size() % 2 == 0 and not loot.is_empty():
		var tier: int = mini(3, int(fallen.size() / 8))
		var candidates := loot.filter(func(item): return int(item.tier) == tier + 1)
		if not candidates.is_empty():
			GameState.add_item(load(candidates[fallen.size() % candidates.size()].path))
	refresh()

func objective_met(quest: Dictionary) -> bool:
	var id: String = quest.get("faction", "")
	match quest.kind:
		"visit": return quest.town in visited
		"delivery": return id in deliveries
		"camp": return camp_cleared(id)
		"trust": return FactionSystem.factions[id].relationship >= 60 or id in conquests
		"oath": return bound(id)
		"report": return id in reports and bound(id)
		"survey": return (id + "_shrine") in explored
		"companion":
			match quest.companion:
				"warrior_shield": return camp_cleared(id)
				"archer_scout": return camp_cleared(id) and visited.size() >= 3
				"healer_alchemist": return id in deliveries and brewed >= 3
				"mercenary_commander": return camp_cleared(id) and ArmySystem.get_total_soldiers() >= 5
	return false

func prerequisites_met(quest: Dictionary) -> bool:
	for required in quest.requires:
		if required not in completed:
			return false
	return true

func active_quests() -> Array:
	return definition.quests.filter(func(quest): return quest.id not in completed and prerequisites_met(quest))

func refresh() -> void:
	if not active:
		return
	for quest in definition.quests:
		if quest.id in completed or not prerequisites_met(quest) or not objective_met(quest):
			continue
		completed.append(quest.id)
		EconomySystem.stockpiles.gold += quest.reward
		if quest.kind == "companion" and quest.companion not in companions:
			companions.append(quest.companion)
		if quest.kind == "report":
			var index: int = definition.factions.find(definition.factions.filter(func(f): return f.id == quest.faction)[0])
			if index < 7 and definition.towns[index + 1].id not in roads:
				roads.append(definition.towns[index + 1].id)
		EventBus.notification_posted.emit(LocalizationManager.get_string(quest.title) + " · +" + str(quest.reward), false)
	var route := ending()
	if not route.is_empty() and announced_ending.is_empty():
		announced_ending = route
		AudioManager.play_sound("victory")
		campaign_finished.emit(route)
	changed.emit()

func ending() -> String:
	if not active or reports.size() < 8:
		return ""
	for faction in definition.factions:
		if not bound(faction.id):
			return ""
	return "military" if conquests.size() == 8 else "diplomatic" if conquests.is_empty() else "mixed"

func explore(point: Dictionary) -> bool:
	if point.id in explored or point.kind == "camp":
		return false
	explored.append(point.id)
	EconomySystem.stockpiles.food += 8
	EconomySystem.stockpiles.wood += 5
	EconomySystem.stockpiles.ore += 3
	GameState.add_item(load("res://data/potions/healing_herb.tres"), 3)
	var herbs := ["ember_bloom", "river_mint", "stone_moss", "marsh_root"]
	GameState.add_item(load("res://data/potions/" + herbs[explored.size() % herbs.size()] + ".tres"), 3)
	if point.kind == "shrine":
		FactionSystem.update_relationship(point.faction, 10)
	refresh()
	return true

func travel(id: String) -> bool:
	var world := get_tree().current_scene
	if id not in roads or not world or not world.has_method("travel_to") or world.in_combat():
		return false
	if not pay(definition.travel_cost):
		return false
	TimeSystem.advance_day()
	world.travel_to(id)
	return true

func capture_state() -> Dictionary:
	return {"visited": visited.duplicate(), "roads": roads.duplicate(), "deliveries": deliveries.duplicate(), "reports": reports.duplicate(), "explored": explored.duplicate(), "fallen": fallen.duplicate(), "conquests": conquests.duplicate(), "assaults": assaults.duplicate(), "completed": completed.duplicate(), "companions": companions.duplicate(), "brewed": brewed, "difficulty": difficulty, "iron_mode": iron_mode, "iron_dead": iron_dead, "active": active, "announced_ending": announced_ending}

func restore_state(data: Dictionary) -> void:
	for key in ["visited", "roads", "deliveries", "reports", "explored", "fallen", "conquests", "assaults", "completed", "companions"]:
		set(key, data.get(key, ["home", "greenhaven"] if key == "roads" else []).duplicate())
	brewed = int(data.get("brewed", 0))
	difficulty = clampi(int(data.get("difficulty", 1)), 0, 3)
	iron_mode = data.get("iron_mode", false)
	iron_dead = data.get("iron_dead", false)
	active = data.get("active", false)
	announced_ending = data.get("announced_ending", "")
	changed.emit()
