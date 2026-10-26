extends Node

signal squad_order_changed(squad_id: int, new_order: String)
signal squad_morale_changed(squad_id: int, new_morale: float)
signal roster_changed()

const UNIT_IDS:Array= ["militia_spear", "shield_swordsmen", "archers", "heavy_infantry"]
const ORDERS:Array= ["follow", "hold", "attack", "retreat"]
const FORMATIONS:Array= ["line", "shield_wall", "loose"]
const SOLDIER_SCRIPT = preload("res://scripts/ai/SoldierActor.gd")
var selected_squad_index: int = 0
var squads: Array = []
var next_squad_id: int = 1
var visual_timer: float = 0
var visual_actors: Array[SOLDIER_SCRIPT] = []

func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	TimeSystem.day_passed.connect(_on_day_passed)

func unit_data(unit_id: String) -> UnitData:
	if unit_id not in UNIT_IDS:
		return null
	return load("res://data/units/"+unit_id+".tres") as UnitData

func get_total_soldiers() -> int:
	var count:int= 0
	for squad:Dictionary in squads:
		var squad_count:int=squad.count
		count += squad_count
	return count

func get_army_power() -> float:
	var result:float= 0.0
	for squad:Dictionary in squads:
		var squad_count:int=squad.count
		var data:UnitData=load(str(squad.unit_res_path)) as UnitData
		result += squad_count * (data.health * 0.04 + data.damage * 0.1 + data.defense * 0.06) * (0.5 + squad.morale / 200.0)
	return result

func get_upkeep() -> Dictionary:
	var result:Dictionary= {"food": 0.0, "gold": 0.0}
	for squad:Dictionary in squads:
		var squad_count:int=squad.count
		var data:UnitData=load(str(squad.unit_res_path)) as UnitData
		result.food += squad_count * data.food_consumption
		result.gold += squad_count * data.daily_wage
	return result

func recruit(unit_id: String, count: int) -> bool:
	var data:UnitData= unit_data(unit_id)
	if not data or count <= 0 or count > PopulationSystem.available_workers:
		return false
	var cost: float = data.recruit_gold * count
	if EconomySystem.stockpiles.gold < cost:
		return false
	EconomySystem.stockpiles.gold -= cost
	var target: Dictionary = {}
	for squad:Dictionary in squads:
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
	var players:Array[Node]= get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var origin: Vector3 = (players[0] as Node3D).global_position
		squad.target = [origin.x, origin.y, origin.z]
	squad_order_changed.emit(squad.squad_id, order_name)
	roster_changed.emit()

func set_formation_for_selected(formation: String) -> void:
	if formation in FORMATIONS and not squads.is_empty():
		selected_squad_index = clampi(selected_squad_index,0,squads.size()-1)
		squads[selected_squad_index].formation = formation
		roster_changed.emit()

func squad_by_id(id: int) -> Dictionary:
	for squad:Dictionary in squads:
		if squad.squad_id == id:
			return squad
	return {}

func register_casualty(id: int, count: int) -> void:
	if count <= 0: return
	var squad:Dictionary= squad_by_id(id)
	if squad.is_empty():
		return
	var squad_count:int=squad.count
	var losses:int= mini(count, squad_count)
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
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).keycode >= KEY_1 and (event as InputEventKey).keycode <= KEY_5:
		select_squad((event as InputEventKey).keycode - KEY_1)

func _on_day_passed(_day: int) -> void:
	for squad:Dictionary in squads:
		var squad_count:int=squad.count
		var data:UnitData=load(str(squad.unit_res_path)) as UnitData
		var food: float = squad_count * data.food_consumption
		var wages: float = squad_count * data.daily_wage
		var supplied: bool = EconomySystem.stockpiles.food >= food and EconomySystem.stockpiles.gold >= wages
		var remaining_food:float=EconomySystem.stockpiles.food-food
		EconomySystem.stockpiles.food=maxf(0,remaining_food)
		var remaining_gold:float=EconomySystem.stockpiles.gold-wages
		EconomySystem.stockpiles.gold=maxf(0,remaining_gold)
		var morale:float=squad.morale
		squad.morale=clampf(morale+(2 if supplied else -15),0,100)
		var low_days:int=squad.get("low_morale_days",0)
		squad.low_morale_days=low_days+1 if squad.morale<10 else 0
		if squad.low_morale_days >= 3 and squad.count > 0:
			var deserters:int= maxi(1, ceili(float(squad_count)*0.1))
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
	var scene:Node= get_tree().current_scene
	var players:Array[Node]= get_tree().get_nodes_in_group("player")
	if not scene is Node3D or players.is_empty():
		return
	# A destroyed Object cannot be converted to the typed callback argument.
	# Prune references before any SoldierActor cast or member access.
	for index:int in range(visual_actors.size()-1,-1,-1):
		var reference:Variant=visual_actors[index]
		if not is_instance_valid(reference):
			visual_actors.remove_at(index)
			continue
		var live_actor:SOLDIER_SCRIPT=visual_actors[index]
		if live_actor.is_queued_for_deletion():
			visual_actors.remove_at(index)
	for actor:SOLDIER_SCRIPT in visual_actors:
		if squad_by_id(actor.squad_id).is_empty() or squad_by_id(actor.squad_id).count <= 0:
			actor.queue_free()
	for squad:Dictionary in squads:
		var squad_count:int=squad.count
		var desired:int= mini(4, squad_count)
		var actors:Array[SOLDIER_SCRIPT]= visual_actors.filter(func(actor:SOLDIER_SCRIPT)->bool: return actor.squad_id == squad.squad_id and not actor.is_queued_for_deletion())
		while actors.size() > desired:
			var removed:SOLDIER_SCRIPT=actors.pop_back()
			removed.queue_free()
		while actors.size() < desired:
			var actor:SOLDIER_SCRIPT= SOLDIER_SCRIPT.new()
			actor.squad_id = squad.squad_id
			actor.formation_index = actors.size()
			actor.represented_count = int(float(squad_count)/desired) + (1 if actors.size() < squad_count % desired else 0)
			scene.add_child(actor)
			actor.global_position = (players[0] as Node3D).global_position + Vector3(2 + actors.size(), 0.5, 3)
			visual_actors.append(actor)
			actors.append(actor)
		for index:int in actors.size():
			actors[index].formation_index = index
			var represented:int= int(float(squad_count)/desired) + (1 if index < squad_count % desired else 0)
			actors[index].resize_representation(represented)
