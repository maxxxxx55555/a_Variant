extends Node3D
const PlayerView=preload("res://scripts/characters/Player.gd")
const EnemyView=preload("res://scripts/ai/Enemy.gd")
const PickupView=preload("res://scripts/items/WorldItem.gd")
const InventoryView=preload("res://scripts/ui/InventoryUI.gd")
const PauseView=preload("res://scripts/ui/PauseMenu.gd")
const AlchemyView=preload("res://scripts/ui/AlchemyUI.gd")
const SettlementView=preload("res://scripts/ui/SettlementUI.gd")
const CouncilView=preload("res://scripts/ui/StrategyUI.gd")
const HUDView=preload("res://scripts/ui/HUD.gd")
const CodexView=preload("res://scripts/ui/CodexUI.gd")

@onready var hud: HUDView = $CanvasLayer/HUD
@onready var inventory_ui: InventoryView = $CanvasLayer/InventoryUI
@onready var pause_menu: PauseView = $CanvasLayer/PauseMenu
@onready var alchemy_ui: AlchemyView = $CanvasLayer/AlchemyUI
@onready var settlement_ui: SettlementView = $CanvasLayer/SettlementUI
@onready var player: PlayerView = $Player
@onready var enemy: EnemyView = $Enemy
@onready var armor_pickup: PickupView = $ArmorPickup

const ENEMY_SCENE:PackedScene= preload("res://scenes/enemies/enemy.tscn")
const PICKUP_SCENE:PackedScene= preload("res://scenes/items/world_item.tscn")
const TUTORIAL_SCRIPT = preload("res://scripts/systems/TutorialSystem.gd")
var tutorial: TUTORIAL_SCRIPT
var music_check_time: float = 0.0
var strategy_ui: CouncilView
var codex_ui: CodexView

func _ready() -> void:
	AudioManager.play_music("exploration")
	AudioManager.start_ambience("forest", Vector3(0, 3, 0))
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.player_died.connect(_on_player_died)
	tutorial = TUTORIAL_SCRIPT.new()
	add_child(tutorial)
	var menu_theme:Theme= preload("res://scripts/ui/MarchTheme.gd").create()
	hud.theme = menu_theme
	strategy_ui = preload("res://scripts/ui/StrategyUI.gd").new()
	$CanvasLayer.add_child(strategy_ui)
	strategy_ui.theme = menu_theme
	strategy_ui.hide()
	codex_ui = CodexView.new()
	$CanvasLayer.add_child(codex_ui)
	codex_ui.theme = menu_theme
	codex_ui.hide()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	codex_ui.closed.connect(toggle_codex)
	for menu:Control in [inventory_ui, alchemy_ui, settlement_ui, pause_menu]:
		menu.theme = menu_theme
		if menu == pause_menu:
			continue
		var close_button:Button= Button.new()
		close_button.name = "CloseButton"
		close_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		menu.add_child(close_button)
		close_button.offset_left = -230
		close_button.offset_right = -30
		close_button.offset_top = 20
		close_button.offset_bottom = 68
		close_button.text = LocalizationManager.get_string("ui.close") + " (Esc)"
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		close_button.pressed.connect(toggle_pause)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(_localize_close_buttons)
	inventory_ui.visible = false
	pause_menu.visible = false
	if alchemy_ui: alchemy_ui.visible = false
	if settlement_ui: settlement_ui.visible = false

	if GameState.inventory.is_empty():
		var sword_res:Resource= load("res://data/weapons/iron_sword.tres")
		if sword_res:
			# Initial equipment is granted only to the empty inventory on a new run.
			@warning_ignore("return_value_discarded")
			GameState.add_item(sword_res, 1)

		var potion_res:Resource= load("res://data/potions/health_potion.tres")
		if potion_res:
			# Initial equipment is granted only to the empty inventory on a new run.
			@warning_ignore("return_value_discarded")
			GameState.add_item(potion_res, 2)

		var herb_res:Resource= load("res://data/potions/healing_herb.tres")
		if herb_res:
			# Initial equipment is granted only to the empty inventory on a new run.
			@warning_ignore("return_value_discarded")
			GameState.add_item(herb_res, 4)
	_sync_menu_state()

func _localize_close_buttons(_language: String) -> void:
	for menu:Control in [inventory_ui, alchemy_ui, settlement_ui]:
		(menu.get_node("CloseButton") as Button).text = LocalizationManager.get_string("ui.close") + " (Esc)"

func get_objective_state() -> Dictionary:
	return tutorial.get_state()

func _process(delta: float) -> void:
	music_check_time -= delta
	if music_check_time > 0:
		return
	music_check_time = 0.35
	AudioManager.play_music(desired_music())

