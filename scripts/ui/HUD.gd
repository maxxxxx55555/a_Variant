extends Control
const PlayerView=preload("res://scripts/characters/Player.gd")
const CompassView=preload("res://scripts/ui/CompassNeedle.gd")
const IconView=preload("res://scripts/ui/IconSet.gd")

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaBar
@onready var notification_label: Label = $NotificationLabel
@onready var crosshair: ColorRect = $Crosshair

@onready var attack_btn: Button = $MobileControls/AttackBtn
@onready var interact_btn: Button = $MobileControls/InteractBtn
@onready var potion_btn: Button = $MobileControls/PotionBtn
@onready var inventory_btn: Button = $MobileControls/InventoryBtn
@onready var town_btn: Button = $MobileControls/TownBtn

var notification_timer: float = 0.0
var controls_label: Label
var alchemy_btn: Button
var council_btn: Button
var codex_btn: Button
var objective_label: Label
var quest_panel: Panel
var quest_label: Label
var quest_distance: Label
var compass: CompassView
var tracker_timer: float = 0.0
var target_health: Label
var target_timer: float = 0
var hit_flash: float = 0
var expanded_help:bool= false
var tutorial_text:String= ""

func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.player_hp_changed.connect(_on_hp_changed)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.notification_posted.connect(_on_notification_posted)
	target_health = Label.new()
	target_health.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	target_health.position = Vector2(-160, 180)
	target_health.size = Vector2(320, 48)
	target_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_health.add_theme_stylebox_override("normal", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.06, 0.14, 0.12, 0.85)))
	target_health.hide()
	add_child(target_health)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.enemy_damaged.connect(func(enemy:Node3D,amount:float,hp:float,max_hp:float)->void:
		var players:Array[Node]=get_tree().get_nodes_in_group("player")
		if players.is_empty() or enemy.global_position.distance_to((players[0] as Node3D).global_position) > 24: return
		target_health.text = "−%d    ·    %d / %d" % [amount, maxf(0, hp), max_hp]
		target_health.show()
		target_timer = 2.5
		hit_flash = 0.16
		spawn_damage_number(amount, enemy.global_position + Vector3.UP * 1.9, max_hp)
	)
	objective_label = Label.new()
	objective_label.position = Vector2(24, 140)
	objective_label.size = Vector2(580, 74)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 21)
	objective_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	objective_label.add_theme_constant_override("shadow_offset_x", 2)
	objective_label.add_theme_constant_override("shadow_offset_y", 2)
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_label.add_theme_stylebox_override("normal", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.06, 0.14, 0.12, 0.85)))
	objective_label.add_theme_color_override("font_color", Color("eadcba"))
	add_child(objective_label)
	quest_panel = Panel.new()
	quest_panel.name = "QuestTracker"
	quest_panel.position = Vector2(24, 224)
	quest_panel.size = Vector2(470, 96)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.09, 0.11, 0.13, 0.90), Color("c9a227")))
	add_child(quest_panel)
	var quest_icon:TextureRect=IconView.rect("quest",Color("c9a227"),Vector2(28,28),"QuestTrackerIcon")
	quest_icon.position=Vector2(14,14)
	quest_panel.add_child(quest_icon)
	quest_label = Label.new()
	quest_label.name = "QuestTrackerTitle"
	quest_label.position = Vector2(50, 10)
	quest_label.size = Vector2(340, 52)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_font_size_override("font_size", 20)
	quest_label.add_theme_color_override("font_color", Color("e8dcc3"))
	quest_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_label)
	quest_distance = Label.new()
	quest_distance.name = "QuestTrackerDistance"
	quest_distance.position = Vector2(50, 62)
	quest_distance.size = Vector2(340, 26)
	quest_distance.add_theme_font_override("font", preload("res://scripts/ui/MarchTheme.gd").numeric_font())
	quest_distance.add_theme_font_size_override("font_size", 18)
	quest_distance.add_theme_color_override("font_color", Color("91a0a7"))
	quest_distance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quest_panel.add_child(quest_distance)
	compass = CompassView.new()
	compass.name = "ObjectiveCompass"
	compass.position = Vector2(392, 16)
	compass.size = Vector2(64, 64)
	quest_panel.add_child(compass)
	quest_panel.hide()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.tutorial_updated.connect(func(text:Variant, done:Variant)->void:
		tutorial_text = text
		refresh_help()
		objective_label.modulate = Color(0.65, 1.0, 0.7) if done else Color.WHITE
	)

	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	if attack_btn: attack_btn.pressed.connect(func()->void: controlled_player().perform_attack())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	if interact_btn: interact_btn.pressed.connect(func()->void: controlled_player().interact())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	if potion_btn: potion_btn.pressed.connect(func()->void: controlled_player().use_quick_potion())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	if inventory_btn: inventory_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_inventory"))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	if town_btn: town_btn.pressed.connect(func()->void:
		var scene:Node= get_tree().current_scene
		if scene and scene.has_method("toggle_settlement"):
			# Scene method is guarded above; no UI-owned simulation action is queued.
			@warning_ignore("return_value_discarded")
			scene.call("toggle_settlement")
	)
	alchemy_btn = Button.new()
	alchemy_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	alchemy_btn.position = Vector2(-520, 30)
	alchemy_btn.size = Vector2(165, 60)
	$MobileControls.add_child(alchemy_btn)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	alchemy_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_alchemy"))
	council_btn = Button.new()
	$MobileControls.add_child(council_btn)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	council_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_strategy",0))
	codex_btn = Button.new()
	codex_btn.name = "CodexButton"
	$MobileControls.add_child(codex_btn)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	codex_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_codex"))
	var top_buttons:Array= [inventory_btn, town_btn, alchemy_btn, council_btn, codex_btn]
	var top_icons:Array[String]= ["inventory","town","potion","army","codex"]
	for i:int in range(top_buttons.size()):
		var button: Button = top_buttons[i]
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		button.offset_left = -230 - i * 220
		button.offset_right = -30 - i * 220
		button.offset_top = 20
		button.offset_bottom = 80
		button.add_theme_font_size_override("font_size", 19)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		IconView.apply(button,top_icons[i],24)
	controls_label = Label.new()
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls_label.position = Vector2(25, -110)
	controls_label.size = Vector2(900, 90)
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.add_theme_font_size_override("font_size", 18)
	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_label.add_theme_stylebox_override("normal", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.06, 0.14, 0.12, 0.8)))
	# A quiet frame keeps both meters legible against snow, fog and bright skies.
	var meter_frame:Panel=Panel.new()
	meter_frame.name="MeterFrame"
	meter_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	meter_frame.position=Vector2(12,12)
	meter_frame.size=Vector2(296,76)
	meter_frame.add_theme_stylebox_override("panel",preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.05,0.09,0.11,0.83),Color("61717a")))
	add_child(meter_frame)
	move_child(meter_frame,0)
	stamina_bar.add_theme_stylebox_override("fill", preload("res://scripts/ui/MarchTheme.gd").panel(Color("789977"), Color("a6b889")))
	for bar:ProgressBar in [hp_bar,stamina_bar]:
		var background:StyleBoxFlat=StyleBoxFlat.new()
		background.bg_color=Color(0.04,0.08,0.09,0.86)
		background.border_color=Color("746347")
		background.set_border_width_all(1)
		background.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background",background)
		var fill:StyleBoxFlat=StyleBoxFlat.new()
		fill.bg_color=Color("9c6653") if bar==hp_bar else Color("6a886e")
		fill.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("fill",fill)
		bar.add_theme_font_size_override("font_size",16)
		bar.custom_minimum_size.y=22
	add_child(controls_label)
	for control:Control in [attack_btn, interact_btn, potion_btn]:
		control.visible = DisplayServer.is_touchscreen_available()
	# Desktop help spans the bottom safely; touch devices retain action space.
	controls_label.size.x = 1150 if not DisplayServer.is_touchscreen_available() else 900
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: localize())
	localize()

	update_bars()

