extends Control

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
var objective_label: Label

func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.notification_posted.connect(_on_notification_posted)
	objective_label = Label.new()
	objective_label.position = Vector2(24, 140)
	objective_label.size = Vector2(580, 300)
	objective_label.add_theme_font_size_override("font_size", 21)
	objective_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	objective_label.add_theme_constant_override("shadow_offset_x", 2)
	objective_label.add_theme_constant_override("shadow_offset_y", 2)
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_label)
	EventBus.tutorial_updated.connect(func(text, done):
		objective_label.text = text
		objective_label.modulate = Color(0.65, 1.0, 0.7) if done else Color.WHITE
	)

	if attack_btn: attack_btn.pressed.connect(func(): get_tree().current_scene.player.perform_attack())
	if interact_btn: interact_btn.pressed.connect(func(): get_tree().current_scene.player.interact())
	if potion_btn: potion_btn.pressed.connect(func(): get_tree().current_scene.player.use_quick_potion())
	if inventory_btn: inventory_btn.pressed.connect(func(): get_tree().current_scene.toggle_inventory())
	if town_btn: town_btn.pressed.connect(func():
		var scene = get_tree().current_scene
		if scene and scene.has_method("toggle_settlement"):
			scene.toggle_settlement()
	)
	alchemy_btn = Button.new()
	alchemy_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	alchemy_btn.position = Vector2(-520, 30)
	alchemy_btn.size = Vector2(165, 60)
	$MobileControls.add_child(alchemy_btn)
	alchemy_btn.pressed.connect(func(): get_tree().current_scene.toggle_alchemy())
	council_btn = Button.new()
	$MobileControls.add_child(council_btn)
	council_btn.pressed.connect(func(): get_tree().current_scene.toggle_strategy(0))
	var top_buttons := [inventory_btn, town_btn, alchemy_btn, council_btn]
	for i in range(top_buttons.size()):
		var button: Button = top_buttons[i]
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		button.offset_left = -230 - i * 220
		button.offset_right = -30 - i * 220
		button.offset_top = 20
		button.offset_bottom = 80
		button.add_theme_font_size_override("font_size", 20)
	controls_label = Label.new()
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls_label.position = Vector2(25, -110)
	controls_label.size = Vector2(900, 90)
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.add_theme_font_size_override("font_size", 18)
	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls_label)
	for control in [attack_btn, interact_btn, potion_btn]:
		control.visible = DisplayServer.is_touchscreen_available()
	# Desktop help spans the bottom safely; touch devices retain action space.
	controls_label.size.x = 1150 if not DisplayServer.is_touchscreen_available() else 900
	EventBus.language_changed.connect(func(_lang): localize())
	localize()

	update_bars()

func localize() -> void:
	attack_btn.text = LocalizationManager.get_string("ui.attack")
	interact_btn.text = LocalizationManager.get_string("ui.interact") + " (E)"
	potion_btn.text = LocalizationManager.get_string("ui.potion") + " (Q)"
	inventory_btn.text = LocalizationManager.get_string("ui.inventory") + " (I)"
	town_btn.text = LocalizationManager.get_string("ui.settlement") + " (B)"
	alchemy_btn.text = LocalizationManager.get_string("ui.alchemy") + " (C)"
	council_btn.text = LocalizationManager.get_string("ui.strategy") + " (R)"
	controls_label.text = LocalizationManager.get_string("ui.controls")

func _process(delta: float) -> void:
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0:
			notification_label.text = ""

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