func desired_music() -> String:
	var in_combat:bool= false
	for actor:EnemyView in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(actor) and not actor.is_dead and is_instance_valid(actor.target_player) and actor.global_position.distance_to(player.global_position) < 35:
			in_combat = true
	if settlement_ui.visible:
		return "settlement"
	elif in_combat:
		return "combat"
	return "exploration"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event.is_action_pressed("pause"):
		toggle_pause()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_B:
		toggle_settlement()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_C:
		toggle_alchemy()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_K:
		toggle_codex()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode in [KEY_R, KEY_F, KEY_J]:
		toggle_strategy([KEY_R, KEY_F, KEY_J].find((event as InputEventKey).keycode))

func toggle_inventory() -> void:
	if pause_menu.visible:
		return
	inventory_ui.visible = not inventory_ui.visible
	strategy_ui.hide()
	codex_ui.hide()
	if alchemy_ui: alchemy_ui.visible = false
	if settlement_ui: settlement_ui.visible = false
	if inventory_ui.visible:
		if AudioManager: AudioManager.play_sound("inventory_open")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_menu_state()

func toggle_settlement() -> void:
	if pause_menu.visible:
		return
	if settlement_ui:
		strategy_ui.hide()
		codex_ui.hide()
		settlement_ui.visible = not settlement_ui.visible
		inventory_ui.visible = false
		if alchemy_ui: alchemy_ui.visible = false
		if settlement_ui.visible:
			if AudioManager: AudioManager.play_sound("ui_click")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_menu_state()
	settlement_ui.refresh_ui()

func toggle_alchemy() -> void:
	if pause_menu.visible or GameState.player_hp <= 0:
		return
	alchemy_ui.visible = not alchemy_ui.visible
	strategy_ui.hide()
	codex_ui.hide()
	inventory_ui.visible = false
	settlement_ui.visible = false
	alchemy_ui.update_info()
	_sync_menu_state()

func toggle_codex() -> void:
	if pause_menu.visible:
		return
	codex_ui.visible = not codex_ui.visible
	if codex_ui.visible:
		inventory_ui.hide()
		alchemy_ui.hide()
		settlement_ui.hide()
		strategy_ui.hide()
		codex_ui.refresh()
		codex_ui.focus_first()
		if AudioManager: AudioManager.play_sound("ui_focus")
	_sync_menu_state()

func _sync_menu_state() -> void:
	var menu_open:bool= inventory_ui.visible or pause_menu.visible or alchemy_ui.visible or settlement_ui.visible or (is_instance_valid(strategy_ui) and strategy_ui.visible) or (is_instance_valid(codex_ui) and codex_ui.visible)
	get_tree().paused = menu_open
	AudioManager.set_scene_paused(menu_open)
	hud.visible = not menu_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED

func toggle_pause() -> void:
	if GameState.player_hp <= 0:
		return
	if pause_menu.visible:
		if pause_menu.settings_panel.visible:pause_menu._on_toggle_settings()
		else:pause_menu._on_resume()
		return
	if inventory_ui.visible or (alchemy_ui and alchemy_ui.visible) or (settlement_ui and settlement_ui.visible) or strategy_ui.visible or (codex_ui and codex_ui.visible):
		inventory_ui.visible = false
		if alchemy_ui: alchemy_ui.visible = false
		if settlement_ui: settlement_ui.visible = false
		strategy_ui.hide()
		if codex_ui: codex_ui.hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_sync_menu_state()
		return

	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused
	if pause_menu.visible:
		if AudioManager: AudioManager.play_sound("ui_click")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_menu_state()

func toggle_strategy(index: int) -> void:
	if pause_menu.visible or GameState.player_hp <= 0:
		return
	inventory_ui.hide()
	alchemy_ui.hide()
	settlement_ui.hide()
	strategy_ui.hide()
	codex_ui.hide()
	if strategy_ui.visible and strategy_ui.tabs.current_tab == index:
		strategy_ui.hide()
	else:
		strategy_ui.show_tab(index)
	_sync_menu_state()

func _on_player_died() -> void:
	inventory_ui.hide()
	alchemy_ui.hide()
	settlement_ui.hide()
	strategy_ui.hide()
	codex_ui.hide()
	pause_menu.show()
	pause_menu.resume_btn.text = LocalizationManager.get_string("ui.respawn")
	pause_menu.save_btn.disabled = true
	pause_menu.localize()
	_sync_menu_state()