func localize() -> void:
	attack_btn.text = LocalizationManager.get_string("ui.attack")
	interact_btn.text = LocalizationManager.get_string("ui.interact") + " (E)"
	potion_btn.text = LocalizationManager.get_string("ui.potion") + " (Q)"
	inventory_btn.text = LocalizationManager.get_string("ui.inventory")
	town_btn.text = LocalizationManager.get_string("ui.settlement")
	alchemy_btn.text = LocalizationManager.get_string("ui.alchemy")
	council_btn.text = LocalizationManager.get_string("hud.council")
	codex_btn.text = LocalizationManager.get_string("hud.codex")
	for entry:Array in [[inventory_btn,"I"],[town_btn,"B"],[alchemy_btn,"C"],[council_btn,"R"],[codex_btn,"K"]]:
		var button:Button=entry[0]
		button.tooltip_text=button.text+" ("+str(entry[1])+")"
	refresh_help()
	refresh_quest_tracker()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).keycode == KEY_F1:
		expanded_help = not expanded_help
		refresh_help()
		get_viewport().set_input_as_handled()

func refresh_help() -> void:
	controls_label.text = LocalizationManager.get_string("ui.controls") if expanded_help else LocalizationManager.get_string("ui.help_compact")
	controls_label.offset_right=1175 if expanded_help else 215
	controls_label.offset_top = -110 if expanded_help else -65
	controls_label.offset_bottom = -20
	objective_label.size.y = 218 if expanded_help else 74
	if expanded_help:
		objective_label.text = tutorial_text
	else:
		objective_label.text = ""
		var pending_prefix:String=LocalizationManager.get_string("tutorial.pending")
		for line:String in tutorial_text.split("\n"):
			if line.begins_with(pending_prefix):
				objective_label.text = line
				break
	objective_label.visible = not objective_label.text.is_empty()

