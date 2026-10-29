extends Control
const PlayerView=preload("res://scripts/characters/Player.gd")
const UITheme=preload("res://scripts/ui/MarchTheme.gd")

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
var target_health: Label
var hp_value: Label
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
	_build_scrims()
	_style_vitals()
	_build_target_readout()
	_build_objective()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.tutorial_updated.connect(func(text:Variant, done:Variant)->void:
		tutorial_text = text
		refresh_help()
		objective_label.modulate = Color(1, 1, 1, 0.72) if done else Color.WHITE
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
	alchemy_btn = _action_button("ui.alchemy")
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	alchemy_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_alchemy"))
	council_btn = _action_button("hud.council")
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	council_btn.pressed.connect(func()->void: get_tree().current_scene.call("toggle_strategy",0))
	_layout_action_strip()
	_build_controls_hint()
	# Desktop hides the touch action pads; touch devices keep a clear thumb zone.
	for control:Control in [attack_btn, interact_btn, potion_btn]:
		control.visible = DisplayServer.is_touchscreen_available()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: localize())
	localize()
	update_bars()

# Vitals read as a measuring instrument: numeral, then a hairline meter.
# Two soft corner veils keep type legible over sky, snow or firelight.
func _build_scrims() -> void:
	var top:TextureRect = _scrim(0.0, 820, 420)
	top.name = "TopScrim"
	add_child(top)
	move_child(top, 0)
	var bottom:TextureRect = _scrim(1.0, 780, 380)
	bottom.name = "BottomScrim"
	add_child(bottom)
	move_child(bottom, 1)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.offset_left = 0
	bottom.offset_right = 780
	bottom.offset_top = -380
	bottom.offset_bottom = 0

func _scrim(anchor_y: float, width: int, height: int) -> TextureRect:
	var gradient:Gradient = Gradient.new()
	# The veil must reach zero well inside its rectangle, otherwise the edge cuts.
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7])
	gradient.colors = PackedColorArray([
		Color(0.02, 0.05, 0.07, 0.5),
		Color(0.02, 0.05, 0.07, 0.22),
		Color(0.02, 0.05, 0.07, 0.0),
	])
	var texture:GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.0, anchor_y)
	texture.fill_to = Vector2(1.0, 1.0 - anchor_y)
	var rect:TextureRect = TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(width, height)
	return rect

func _style_vitals() -> void:
	var container:VBoxContainer = $VBoxContainer
	container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	container.offset_left = 56
	container.offset_top = -142
	container.offset_right = 356
	container.offset_bottom = -52
	container.add_theme_constant_override("separation", 6)
	hp_value = Label.new()
	hp_value.name = "HPValue"
	hp_value.add_theme_font_override("font", UITheme.body_font(500))
	hp_value.add_theme_font_size_override("font_size", 24)
	hp_value.add_theme_color_override("font_color", UITheme.CHALK)

	container.add_child(hp_value)
	container.move_child(hp_value, 0)
	for bar:ProgressBar in [hp_bar, stamina_bar]:
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(240, 5 if bar == hp_bar else 3)
		var background:StyleBoxFlat = StyleBoxFlat.new()
		background.bg_color = Color(0, 0, 0, 0.42)
		background.set_corner_radius_all(0)
		bar.add_theme_stylebox_override("background", background)
		var fill:StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = UITheme.CLAY if bar == hp_bar else UITheme.SAGE
		fill.set_corner_radius_all(0)
		bar.add_theme_stylebox_override("fill", fill)
	# The stamina meter sits quieter than health.
	stamina_bar.modulate = Color(1, 1, 1, 0.72)

func _build_target_readout() -> void:
	target_health = Label.new()
	target_health.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	target_health.position = Vector2(-160, 190)
	target_health.size = Vector2(320, 48)
	target_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_health.add_theme_font_size_override("font_size", 22)
	target_health.add_theme_color_override("font_color", UITheme.BRASS)
	target_health.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	target_health.add_theme_constant_override("shadow_offset_x", 1)
	target_health.add_theme_constant_override("shadow_offset_y", 2)
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
	)

# The objective is set like a margin note: a brass rule and one line of text.
func _build_objective() -> void:
	objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.position = Vector2(56, 92)
	objective_label.size = Vector2(520, 74)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 21)
	objective_label.add_theme_color_override("font_color", UITheme.CHALK)

	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(objective_label)
	var tick:ColorRect = ColorRect.new()
	tick.name = "ObjectiveRule"
	tick.color = UITheme.BRASS
	tick.position = Vector2(56, 86)
	tick.size = Vector2(28, 2)
	tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tick)

func _action_button(key: String) -> Button:
	var button:Button = Button.new()
	button.text = LocalizationManager.get_string(key)
	button.set_meta("locale_key", key)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(UITheme.CHALK, 0.86))
	button.add_theme_color_override("font_hover_color", UITheme.BRASS)
	button.add_theme_color_override("font_pressed_color", UITheme.BRASS)
	for state:String in ["normal","disabled"]:
		button.add_theme_stylebox_override(state, _flat_box(Color.TRANSPARENT, 0))
	button.add_theme_stylebox_override("hover", _flat_box(Color(0, 0, 0, 0.25), 0))
	button.add_theme_stylebox_override("pressed", _flat_box(Color(0, 0, 0, 0.35), 0))
	var focus:StyleBoxFlat = _flat_box(Color.TRANSPARENT, 2)
	focus.border_color = UITheme.BRASS
	button.add_theme_stylebox_override("focus", focus)
	$MobileControls.add_child(button)
	return button