func restart_run() -> void:
	if CampaignSystem.active and CampaignSystem.iron_mode:return
	GameState.player_hp = GameState.max_hp
	GameState.player_stamina = GameState.max_stamina
	EconomySystem.stockpiles.gold *= 0.8
	for item_value:Variant in GameState.equipment.values():
		if item_value:
			var item:Dictionary=item_value
			var path:String=item.resource_path
			var resource:EquipmentData=load(path) as EquipmentData
			item["durability"] = item.get("durability", resource.durability) * 0.8
	GameState.recalculate_stats()
	EventBus.equipment_updated.emit()
	player.global_position = Vector3(0, 1, 5)
	player.velocity = Vector3.ZERO
	pause_menu.hide()
	pause_menu.save_btn.disabled = false
	pause_menu.localize()
	get_tree().paused = false
	_sync_menu_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.player_hp_changed.emit(GameState.player_hp, GameState.max_hp)
	EventBus.player_stamina_changed.emit(GameState.player_stamina, GameState.max_stamina)

func get_world_state() -> Dictionary:
	var pickups: Array = []
	for item:PickupView in get_tree().get_nodes_in_group("world_items"):
		if is_instance_valid(item) and not item.is_queued_for_deletion():
			pickups.append({"path": item.item_resource.resource_path, "count": item.item_count,
				"pos": [item.position.x, item.position.y, item.position.z]})
	var state:Dictionary= {
		"player_pos": [player.global_position.x, player.global_position.y, player.global_position.z] if is_instance_valid(player) else [0, 0, 0],
		"enemy_alive": is_instance_valid(enemy) and not enemy.is_dead,
		"enemy_hp": maxf(0,enemy.current_hp) if is_instance_valid(enemy) else 0.0,
		"enemy_pos": [enemy.global_position.x, enemy.global_position.y, enemy.global_position.z] if is_instance_valid(enemy) else [0, 0, 0],
		"armor_pickup_exists": is_instance_valid(armor_pickup) and not armor_pickup.is_queued_for_deletion(),
		"pickups": pickups,
		"player_rotation": [player.rotation.y, player.camera.rotation.x],
		"tutorial": tutorial.get_state()
	}
	return state

func load_world_state(state: Dictionary) -> void:
	var tutorial_state:Dictionary=state.get("tutorial",{"enemy_defeated":not state.get("enemy_alive",true)})
	tutorial.restore_state(tutorial_state)
	if state.has("player_pos") and is_instance_valid(player):
		var p:Array=state["player_pos"]
		player.global_position = saved_vector(p)
		player.velocity = Vector3.ZERO
	if state.has("player_rotation"):
		player.rotation.y = state["player_rotation"][0]
		player.camera.rotation.x = state["player_rotation"][1]
	if state.has("enemy_alive"):
		if not state["enemy_alive"] and is_instance_valid(enemy):
			remove_child(enemy)
			enemy.queue_free()
			enemy = null
		elif state["enemy_alive"]:
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
				enemy = ENEMY_SCENE.instantiate()
				enemy.process_mode = Node.PROCESS_MODE_PAUSABLE
				add_child(enemy)
			enemy.is_dead = false
			enemy.current_hp = state.get("enemy_hp", 80.0)
			var ep:Array=state.get("enemy_pos", [0, 0.5, -8])
			enemy.global_position = saved_vector(ep)
	if state.has("pickups"):
		for item:PickupView in get_tree().get_nodes_in_group("world_items"):
			item.get_parent().remove_child(item)
			item.queue_free()
		armor_pickup = null
		for item:Dictionary in state["pickups"]:
			var pickup:PickupView= PICKUP_SCENE.instantiate()
			var pickup_path:String=item["path"]
			pickup.item_resource=load(pickup_path)
			pickup.item_count=item.get("count",1)
			add_child(pickup)
			var pos:Array=item["pos"]
			pickup.position = saved_vector(pos)
			if pickup.item_resource.resource_path.ends_with("leather_armor.tres"):
				armor_pickup = pickup
	elif state.has("armor_pickup_exists"):
		if not state["armor_pickup_exists"] and is_instance_valid(armor_pickup):
			armor_pickup.queue_free()
		elif state["armor_pickup_exists"] and not is_instance_valid(armor_pickup):
			armor_pickup = PICKUP_SCENE.instantiate()
			armor_pickup.item_resource = load("res://data/armors/leather_armor.tres")
			add_child(armor_pickup)
			armor_pickup.position = Vector3(2, 0.5, 3)

# Save policy validates the array shape and finite coordinates before world restoration.
func saved_vector(values:Array)->Vector3:
	var x:float=values[0]
	var y:float=values[1]
	var z:float=values[2]
	return Vector3(x,y,z)
