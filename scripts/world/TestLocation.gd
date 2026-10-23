extends Node3D

@onready var hud: Control = $CanvasLayer/HUD
@onready var inventory_ui: Control = $CanvasLayer/InventoryUI
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var alchemy_ui: Control = $CanvasLayer/AlchemyUI
@onready var settlement_ui: Control = $CanvasLayer/SettlementUI
@onready var player: Node3D = $Player
@onready var enemy: Node3D = $Enemy
@onready var armor_pickup: Node3D = $ArmorPickup

var current_objective_step: int = 1

func _ready() -> void:
	inventory_ui.visible = false
	pause_menu.visible = false
	if alchemy_ui: alchemy_ui.visible = false
	if settlement_ui: settlement_ui.visible = false

	if GameState.inventory.is_empty():
		var sword_res = load("res://data/weapons/iron_sword.tres")
		if sword_res:
			GameState.add_item(sword_res, 1)

		var potion_res = load("res://data/potions/health_potion.tres")
		if potion_res:
			GameState.add_item(potion_res, 2)

		var herb_res = load("res://data/potions/healing_herb.tres")
		if herb_res:
			GameState.add_item(herb_res, 4)

	# Connect signals for objective tracking
	EventBus.enemy_died.connect(_on_enemy_died)
	if ArmySystem:
		ArmySystem.squad_order_changed.connect(_on_squad_order_changed)
	if DiplomacySystem:
		DiplomacySystem.treaty_signed.connect(_on_treaty_signed)

	show_current_objective()

func show_current_objective() -> void:
	var key = ""
	match current_objective_step:
		1: key = "objective.defeat_enemy"
		2: key = "objective.brew_potion"
		3: key = "objective.manage_settlement"
		4: key = "objective.command_army"
		5: key = "objective.diplomacy_treaty"
		_: key = "msg.vertical_slice_completed"

	var text = LocalizationManager.get_string(key)
	EventBus.notification_posted.emit("Current Objective: " + text, false)

func advance_objective() -> void:
	current_objective_step += 1
	show_current_objective()

func _on_enemy_died(_enemy_node: Node) -> void:
	if current_objective_step == 1:
		advance_objective()

func _on_squad_order_changed(_squad_id: int, _new_order: String) -> void:
	if current_objective_step == 4:
		advance_objective()

func _on_treaty_signed(_faction_id: String, _treaty_type: String) -> void:
	if current_objective_step == 5:
		current_objective_step = 6
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.vertical_slice_completed"), false)

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	elif Input.is_action_just_pressed("pause"):
		toggle_pause()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_B:
		toggle_settlement()

func toggle_inventory() -> void:
	if pause_menu.visible:
		return
	inventory_ui.visible = not inventory_ui.visible
	if alchemy_ui: alchemy_ui.visible = false
	if settlement_ui: settlement_ui.visible = false
	if inventory_ui.visible:
		if AudioManager: AudioManager.play_sound("inventory_open")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if current_objective_step == 2:
			advance_objective()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_settlement() -> void:
	if pause_menu.visible:
		return
	if settlement_ui:
		settlement_ui.visible = not settlement_ui.visible
		inventory_ui.visible = false
		if alchemy_ui: alchemy_ui.visible = false
		if settlement_ui.visible:
			if AudioManager: AudioManager.play_sound("ui_click")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			if current_objective_step == 3:
				advance_objective()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_pause() -> void:
	if inventory_ui.visible or (alchemy_ui and alchemy_ui.visible) or (settlement_ui and settlement_ui.visible):
		inventory_ui.visible = false
		if alchemy_ui: alchemy_ui.visible = false
		if settlement_ui: settlement_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused
	if pause_menu.visible:
		if AudioManager: AudioManager.play_sound("ui_click")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_world_state() -> Dictionary:
	var state = {
		"player_pos": [player.global_position.x, player.global_position.y, player.global_position.z] if is_instance_valid(player) else [0, 0, 0],
		"enemy_alive": is_instance_valid(enemy) and not enemy.is_dead,
		"enemy_hp": enemy.current_hp if is_instance_valid(enemy) else 0.0,
		"enemy_pos": [enemy.global_position.x, enemy.global_position.y, enemy.global_position.z] if is_instance_valid(enemy) else [0, 0, 0],
		"armor_pickup_exists": is_instance_valid(armor_pickup),
		"objective_step": current_objective_step
	}
	return state

func load_world_state(state: Dictionary) -> void:
	if state.has("player_pos") and is_instance_valid(player):
		var p = state["player_pos"]
		player.global_position = Vector3(p[0], p[1], p[2])
	if state.has("enemy_alive"):
		if not state["enemy_alive"] and is_instance_valid(enemy):
			enemy.queue_free()
		elif state["enemy_alive"] and is_instance_valid(enemy):
			enemy.current_hp = state.get("enemy_hp", 80.0)
			var ep = state.get("enemy_pos", [0, 0.5, -8])
			enemy.global_position = Vector3(ep[0], ep[1], ep[2])
	if state.has("armor_pickup_exists") and not state["armor_pickup_exists"] and is_instance_valid(armor_pickup):
		armor_pickup.queue_free()
	if state.has("objective_step"):
		current_objective_step = state["objective_step"]
		show_current_objective()