func _process(delta: float) -> void:
	target_timer = maxf(0, target_timer - delta)
	if target_health: target_health.visible = target_timer > 0
	hit_flash = maxf(0, hit_flash - delta)
	crosshair.color = Color("e6b875") if hit_flash > 0 else Color(1, 1, 1, 0.75)
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0:
			notification_label.text = ""
	tracker_timer -= delta
	if tracker_timer <= 0:
		tracker_timer = 0.35
		refresh_quest_tracker()

func refresh_quest_tracker() -> void:
	if not is_instance_valid(quest_panel):
		return
	var quest: Dictionary = CampaignSystem.tracked_objective()
	if quest.is_empty():
		quest_panel.hide()
		compass.active = false
		return
	quest_label.text = CampaignSystem.tracked_objective_text()
	var location: Dictionary = CampaignSystem.objective_location(quest)
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if location.is_empty() or players.is_empty():
		quest_distance.text = LocalizationManager.get_string("objective.no_position")
		compass.active = false
	else:
		var actor: Node3D = players[0] as Node3D
		var target: Vector3 = Vector3(_coordinate(location.get("x", 0.0)), 0.0, _coordinate(location.get("z", 0.0)))
		var distance: float = actor.global_position.distance_to(target)
		quest_distance.text = LocalizationManager.get_string("objective.distance", {"meters": int(distance)})
		compass.target = target
		compass.active = true
	quest_panel.show()

func spawn_damage_number(amount: float, world_position: Vector3, max_hp: float) -> void:
	if not SettingsManager.damage_numbers or amount <= 0.0:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or camera.is_position_behind(world_position):
		return
	var screen: Vector2 = camera.unproject_position(world_position)
	var heavy: bool = max_hp > 0.0 and amount >= max_hp * 0.25
	var popup: Label = Label.new()
	popup.text = "−" + str(roundi(amount))
	popup.position = screen - Vector2(44, 30)
	popup.size = Vector2(88, 34)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_font_size_override("font_size", 28 if heavy else 23)
	popup.add_theme_color_override("font_color", Color("C9A227") if heavy else Color("E8DCC3"))
	popup.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	popup.add_theme_constant_override("shadow_offset_x", 2)
	popup.add_theme_constant_override("shadow_offset_y", 2)
	add_child(popup)
	var tween: Tween = create_tween().set_parallel(true)
	@warning_ignore("return_value_discarded")
	var rise: PropertyTweener = tween.tween_property(popup, "position", popup.position + Vector2(randf_range(-14.0, 14.0), -62.0), 0.7)
	rise = rise.set_ease(Tween.EASE_OUT)
	rise = rise.set_trans(Tween.TRANS_CUBIC)
	@warning_ignore("return_value_discarded")
	var fade: PropertyTweener = tween.tween_property(popup, "modulate:a", 0.0, 0.7)
	fade = fade.set_ease(Tween.EASE_IN)
	fade = fade.set_trans(Tween.TRANS_QUAD)
	@warning_ignore("return_value_discarded")
	tween.finished.connect(popup.queue_free)

func _coordinate(value: Variant) -> float:
	if value is int or value is float:
		# Campaign objective coordinates are validated numeric catalog fields.
		@warning_ignore("unsafe_call_argument")
		return float(value)
	return 0.0

func update_bars() -> void:
	if hp_bar:
		hp_bar.value = GameState.player_hp
		hp_bar.max_value = GameState.max_hp
	if stamina_bar:
		stamina_bar.value = GameState.player_stamina
		stamina_bar.max_value = GameState.max_stamina

func _on_hp_changed(current: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.value = current
		hp_bar.max_value = max_v

func _on_stamina_changed(current: float, max_v: float) -> void:
	if stamina_bar:
		stamina_bar.value = current
		stamina_bar.max_value = max_v

func _on_notification_posted(text: String, is_warning: bool) -> void:
	if notification_label:
		notification_label.text = text
		if is_warning:
			notification_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			notification_label.add_theme_color_override("font_color", Color(1, 1, 1))
		notification_timer = 3.0

func controlled_player()->PlayerView:
	return get_tree().get_first_node_in_group("player") as PlayerView
