extends Control

@onready var resume_btn: Button = $MarginContainer/VBoxContainer/ResumeBtn
@onready var save_btn: Button = $MarginContainer/VBoxContainer/SaveBtn
@onready var load_btn: Button = $MarginContainer/VBoxContainer/LoadBtn
@onready var settings_btn: Button = $MarginContainer/VBoxContainer/SettingsBtn
@onready var exit_btn: Button = $MarginContainer/VBoxContainer/ExitBtn

@onready var settings_panel: VBoxContainer = $MarginContainer/SettingsScroll/SettingsPanel
@onready var lang_option: OptionButton = $MarginContainer/SettingsScroll/SettingsPanel/LangOption
@onready var master_slider: HSlider = $MarginContainer/SettingsScroll/SettingsPanel/MasterSlider
@onready var music_slider: HSlider = $MarginContainer/SettingsScroll/SettingsPanel/MusicSlider
@onready var sfx_slider: HSlider = $MarginContainer/SettingsScroll/SettingsPanel/SFXSlider
@onready var ui_slider: HSlider = $MarginContainer/SettingsScroll/SettingsPanel/UISlider
@onready var bobbing_check: CheckBox = $MarginContainer/SettingsScroll/SettingsPanel/BobbingCheck
@onready var shake_check: CheckBox = $MarginContainer/SettingsScroll/SettingsPanel/ShakeCheck

var settings_back:Button
var settings_header:HBoxContainer
var settings_backdrop:Panel

func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: localize())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	resume_btn.pressed.connect(_on_resume)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	save_btn.pressed.connect(_on_save)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	load_btn.pressed.connect(_on_load)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	settings_btn.pressed.connect(_on_toggle_settings)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	exit_btn.pressed.connect(_on_exit)

	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	lang_option.item_selected.connect(_on_lang_selected)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	master_slider.value_changed.connect(func(v:Variant)->void: SettingsManager.master_volume = v; SettingsManager.apply_settings())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	music_slider.value_changed.connect(func(v:Variant)->void: SettingsManager.music_volume = v; SettingsManager.apply_settings())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	sfx_slider.value_changed.connect(func(v:Variant)->void: SettingsManager.sfx_volume = v; SettingsManager.apply_settings())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	ui_slider.value_changed.connect(func(v:Variant)->void: SettingsManager.ui_volume = v; SettingsManager.apply_settings())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	bobbing_check.toggled.connect(func(v:Variant)->void: SettingsManager.camera_bobbing = v)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	shake_check.toggled.connect(func(v:Variant)->void: SettingsManager.camera_shake = v)

	var motion:CheckBox=CheckBox.new()
	motion.name="ReducedMotionCheck"
	motion.button_pressed=SettingsManager.reduced_motion
	settings_panel.add_child(motion)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	motion.toggled.connect(func(enabled:Variant)->void:SettingsManager.reduced_motion=enabled)
	var sensitivity_label:Label=Label.new()
	sensitivity_label.name="SensitivityLabel"
	settings_panel.add_child(sensitivity_label)
	var sensitivity:HSlider=HSlider.new()
	sensitivity.name="MouseSensitivity"
	sensitivity.min_value=0.0005
	sensitivity.max_value=0.01
	sensitivity.step=0.0001
	sensitivity.value=SettingsManager.mouse_sensitivity
	settings_panel.add_child(sensitivity)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	sensitivity.value_changed.connect(func(value:Variant)->void:SettingsManager.mouse_sensitivity=value)
	var quality_label:Label=Label.new()
	quality_label.name="QualityLabel"
	settings_panel.add_child(quality_label)
	var quality:OptionButton=OptionButton.new()
	quality.name="MSAAQuality"
	for level:String in ["", "2×", "4×", "8×"]:quality.add_item(level)
	quality.selected=SettingsManager.msaa_quality
	settings_panel.add_child(quality)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	quality.item_selected.connect(func(index:Variant)->void:SettingsManager.msaa_quality=index;SettingsManager.apply_settings())
	build_settings_frame()
	init_settings_ui()
	localize()
	var slot_choice:OptionButton= OptionButton.new()
	slot_choice.name="SaveSlotChoice"
	for index:int in 5: slot_choice.add_item(LocalizationManager.get_string("ui.slot") + " " + str(index + 1))
	slot_choice.selected = SaveSystem.selected_slot
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	slot_choice.item_selected.connect(func(index:Variant)->void: SaveSystem.selected_slot = index)
	$MarginContainer/VBoxContainer.add_child(slot_choice)
	if CampaignSystem.active:
		var menu_button:Button= Button.new()
		menu_button.name="ToMenuButton"
		menu_button.text = LocalizationManager.get_string("ui.to_menu")
		$MarginContainer/VBoxContainer.add_child(menu_button)
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		menu_button.pressed.connect(_return_to_menu)
		if CampaignSystem.iron_mode:
			slot_choice.disabled = true
			load_btn.disabled = true
			slot_choice.tooltip_text=LocalizationManager.get_string("ui.iron_no_load")
			load_btn.tooltip_text=slot_choice.tooltip_text

