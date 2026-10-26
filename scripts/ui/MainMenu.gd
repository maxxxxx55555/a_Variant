extends Control
const TypeRefMarchCredits=preload("res://scripts/ui/MarchCredits.gd")

var continue_button: Button
var difficulty_choice: OptionButton
var iron_choice: CheckBox
var cached_save: Dictionary = {}

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music("settlement")
	var backdrop:TextureRect= TextureRect.new()
	backdrop.texture = load("res://assets/art/title_painting.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade:Panel= Panel.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_right = -1200
	shade.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.04,0.10,0.10,0.92),Color(0.7,0.6,0.4,0.4)))
	add_child(shade)
	var margin:MarginContainer= MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_right", 1216)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)
	var column:VBoxContainer= VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	theme = preload("res://scripts/ui/MarchTheme.gd").create()
	var title:Label= Label.new()
	title.text = LocalizationManager.get_string("ui.title")
	title.set_meta("locale_key","ui.title")
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_font_override("font", load("res://assets/fonts/Literata.ttf") as Font)
	title.add_theme_color_override("font_color", Color("dfc692"))
	column.add_child(title)
	var subtitle:Label= Label.new()
	subtitle.text = LocalizationManager.get_string("ui.preview")
	subtitle.set_meta("locale_key","ui.preview")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("92b0ad"))
	column.add_child(subtitle)
	var language_choice:OptionButton= OptionButton.new()
	language_choice.name="LanguageChoice"
	language_choice.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	language_choice.add_item("Русский")
	language_choice.add_item("English")
	language_choice.selected = 0 if SettingsManager.language == "ru" else 1
	column.add_child(language_choice)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	language_choice.item_selected.connect(func(index:int)->void:
		SettingsManager.language = "ru" if index == 0 else "en"
		SettingsManager.language_confirmed=true
		SettingsManager.apply_settings()
		SettingsManager.save_settings()
		localize()
	)
	var intro:Label= Label.new()
	intro.text = LocalizationManager.get_string("ui.campaign_summary")
	intro.tooltip_text=LocalizationManager.get_string("ui.campaign_intro")
	intro.set_meta("locale_tooltip","ui.campaign_intro")
	intro.set_meta("locale_key","ui.campaign_summary")
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.y = 96
	column.add_child(intro)
	var slot_choice:OptionButton= OptionButton.new()
	slot_choice.name="SlotChoice"
	for index:int in 7:
		slot_choice.add_item(LocalizationManager.get_string("ui.slot") + " " + str(index + 1) if index < 5 else LocalizationManager.get_string("ui.autosave" if index == 5 else "ui.iron_save"))
	slot_choice.selected = SaveSystem.newest_slot()
	if slot_choice.selected < 5: SaveSystem.selected_slot = slot_choice.selected
	cached_save = SaveSystem.load_slot(slot_choice.selected)
	column.add_child(slot_choice)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	slot_choice.item_selected.connect(func(index:int)->void:
		if index < 5: SaveSystem.selected_slot = index
		cached_save = SaveSystem.load_slot(index)
		var campaign_data: Dictionary = saved_campaign()
		continue_button.disabled = cached_save.is_empty() or not campaign_data.get("active", false) or campaign_data.get("iron_dead", false)
		continue_button.tooltip_text=LocalizationManager.get_string("ui.no_campaign_save") if continue_button.disabled else ""
	)
	continue_button = action(column, "ui.continue", func()->void:
		CampaignSystem.pending_load = cached_save
		CampaignSystem.restore_state(saved_campaign())
		MarchTransition.go_to.call_deferred("res://scenes/world/march.tscn")
	)
	var campaign: Dictionary = saved_campaign()
	continue_button.disabled = cached_save.is_empty() or not campaign.get("active", false) or campaign.get("iron_dead", false)
	difficulty_choice = OptionButton.new()
	difficulty_choice.name="DifficultyChoice"
	for id:String in ["story", "normal", "hard", "expert"]:
		difficulty_choice.add_item(LocalizationManager.get_string("difficulty." + id))
	difficulty_choice.selected = 1
	column.add_child(difficulty_choice)
	iron_choice = CheckBox.new()
	iron_choice.text = LocalizationManager.get_string("ui.iron_mode")
	iron_choice.set_meta("locale_key","ui.iron_mode")
	column.add_child(iron_choice)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	action(column, "ui.new_campaign", func()->void:
		SettingsManager.language_confirmed=true
		SettingsManager.save_settings()
		CampaignSystem.new_campaign(difficulty_choice.selected, iron_choice.button_pressed)
		MarchTransition.go_to.call_deferred("res://scenes/world/march.tscn")
	)
	var credits_button:Button=action(column,"ui.credits",open_credits)
	credits_button.name="CreditsButton"
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	action(column, "ui.exit", func()->void: get_tree().quit())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:localize())
	localize()
	if not SettingsManager.reduced_motion:
		modulate.a=0.9
		# Tween retains this property track until completion.
		@warning_ignore("return_value_discarded")
		create_tween().tween_property(self,"modulate:a",1.0,0.18)
	# The private QA router handles its own rejection/exit; normal startup continues without a flag.
	@warning_ignore("return_value_discarded")
	preload("res://scripts/security/QARouter.gd").request(self)

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("locale_key",key)
	control.custom_minimum_size.y = 56
	parent.add_child(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

func localize() -> void:
	for node:Control in find_children("*","Control",true,false):
		if node.has_meta("locale_key"):node.set("text",LocalizationManager.get_string(str(node.get_meta("locale_key"))))
		if node.has_meta("locale_tooltip"):node.tooltip_text=LocalizationManager.get_string(str(node.get_meta("locale_tooltip")))
	if continue_button:continue_button.tooltip_text=LocalizationManager.get_string("ui.no_campaign_save") if continue_button.disabled else ""
	if difficulty_choice:
		for i:int in 4:difficulty_choice.set_item_text(i,LocalizationManager.get_string("difficulty."+str(["story","normal","hard","expert"][i])))
	var slots:OptionButton=find_child("SlotChoice",true,false)
	if slots:
		for i:int in 7:slots.set_item_text(i,LocalizationManager.get_string("ui.slot")+" "+str(i+1) if i<5 else LocalizationManager.get_string("ui.autosave" if i==5 else "ui.iron_save"))

func open_credits() -> void:
	if find_child("CreditsPanel",true,false):return
	var previous_focus:Control=get_viewport().gui_get_focus_owner()
	var panel:TypeRefMarchCredits=preload("res://scripts/ui/MarchCredits.gd").new()
	add_child(panel)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	panel.closed.connect(func()->void:
		if is_instance_valid(previous_focus):previous_focus.grab_focus()
	)

func _notification(what:int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:get_tree().quit()

func saved_campaign()->Dictionary:
	var simulation:Dictionary=cached_save.get("simulation",{})
	return simulation.get("campaign",{})
