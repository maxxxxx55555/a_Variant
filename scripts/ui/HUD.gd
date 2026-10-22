extends Control

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var stamina_bar: ProgressBar = $VBoxContainer/StaminaBar
@onready var notification_label: Label = $NotificationLabel
@onready var crosshair: ColorRect = $Crosshair

var notification_timer: float = 0.0

func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_hp_changed)
	EventBus.player_stamina_changed.connect(_on_stamina_changed)
	EventBus.notification_posted.connect(_on_notification_posted)
	update_bars()

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
