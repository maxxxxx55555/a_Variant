extends Node

signal squad_order_changed(squad_id: int, new_order: String)
signal squad_morale_changed(squad_id: int, new_morale: float)
signal roster_changed()

const UNIT_IDS := ["militia_spear", "shield_swordsmen", "archers", "heavy_infantry"]
const ORDERS := ["follow", "hold", "attack", "retreat"]
const FORMATIONS := ["line", "shield_wall", "loose"]
const SOLDIER_SCRIPT = preload("res://scripts/ai/SoldierActor.gd")
var selected_squad_index: int = 0
var squads: Array = []
var next_squad_id: int = 1
var visual_timer: float = 0
var visual_actors: Array[Node3D] = []

func _ready() -> void:
	TimeSystem.day_passed.connect(_on_day_passed)

func unit_data(unit_id: String) -> Resource:
	if unit_id not in UNIT_IDS:
		return null
	return load("res://data/units/" + unit_id + ".tres")

func get_total_soldiers() -> int:
	var count := 0
	for squad in squads:
		count += int(squad.count)
	return count

func get_army_power() -> float:
	var result := 0.0
	for squad in squads:
		var data = load(squad.unit_res_path)
		result += squad.count * (data.health * 0.04 + data.damage * 0.1 + data.defense * 0.06) * (0.5 + squad.morale / 200.0)
	return result

func get_upkeep() -> Dictionary:
	var result := {"food": 0.0, "gold": 0.0}
	for squad in squads:
		var data = load(squad.unit_res_path)
		result.food += squad.count * data.food_consumption
		result.gold += squad.count * data.daily_wage
	return result

func recruit(unit_id: String, count: int) -> bool:
	var data := unit_data(unit_id)
	if not data or count <= 0 or count > PopulationSystem.available_workers:
		return false
	var cost: float = data.recruit_gold * count
	if EconomySystem.stockpiles.gold < cost:
		return false
	EconomySystem.stockpiles.gold -= cost
	var target: Dictionary = {}
	for squad in squads:
		if squad.unit_res_path == data.resource_path:
			target = squad
			break
	if target.is_empty():
		target = {"squad_id": next_squad_id, "unit_res_path": data.resource_path, "count": 0, "morale": 80.0, "experience_level": 1, "formation": data.formation_type, "order": "follow", "low_morale_days": 0, "target": [0.0, 0.0, 0.0]}
		next_squad_id += 1
		squads.append(target)
	target.count += count
	PopulationSystem.reconcile_workers()
	roster_changed.emit()
	EventBus.settlement_updated.emit()
	return true

func select_squad(index: int) -> void:
	if index >= 0 and index < squads.size():
		selected_squad_index = index
		roster_changed.emit()

func issue_order_to_selected(order_name: String) -> void:
	if order_name not in ORDERS or squads.is_empty():
		return
	var squad: Dictionary = squads[clampi(selected_squad_index, 0, squads.size() - 1)]
	squad.order = order_name
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var origin: Vector3 = players[0].global_position
		squad.target = [origin.x, origin.y, origin.z]
	squad_order_changed.emit(squad.squad_id, order_name)
	roster_changed.emit()

func set_formation_for_selected(formation: String) -> void:
	if formation in FORMATIONS and not squads.is_empty():
		selected_squad_index = clampi(selected_squad_index,0,squads.size()-1)
		squads[selected_squad_index].formation = formation
		roster_changed.emit()

func squad_by_id(id: int) -> Dictionary:
	for squad in squads:
		if squad.squad_id == id:
			return squad
	return {}

func register_casualty(id: int, count: int) -> void:
	if count <= 0: return
	var squad := squad_by_id(id)
	if squad.is_empty():
		return
	var losses := mini(count, int(squad.count))
	squad.count -= losses
	PopulationSystem.total_population = maxi(0, PopulationSystem.total_population - losses)
	PopulationSystem.happiness = maxf(0, PopulationSystem.happiness - losses)
	PopulationSystem.reconcile_workers()
	roster_changed.emit()

func disband_selected() -> void:
	if not squads.is_empty():
		squads.remove_at(clampi(selected_squad_index, 0, squads.size() - 1))
		selected_squad_index = 0
		PopulationSystem.reconcile_workers()
		roster_changed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode >= KEY_1 and event.keycode <= KEY_5:
		select_squad(event.keycode - KEY_1)

func _on_day_passed(_day: int) -> void:
	for squad in squads:
		var data = load(squad.unit_res_path)
		var food: float = squad.count * data.food_consumption
		var wages: float = squad.count * data.daily_wage
		var supplied: bool = EconomySystem.stockpiles.food >= food and EconomySystem.stockpiles.gold >= wages
		EconomySystem.stockpiles.food = maxf(0, EconomySystem.stockpiles.food - food)
		EconomySystem.stockpiles.gold = maxf(0, EconomySystem.stockpiles.gold - wages)
		squad.morale = clampf(squad.morale + (2 if supplied else -15), 0, 100)
		squad.low_morale_days = int(squad.get("low_morale_days", 0)) + 1 if squad.morale < 10 else 0
		if squad.low_morale_days >= 3 and squad.count > 0:
			var deserters := maxi(1, int(ceil(squad.count * 0.1)))
			squad.count -= deserters
			PopulationSystem.total_population = maxi(0, PopulationSystem.total_population - deserters)
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.desertion_warning"), true)
		squad_morale_changed.emit(squad.squad_id, squad.morale)
	PopulationSystem.reconcile_workers()
	roster_changed.emit()

func _process(delta: float) -> void:
	visual_timer -= delta
	if visual_timer > 0:
		return
	visual_timer = 0.5
	var scene := get_tree().current_scene
	var players := get_tree().get_nodes_in_group("player")
	if not scene is Node3D or players.is_empty():
		return
	visual_actors = visual_actors.filter(func(actor): return is_instance_valid(actor) and not actor.is_queued_for_deletion())
	for actor in visual_actors:
		if squad_by_id(actor.squad_id).is_empty() or squad_by_id(actor.squad_id).count <= 0:
			actor.queue_free()
	for squad in squads:
		var desired := mini(4, int(squad.count))
		var actors := visual_actors.filter(func(actor): return actor.squad_id == squad.squad_id and not actor.is_queued_for_deletion())
		while actors.size() > desired:
			actors.pop_back().queue_free()
		while actors.size() < desired:
			var actor := SOLDIER_SCRIPT.new()
			actor.squad_id = squad.squad_id
			actor.formation_index = actors.size()
			actor.represented_count = int(squad.count / desired) + (1 if actors.size() < int(squad.count) % desired else 0)
			scene.add_child(actor)
			actor.global_position = players[0].global_position + Vector3(2 + actors.size(), 0.5, 3)
			visual_actors.append(actor)
			actors.append(actor)
		for index in actors.size():
			actors[index].formation_index = index
			var represented := int(squad.count / desired) + (1 if index < int(squad.count) % desired else 0)
			actors[index].resize_representation(represented)
