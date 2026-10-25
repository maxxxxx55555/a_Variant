extends Control

var continue_button: Button
var difficulty_choice: OptionButton
var iron_choice: CheckBox
var cached_save: Dictionary = {}

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music("settlement")
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/art/title_painting.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade := Panel.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_right = -1200
	shade.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.04,0.10,0.10,0.92),Color(0.7,0.6,0.4,0.4)))
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 65)
	margin.add_theme_constant_override("margin_right", 1220)
	margin.add_theme_constant_override("margin_top", 45)
	margin.add_theme_constant_override("margin_bottom", 45)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	theme = preload("res://scripts/ui/MarchTheme.gd").create()
	var title := Label.new()
	title.text = LocalizationManager.get_string("ui.title")
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_font_override("font", load("res://assets/fonts/Literata.ttf"))
	title.add_theme_color_override("font_color", Color("dfc692"))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = LocalizationManager.get_string("ui.preview")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("92b0ad"))
	column.add_child(subtitle)
	var language_choice := OptionButton.new()
	language_choice.add_item("Русский")
	language_choice.add_item("English")
	language_choice.selected = 0 if SettingsManager.language == "ru" else 1
	column.add_child(language_choice)
	language_choice.item_selected.connect(func(index):
		SettingsManager.language = "ru" if index == 0 else "en"
		SettingsManager.apply_settings()
		SettingsManager.save_settings()
		get_tree().reload_current_scene()
	)
	var intro := Label.new()
	intro.text = LocalizationManager.get_string("ui.campaign_intro")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 130
	column.add_child(intro)
	var slot_choice := OptionButton.new()
	for index in 7:
		slot_choice.add_item(LocalizationManager.get_string("ui.slot") + " " + str(index + 1) if index < 5 else LocalizationManager.get_string("ui.autosave" if index == 5 else "ui.iron_save"))
	slot_choice.selected = SaveSystem.newest_slot()
	if slot_choice.selected < 5: SaveSystem.selected_slot = slot_choice.selected
	cached_save = SaveSystem.load_slot(slot_choice.selected)
	column.add_child(slot_choice)
	slot_choice.item_selected.connect(func(index):
		if index < 5: SaveSystem.selected_slot = index
		cached_save = SaveSystem.load_slot(index)
		var campaign_data: Dictionary = cached_save.get("simulation", {}).get("campaign", {})
		continue_button.disabled = cached_save.is_empty() or not campaign_data.get("active", false) or campaign_data.get("iron_dead", false)
	)
	continue_button = action(column, "ui.continue", func():
		CampaignSystem.pending_load = cached_save
		CampaignSystem.restore_state(cached_save.get("simulation", {}).get("campaign", {}))
		get_tree().change_scene_to_file("res://scenes/world/march.tscn")
	)
	var campaign: Dictionary = cached_save.get("simulation", {}).get("campaign", {})
	continue_button.disabled = cached_save.is_empty() or not campaign.get("active", false) or campaign.get("iron_dead", false)
	difficulty_choice = OptionButton.new()
	for id in ["story", "normal", "hard", "expert"]:
		difficulty_choice.add_item(LocalizationManager.get_string("difficulty." + id))
	difficulty_choice.selected = 1
	column.add_child(difficulty_choice)
	iron_choice = CheckBox.new()
	iron_choice.text = LocalizationManager.get_string("ui.iron_mode")
	column.add_child(iron_choice)
	action(column, "ui.new_campaign", func():
		CampaignSystem.new_campaign(difficulty_choice.selected, iron_choice.button_pressed)
		get_tree().change_scene_to_file("res://scenes/world/march.tscn")
	)
	action(column, "ui.exit", func(): get_tree().quit())
	if OS.get_cmdline_user_args().has("--verify-build"):
		var verification := preload("res://scripts/verification/CampaignRoute.gd").new()
		get_tree().root.add_child.call_deferred(verification)

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = LocalizationManager.get_string(key)
	control.custom_minimum_size.y = 55
	parent.add_child(control)
	control.pressed.connect(callback)
	return control
