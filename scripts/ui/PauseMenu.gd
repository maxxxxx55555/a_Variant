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
	EventBus.language_changed.connect(func(_lang): localize())
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
	localize()
	var slot_choice := OptionButton.new()
	for index in 5: slot_choice.add_item(LocalizationManager.get_string("ui.slot") + " " + str(index + 1))
	slot_choice.selected = SaveSystem.selected_slot
	slot_choice.item_selected.connect(func(index): SaveSystem.selected_slot = index)
	$MarginContainer/VBoxContainer.add_child(slot_choice)
	if CampaignSystem.active:
		var menu_button := Button.new()
		menu_button.text = LocalizationManager.get_string("ui.to_menu")
		$MarginContainer/VBoxContainer.add_child(menu_button)
		menu_button.pressed.connect(func():
			_on_save(true)
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
		)
		if CampaignSystem.iron_mode:
			slot_choice.disabled = true
			load_btn.disabled = true

func localize() -> void:
	resume_btn.text = LocalizationManager.get_string("ui.respawn" if GameState.player_hp <= 0 else "ui.resume")
	save_btn.text = LocalizationManager.get_string("ui.save")
	load_btn.text = LocalizationManager.get_string("ui.load")
	settings_btn.text = LocalizationManager.get_string("ui.settings")
	exit_btn.text = LocalizationManager.get_string("ui.exit")
	var labels := {"LangLabel": "ui.language", "MasterLabel": "ui.volume_master", "MusicLabel": "ui.volume_music", "SFXLabel": "ui.volume_sfx", "UILabel": "ui.volume_ui", "BobbingCheck": "ui.camera_bobbing", "ShakeCheck": "ui.camera_shake"}
	for node_name in labels:
		settings_panel.get_node(node_name).text = LocalizationManager.get_string(labels[node_name])

func init_settings_ui() -> void:
	lang_option.clear()
	lang_option.add_item("Русский", 0)
	lang_option.add_item("English", 1)
	lang_option.selected = 0 if SettingsManager.language == "ru" else 1

	master_slider.set_value_no_signal(SettingsManager.master_volume)
	music_slider.set_value_no_signal(SettingsManager.music_volume)
	sfx_slider.set_value_no_signal(SettingsManager.sfx_volume)
	ui_slider.set_value_no_signal(SettingsManager.ui_volume)
	bobbing_check.set_pressed_no_signal(SettingsManager.camera_bobbing)
	shake_check.set_pressed_no_signal(SettingsManager.camera_shake)

func _on_resume() -> void:
	SettingsManager.save_settings()
	if GameState.player_hp <= 0:
		get_tree().current_scene.restart_run()
		return
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().current_scene._sync_menu_state()

func _on_save(autosave: bool = false) -> void:
	if GameState.player_hp <= 0:
		return
	var world_node = get_tree().current_scene
	var world_data = {}
	if world_node and world_node.has_method("get_world_state"):
		world_data = world_node.get_world_state()

	var state_data = {
		"hp": GameState.player_hp,
		"stamina": GameState.player_stamina,
		"inventory": GameState.inventory,
		"equipment": GameState.equipment,
		"world": world_data,
		"simulation": capture_simulation()
	}
	SaveSystem.save_game(state_data, autosave)

func _on_load() -> void:
	if CampaignSystem.active and CampaignSystem.iron_mode:
		return
	var loaded = SaveSystem.load_game()
	if not loaded.is_empty():
		GameState.player_hp = loaded.get("hp", 100.0)
		GameState.player_stamina = loaded.get("stamina", 100.0)
		GameState.restore_items(loaded.get("inventory",[]),loaded.get("equipment",{}))
		GameState.clamp_values()
		GameState.recalculate_stats()
		restore_simulation(loaded.get("simulation", {}))

		var world_node = get_tree().current_scene
		if world_node and world_node.has_method("load_world_state") and loaded.has("world"):
			world_node.load_world_state(loaded["world"])

		EventBus.inventory_updated.emit()
		EventBus.equipment_updated.emit()
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.max_hp)
		EventBus.player_stamina_changed.emit(GameState.player_stamina, GameState.max_stamina)
		save_btn.disabled = false
		localize()
		_on_resume()
	else:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.save_error"), true)

func _on_toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	$MarginContainer/VBoxContainer.visible = not settings_panel.visible
	if settings_panel.visible:
		init_settings_ui()
		var back_button := settings_panel.get_node_or_null("BackButton")
		if not back_button:
			back_button = Button.new()
			back_button.name = "BackButton"
			settings_panel.add_child(back_button)
			back_button.pressed.connect(_on_toggle_settings)
		back_button.text = LocalizationManager.get_string("ui.resume")
	else:
		SettingsManager.save_settings()

