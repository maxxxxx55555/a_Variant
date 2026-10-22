extends Control

@onready var resume_btn: Button = $MarginContainer/VBoxContainer/ResumeBtn
@onready var save_btn: Button = $MarginContainer/VBoxContainer/SaveBtn
@onready var load_btn: Button = $MarginContainer/VBoxContainer/LoadBtn
@onready var settings_btn: Button = $MarginContainer/VBoxContainer/SettingsBtn
@onready var exit_btn: Button = $MarginContainer/VBoxContainer/ExitBtn

@onready var settings_panel: VBoxContainer = $MarginContainer/SettingsPanel
@onready var lang_option: OptionButton = $MarginContainer/SettingsPanel/LangOption
@onready var master_slider: HSlider = $MarginContainer/SettingsPanel/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/SettingsPanel/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/SettingsPanel/SFXSlider
@onready var ui_slider: HSlider = $MarginContainer/SettingsPanel/UISlider
@onready var bobbing_check: CheckBox = $MarginContainer/SettingsPanel/BobbingCheck
@onready var shake_check: CheckBox = $MarginContainer/SettingsPanel/ShakeCheck

func _ready() -> void:
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	settings_btn.pressed.connect(_on_toggle_settings)
	exit_btn.pressed.connect(_on_exit)

	lang_option.item_selected.connect(_on_lang_selected)
	master_slider.value_changed.connect(func(v): SettingsManager.master_volume = v; SettingsManager.apply_settings())
	music_slider.value_changed.connect(func(v): SettingsManager.music_volume = v; SettingsManager.apply_settings())
	sfx_slider.value_changed.connect(func(v): SettingsManager.sfx_volume = v; SettingsManager.apply_settings())
	ui_slider.value_changed.connect(func(v): SettingsManager.ui_volume = v; SettingsManager.apply_settings())
	bobbing_check.toggled.connect(func(v): SettingsManager.camera_bobbing = v)
	shake_check.toggled.connect(func(v): SettingsManager.camera_shake = v)

	init_settings_ui()

func init_settings_ui() -> void:
	lang_option.clear()
	lang_option.add_item("Русский", 0)
	lang_option.add_item("English", 1)
	lang_option.selected = 0 if SettingsManager.language == "ru" else 1

	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	ui_slider.value = SettingsManager.ui_volume
	bobbing_check.button_pressed = SettingsManager.camera_bobbing
	shake_check.button_pressed = SettingsManager.camera_shake

func _on_resume() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_save() -> void:
	var world_node = get_tree().current_scene
	var world_data = {}
	if world_node and world_node.has_method("get_world_state"):
		world_data = world_node.get_world_state()

	var state_data = {
		"hp": GameState.player_hp,
		"stamina": GameState.player_stamina,
		"inventory": GameState.inventory,
		"equipment": GameState.equipment,
		"world": world_data
	}
	SaveSystem.save_game(state_data)

func _on_load() -> void:
	var loaded = SaveSystem.load_game()
	if not loaded.is_empty():
		GameState.player_hp = loaded.get("hp", 100.0)
		GameState.player_stamina = loaded.get("stamina", 100.0)
		GameState.inventory = loaded.get("inventory", [])
		GameState.equipment = loaded.get("equipment", {})
		GameState.recalculate_stats()

		var world_node = get_tree().current_scene
		if world_node and world_node.has_method("load_world_state") and loaded.has("world"):
			world_node.load_world_state(loaded["world"])

		EventBus.inventory_updated.emit()
		EventBus.equipment_updated.emit()
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.max_hp)
		_on_resume()

func _on_toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible

func _on_lang_selected(idx: int) -> void:
	var lang = "ru" if idx == 0 else "en"
	SettingsManager.language = lang
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_exit() -> void:
	get_tree().quit()