func _flat_box(color: Color, border: int) -> StyleBoxFlat:
	var box:StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	if border > 0:
		box.border_color = UITheme.BRASS
		box.set_border_width_all(border)
	return box

# Top-right actions stay text-only so the world keeps the frame.
func _layout_action_strip() -> void:
	for button:Button in [inventory_btn, town_btn, alchemy_btn, council_btn]:
		for state:String in ["normal","disabled"]:
			button.add_theme_stylebox_override(state, _flat_box(Color.TRANSPARENT, 0))
		button.add_theme_stylebox_override("hover", _flat_box(Color(0, 0, 0, 0.25), 0))
		button.add_theme_stylebox_override("pressed", _flat_box(Color(0, 0, 0, 0.35), 0))
		var focus:StyleBoxFlat = _flat_box(Color.TRANSPARENT, 2)
		focus.border_color = UITheme.BRASS
		button.add_theme_stylebox_override("focus", focus)
		button.add_theme_color_override("font_color", Color(UITheme.CHALK, 0.86))
		button.add_theme_color_override("font_hover_color", UITheme.BRASS)
		button.add_theme_color_override("font_pressed_color", UITheme.BRASS)
		button.add_theme_font_size_override("font_size", 20)
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	var order:Array = [inventory_btn, town_btn, alchemy_btn, council_btn]
	var cursor:int = -48
	for index:int in range(order.size()):
		var button:Button = order[index]
		var measured:float = button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var width:int = maxi(112, int(measured) + 34)
		button.offset_left = cursor - width
		button.offset_right = cursor
		button.offset_top = 34
		button.offset_bottom = 34 + 46
		cursor -= width + 10

func _build_controls_hint() -> void:
	controls_label = Label.new()
	controls_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls_label.position = Vector2(56, -46)
	controls_label.size = Vector2(760, 32)
	controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label.add_theme_font_size_override("font_size", 18)
	controls_label.add_theme_color_override("font_color", Color(UITheme.MIST, 0.9))

	controls_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(controls_label)

func localize() -> void:
	attack_btn.text = LocalizationManager.get_string("ui.attack")
	interact_btn.text = LocalizationManager.get_string("ui.interact") + " (E)"
	potion_btn.text = LocalizationManager.get_string("ui.potion") + " (Q)"
	inventory_btn.text = LocalizationManager.get_string("ui.inventory")
	town_btn.text = LocalizationManager.get_string("ui.settlement")
	alchemy_btn.text = LocalizationManager.get_string("ui.alchemy")
	council_btn.text = LocalizationManager.get_string("hud.council")
	for entry:Array in [[inventory_btn,"I"],[town_btn,"B"],[alchemy_btn,"C"],[council_btn,"R"]]:
		var button:Button=entry[0]
		button.tooltip_text=button.text+" ("+str(entry[1])+")"
	refresh_help()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).keycode == KEY_F1:
		expanded_help = not expanded_help
		refresh_help()
		get_viewport().set_input_as_handled()

func refresh_help() -> void:
	controls_label.text = LocalizationManager.get_string("ui.controls") if expanded_help else LocalizationManager.get_string("ui.help_compact")
	controls_label.offset_right = 1175 if expanded_help else 215
	controls_label.offset_top = -168 if expanded_help else -46
	controls_label.offset_bottom = -20
	objective_label.size.y = 218 if expanded_help else 74
	if expanded_help:
		objective_label.text = tutorial_text
	else:
		objective_label.text = ""
		for line:String in tutorial_text.split("\n"):
			if "□" in line:
				objective_label.text = line.replace("□", "→")
				break
	objective_label.visible = not objective_label.text.is_empty()
	var rule:ColorRect = get_node_or_null("ObjectiveRule") as ColorRect
	if rule: rule.visible = objective_label.visible

func _process(delta: float) -> void:
	target_timer = maxf(0, target_timer - delta)
	if target_health: target_health.visible = target_timer > 0
	hit_flash = maxf(0, hit_flash - delta)
	crosshair.color = UITheme.BRASS if hit_flash > 0 else Color(1, 1, 1, 0.7)
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
	if hp_value:
		hp_value.text = "%d" % roundi(GameState.player_hp)

func _on_hp_changed(current: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.value = current
		hp_bar.max_value = max_v
	if hp_value:
		hp_value.text = "%d" % roundi(current)

func _on_stamina_changed(current: float, max_v: float) -> void:
	if stamina_bar:
		stamina_bar.value = current
		stamina_bar.max_value = max_v

func _on_notification_posted(text: String, is_warning: bool) -> void:
	if notification_label:
		notification_label.text = text
		notification_label.add_theme_color_override("font_color", UITheme.CLAY if is_warning else UITheme.CHALK)
		notification_timer = 3.0

func controlled_player()->PlayerView:
	return get_tree().get_first_node_in_group("player") as PlayerView