func _on_lang_selected(idx: int) -> void:
	var lang = "ru" if idx == 0 else "en"
	SettingsManager.language = lang
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_exit() -> void:
	SettingsManager.save_settings()
	if CampaignSystem.active: _on_save(true)
	get_tree().quit()

func capture_simulation() -> Dictionary:
	return {
		"day": TimeSystem.current_day, "week": TimeSystem.current_week,
		"season": TimeSystem.current_season_idx, "seconds": TimeSystem.game_time_seconds,
		"population": PopulationSystem.total_population, "sick": PopulationSystem.sick_citizens,
		"jobs": PopulationSystem.jobs.duplicate(), "happiness": PopulationSystem.happiness,
		"health": PopulationSystem.health, "crisis_days": PopulationSystem.low_happiness_days,
		"stockpiles": EconomySystem.stockpiles.duplicate(), "laws": SettlementSystem.current_laws.duplicate(),
		"army": ArmySystem.squads.duplicate(true), "army_next_id": ArmySystem.next_squad_id,
		"factions": FactionSystem.factions.duplicate(true), "treaties": DiplomacySystem.active_treaties.duplicate(true),
		"treaty_expiry": DiplomacySystem.treaty_expiry.duplicate(), "quests_active": QuestSystem.active_quests.duplicate(),
		"quests_completed": QuestSystem.completed_quests.duplicate(), "weather": WeatherSystem.current_weather,
		"strength_buff": GameState.strength_buff_timer,
		"campaign": CampaignSystem.capture_state(), "buildings": WorkshopSystem.levels.duplicate(),
		"timed_effects": GameState.timed_effects.duplicate(true), "poison": GameState.poison_timer
	}

func restore_simulation(data: Dictionary) -> void:
	TimeSystem.current_day = int(data.get("day", 1))
	TimeSystem.current_week = int(data.get("week", 1))
	TimeSystem.current_season_idx = int(data.get("season", 0)) % 4
	TimeSystem.game_time_seconds = float(data.get("seconds", 0))
	PopulationSystem.total_population = int(data.get("population", 25))
	PopulationSystem.sick_citizens = int(data.get("sick", 0))
	PopulationSystem.jobs = data.get("jobs", {"farmers": 8, "woodcutters": 5, "miners": 3, "guards": 2, "blacksmiths": 2})
	ArmySystem.squads = data.get("army", [])
	ArmySystem.selected_squad_index = clampi(ArmySystem.selected_squad_index,0,maxi(0,ArmySystem.squads.size()-1))
	ArmySystem.next_squad_id = int(data.get("army_next_id", 1))
	PopulationSystem.happiness = float(data.get("happiness", 70))
	PopulationSystem.health = float(data.get("health", 85))
	PopulationSystem.low_happiness_days = int(data.get("crisis_days", 0))
	PopulationSystem.reconcile_workers()
	EconomySystem.stockpiles = data.get("stockpiles", {"food": 150.0, "wood": 80.0, "ore": 40.0, "stone": 50.0, "gold": 200.0})
	SettlementSystem.current_laws = data.get("laws", {"taxes": "normal", "rations": "full", "conscription": "voluntary"})
	FactionSystem.factions = data.get("factions", FactionSystem.factions)
	DiplomacySystem.active_treaties = data.get("treaties", {})
	DiplomacySystem.treaty_expiry = data.get("treaty_expiry", {})
	QuestSystem.active_quests = data.get("quests_active", ["main_quest_01", "side_quest_clear_camp", "companion_quest_01"])
	QuestSystem.completed_quests = data.get("quests_completed", [])
	WeatherSystem.set_weather(int(data.get("weather", 0)))
	GameState.strength_buff_timer = data.get("strength_buff", 0.0)
	GameState.timed_effects = data.get("timed_effects", {})
	GameState.poison_timer = data.get("poison", 0.0)
	GameState.recalculate_stats()
	CampaignSystem.restore_state(data.get("campaign", {}))
	# Early profiles may omit factions introduced with the full campaign.
	if CampaignSystem.active:
		for faction in CampaignSystem.definition.factions:
			if not FactionSystem.factions.has(faction.id):
				FactionSystem.factions[faction.id] = {"res_path":"res://data/factions/"+faction.id+".tres","relationship":faction.relationship,"threat":0.0,"escalation_level":0}
	WorkshopSystem.levels = data.get("buildings", {})
	ArmySystem.roster_changed.emit()