func localize() -> void:
	var terminal_iron:bool=CampaignSystem.active and CampaignSystem.iron_mode and (CampaignSystem.iron_dead or GameState.player_hp<=0)
	resume_btn.text=LocalizationManager.get_string("ui.iron_end_label" if terminal_iron else "ui.respawn" if GameState.player_hp<=0 else "ui.resume")
	resume_btn.disabled=terminal_iron
	resume_btn.tooltip_text=LocalizationManager.get_string("ui.iron_dead") if terminal_iron else ""
	save_btn.tooltip_text=LocalizationManager.get_string("ui.iron_dead" if terminal_iron else "ui.save_after_respawn") if GameState.player_hp<=0 else ""
	if CampaignSystem.active and CampaignSystem.iron_mode:
		load_btn.tooltip_text=LocalizationManager.get_string("ui.iron_no_load")
		var iron_slots:OptionButton=find_child("SaveSlotChoice",true,false)
		if iron_slots:iron_slots.tooltip_text=load_btn.tooltip_text
	save_btn.text = LocalizationManager.get_string("ui.save")
	load_btn.text = LocalizationManager.get_string("ui.load")
	settings_btn.text = LocalizationManager.get_string("ui.settings")
	exit_btn.text = LocalizationManager.get_string("ui.exit")
	var labels:Dictionary[String,String]= {"LangLabel": "ui.language", "MasterLabel": "ui.volume_master", "MusicLabel": "ui.volume_music", "SFXLabel": "ui.volume_sfx", "UILabel": "ui.volume_ui", "BobbingCheck": "ui.camera_bobbing", "ShakeCheck": "ui.camera_shake", "ReducedMotionCheck":"ui.reduced_motion", "SensitivityLabel":"ui.mouse_sensitivity", "QualityLabel":"ui.msaa_quality"}
	for node_name:String in labels:
		settings_panel.get_node(node_name).set("text",LocalizationManager.get_string(labels[node_name]))

	(settings_panel.get_node("MouseSensitivity") as HSlider).tooltip_text=LocalizationManager.get_string("ui.mouse_hint")
	(settings_panel.get_node("MSAAQuality") as OptionButton).tooltip_text=LocalizationManager.get_string("ui.msaa_hint")
	(settings_panel.get_node("MSAAQuality") as OptionButton).set_item_text(0,LocalizationManager.get_string("ui.msaa_off"))
	if is_instance_valid(settings_back):
		settings_back.text=LocalizationManager.get_string("ui.close")
		(settings_header.get_child(0) as Label).text=LocalizationManager.get_string("ui.settings")
	var slots:OptionButton=find_child("SaveSlotChoice",true,false)
	if slots:
		for i:int in 5:slots.set_item_text(i,LocalizationManager.get_string("ui.slot")+" "+str(i+1))
	var to_menu:Button=find_child("ToMenuButton",true,false)
	if to_menu:to_menu.text=LocalizationManager.get_string("ui.to_menu")

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
	(settings_panel.get_node("MouseSensitivity") as HSlider).set_value_no_signal(SettingsManager.mouse_sensitivity)
	(settings_panel.get_node("MSAAQuality") as OptionButton).select(SettingsManager.msaa_quality)

