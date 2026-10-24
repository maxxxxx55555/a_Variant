extends Node

signal squad_order_changed(squad_id: int, new_order: String)
signal squad_morale_changed(squad_id: int, new_morale: float)

var selected_squad_index: int = 0

var squads: Array = [
	{
		"squad_id": 1,
		"unit_res_path": "res://data/units/militia_spear.tres",
		"count": 12,
		"morale": 80.0,
		"experience_level": 1,
		"formation": "line",
		"order": "follow"
	},
	{
		"squad_id": 2,
		"unit_res_path": "res://data/units/shield_swordsmen.tres",
		"count": 8,
		"morale": 85.0,
		"experience_level": 2,
		"formation": "shield_wall",
		"order": "follow"
	},
	{
		"squad_id": 3,
		"unit_res_path": "res://data/units/archers.tres",
		"count": 6,
		"morale": 75.0,
		"experience_level": 1,
		"formation": "loose",
		"order": "follow"
	},
	{
		"squad_id": 4,
		"unit_res_path": "res://data/units/heavy_infantry.tres",
		"count": 4,
		"morale": 90.0,
		"experience_level": 3,
		"formation": "shield_wall",
		"order": "follow"
	}
]

func _ready() -> void:
	if TimeSystem:
		TimeSystem.day_passed.connect(_on_day_passed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var idx = event.keycode - KEY_1
			select_squad(idx)

func select_squad(index: int) -> void:
	if index >= 0 and index < squads.size():
		selected_squad_index = index
		var sq = squads[index]
		var res = load(sq.unit_res_path)
		var name_str = LocalizationManager.get_string(res.name_key) if res else "Squad " + str(index + 1)
		var order_str = LocalizationManager.get_string("order." + sq.order)
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.squad_selected", {"unit": name_str, "order": order_str}), false)

func issue_order_to_selected(order_name: String) -> void:
	if selected_squad_index >= 0 and selected_squad_index < squads.size():
		var sq = squads[selected_squad_index]
		sq["order"] = order_name
		squad_order_changed.emit(sq["squad_id"], order_name)
		var order_str = LocalizationManager.get_string("order." + order_name)
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.squad_order_issued", {"order": order_str}), false)

func set_formation_for_selected(formation_name: String) -> void:
	if selected_squad_index >= 0 and selected_squad_index < squads.size():
		var sq = squads[selected_squad_index]
		sq["formation"] = formation_name

func _on_day_passed(_day: int) -> void:
	for sq in squads:
		var res = load(sq.unit_res_path)
		if res:
			var food_needed = sq.count * res.food_consumption
			var wages_needed = sq.count * res.daily_wage

			if EconomySystem.stockpiles.get("food", 0.0) >= food_needed:
				EconomySystem.stockpiles["food"] -= food_needed
			else:
				sq.morale = max(0.0, sq.morale - 15.0)

			if EconomySystem.stockpiles.get("gold", 0.0) >= wages_needed:
				EconomySystem.stockpiles["gold"] -= wages_needed
			else:
				sq.morale = max(0.0, sq.morale - 10.0)

		if sq.morale < 10.0:
			var deserters = int(ceil(sq.count * 0.1))
			sq.count = max(0, sq.count - deserters)
			EventBus.notification_posted.emit(LocalizationManager.get_string("msg.desertion_warning"), true)

		squad_morale_changed.emit(sq.squad_id, sq.morale)