func _on_resume() -> void:
	if CampaignSystem.active and CampaignSystem.iron_mode and (CampaignSystem.iron_dead or GameState.player_hp<=0):return
	SettingsManager.save_settings()
	if GameState.player_hp <= 0:
		# The active world implements this guarded scene lifecycle contract.
		@warning_ignore("return_value_discarded")
		get_tree().current_scene.call("restart_run")
		return
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# The active world implements this guarded scene lifecycle contract.
	@warning_ignore("return_value_discarded")
	get_tree().current_scene.call("_sync_menu_state")

func _on_save(autosave: bool = false) -> bool:
	if GameState.player_hp <= 0:
		return false
	var world_node:Node= get_tree().current_scene
	var world_data:Dictionary= {}
	if world_node and world_node.has_method("get_world_state"):
		world_data = world_node.call("get_world_state")

	var state_data:Dictionary= {
		"hp": GameState.player_hp,
		"stamina": GameState.player_stamina,
		"inventory": GameState.inventory,
		"equipment": GameState.equipment,
		"world": world_data,
		"simulation": capture_simulation()
	}
	return SaveSystem.save_game(state_data, autosave)

func _on_load() -> void:
	if CampaignSystem.active and CampaignSystem.iron_mode:
		return
	var loaded:Dictionary= SaveSystem.load_game()
	if not loaded.is_empty():
		GameState.player_hp = loaded.get("hp", 100.0)
		GameState.player_stamina = loaded.get("stamina", 100.0)
		var inventory:Array=loaded.get("inventory",[])
		var equipment:Dictionary=loaded.get("equipment",{})
		GameState.restore_items(inventory,equipment)
		GameState.clamp_values()
		GameState.recalculate_stats()
		var simulation:Dictionary=loaded.get("simulation",{})
		restore_simulation(simulation)

		var world_node:Node= get_tree().current_scene
		if world_node and world_node.has_method("load_world_state") and loaded.has("world"):
			# The active world implements this guarded scene lifecycle contract.
			@warning_ignore("return_value_discarded")
			world_node.call("load_world_state",loaded["world"])

		EventBus.inventory_updated.emit()
		EventBus.equipment_updated.emit()
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.max_hp)
		EventBus.player_stamina_changed.emit(GameState.player_stamina, GameState.max_stamina)
		save_btn.disabled = false
		localize()
		_on_resume()
	else:
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.save_error"), true)

func build_settings_frame() -> void:
	settings_backdrop=Panel.new()
	settings_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	settings_backdrop.add_theme_stylebox_override("panel",preload("res://scripts/ui/MarchTheme.gd").panel(Color("1c2932"),Color("61717a")))
	add_child(settings_backdrop);move_child(settings_backdrop,1)
	centered_frame(settings_backdrop,Rect2(-344,-488,688,928))
	settings_backdrop.hide()
	settings_header=HBoxContainer.new()
	settings_header.add_theme_constant_override("separation",24)
	add_child(settings_header)
	centered_frame(settings_header,Rect2(-320,-464,640,56))
	var heading:Label=Label.new()
	heading.add_theme_font_override("font",load("res://assets/fonts/Literata.ttf") as Font)
	heading.add_theme_font_size_override("font_size",32)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	settings_header.add_child(heading)
	settings_back=Button.new()
	settings_back.name="BackButton"
	settings_back.custom_minimum_size=Vector2(136,56)
	settings_header.add_child(settings_back)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	settings_back.pressed.connect(_on_toggle_settings)
	settings_header.hide()
	($MarginContainer/SettingsScroll as ScrollContainer).follow_focus=true
	settings_panel.add_theme_constant_override("separation",16)
func centered_frame(control:Control,rectangle:Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	control.offset_left=rectangle.position.x
	control.offset_top=rectangle.position.y
	control.offset_right=rectangle.end.x
	control.offset_bottom=rectangle.end.y
func _on_toggle_settings() -> void:
	settings_panel.visible=not settings_panel.visible
	($MarginContainer/SettingsScroll as ScrollContainer).visible=settings_panel.visible
	($MarginContainer/VBoxContainer as VBoxContainer).visible=not settings_panel.visible
	settings_backdrop.visible=settings_panel.visible
	settings_header.visible=settings_panel.visible
	centered_frame($MarginContainer as Control,Rect2(-320,-392,640,800) if settings_panel.visible else Rect2(-200,-250,400,500))
	if settings_panel.visible:
		init_settings_ui()
		lang_option.grab_focus()
	else:
		SettingsManager.save_settings()
		settings_btn.grab_focus()

func _on_lang_selected(idx: int) -> void:
	var lang:String= "ru" if idx == 0 else "en"
	SettingsManager.language = lang
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_exit() -> void:
	if MarchTransition.quitting:return
	SettingsManager.save_settings()
	if CampaignSystem.active and GameState.player_hp>0 and not _on_save(true):
		MarchTransition.confirm_unsaved(func()->Variant:return _on_save(true),MarchTransition.quit_game)
		return
	MarchTransition.quit_game()

func _return_to_menu() -> void:
	if MarchTransition.quitting:return
	SettingsManager.save_settings()
	if GameState.player_hp>0 and not _on_save(true):
		MarchTransition.confirm_unsaved(func()->Variant:return _on_save(true),func()->void:MarchTransition.go_to.call_deferred("res://scenes/ui/main_menu.tscn"))
		return
	MarchTransition.go_to.call_deferred("res://scenes/ui/main_menu.tscn")

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
	TimeSystem.current_day = data.get("day", 1)
	TimeSystem.current_week = data.get("week", 1)
	var season:int=data.get("season",0)
	TimeSystem.current_season_idx=season%4
	TimeSystem.game_time_seconds = data.get("seconds", 0)
	PopulationSystem.total_population = data.get("population", 25)
	PopulationSystem.sick_citizens = data.get("sick", 0)
	PopulationSystem.jobs = data.get("jobs", {"farmers": 8, "woodcutters": 5, "miners": 3, "guards": 2, "blacksmiths": 2})
	ArmySystem.squads = data.get("army", [])
	ArmySystem.selected_squad_index = clampi(ArmySystem.selected_squad_index,0,maxi(0,ArmySystem.squads.size()-1))
	ArmySystem.next_squad_id = data.get("army_next_id", 1)
	PopulationSystem.happiness = data.get("happiness", 70)
	PopulationSystem.health = data.get("health", 85)
	PopulationSystem.low_happiness_days = data.get("crisis_days", 0)
	PopulationSystem.reconcile_workers()
	EconomySystem.stockpiles = data.get("stockpiles", {"food": 150.0, "wood": 80.0, "ore": 40.0, "stone": 50.0, "gold": 200.0})
	SettlementSystem.current_laws = data.get("laws", {"taxes": "normal", "rations": "full", "conscription": "voluntary"})
	FactionSystem.factions = data.get("factions", FactionSystem.factions)
	DiplomacySystem.active_treaties = data.get("treaties", {})
	DiplomacySystem.treaty_expiry = data.get("treaty_expiry", {})
	QuestSystem.active_quests = data.get("quests_active", ["main_quest_01", "side_quest_clear_camp", "companion_quest_01"])
	QuestSystem.completed_quests = data.get("quests_completed", [])
	var weather:int=data.get("weather",0)
	WeatherSystem.set_weather(weather as WeatherSystem.WeatherType)
	GameState.strength_buff_timer = data.get("strength_buff", 0.0)
	GameState.timed_effects = data.get("timed_effects", {})
	GameState.poison_timer = data.get("poison", 0.0)
	GameState.recalculate_stats()
	var campaign:Dictionary=data.get("campaign",{})
	CampaignSystem.restore_state(campaign)
	# Early profiles may omit factions introduced with the full campaign.
	if CampaignSystem.active:
		for faction:Variant in CampaignSystem.definition.factions:
			if not FactionSystem.factions.has(faction.id):
				FactionSystem.factions[faction.id] = {"res_path":"res://data/factions/"+faction.id+".tres","relationship":faction.relationship,"threat":0.0,"escalation_level":0}
	WorkshopSystem.levels = data.get("buildings", {})
	ArmySystem.roster_changed.emit()
