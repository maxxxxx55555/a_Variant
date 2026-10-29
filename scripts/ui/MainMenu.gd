extends Control
const TypeRefMarchCredits=preload("res://scripts/ui/MarchCredits.gd")
const UITheme=preload("res://scripts/ui/MarchTheme.gd")

var continue_button: Button
var difficulty_choice: OptionButton
var iron_choice: CheckBox
var cached_save: Dictionary = {}
var primary_button: Button

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music("settlement")
	theme = UITheme.create()
	_build_backdrop()
	var column: VBoxContainer = _build_column()
	_build_header(column)
	_build_actions(column)
	_build_setup(column)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:localize())
	localize()
	if not SettingsManager.reduced_motion:
		modulate.a = 0.9
		# Tween retains this property track until completion.
		@warning_ignore("return_value_discarded")
		create_tween().tween_property(self,"modulate:a",1.0,0.18)
	# The private QA router handles its own rejection/exit; normal startup continues without a flag.
	@warning_ignore("return_value_discarded")
	preload("res://scripts/security/QARouter.gd").request(self)

# One cinematic scrim carries the title column; the painting stays legible beside it.
func _build_backdrop() -> void:
	var backdrop:TextureRect = TextureRect.new()
	backdrop.texture = load("res://assets/art/title_painting.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade:TextureRect = TextureRect.new()
	var gradient:Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 0.82, 1.0])
	gradient.colors = PackedColorArray([
		Color(UITheme.INK, 0.994),
		Color(UITheme.INK, 0.985),
		Color(UITheme.INK, 0.72),
		Color(UITheme.INK, 0.0),
	])
	var texture:GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 512
	texture.height = 8
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(1, 0)
	shade.texture = texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.offset_right = -420.0
	add_child(shade)

func _build_column() -> VBoxContainer:
	var margin:MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 104)
	margin.add_theme_constant_override("margin_right", 1150)
	margin.add_theme_constant_override("margin_top", 84)
	margin.add_theme_constant_override("margin_bottom", 60)
	add_child(margin)
	var column:VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	margin.add_child(column)
	return column

func _build_header(column: VBoxContainer) -> void:
	var title:Label = Label.new()
	title.name = "TitleLabel"
	title.text = LocalizationManager.get_string("ui.title")
	title.set_meta("locale_key","ui.title")
	title.add_theme_font_override("font", UITheme.display_font())
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", UITheme.BRASS)
	title.add_theme_constant_override("outline_size", 0)
	column.add_child(title)
	column.add_child(_spacer(16))
	column.add_child(_hairline(230, UITheme.BRASS_DEEP))
	column.add_child(_spacer(20))
	var subtitle:Label = Label.new()
	subtitle.text = LocalizationManager.get_string("ui.preview")
	subtitle.set_meta("locale_key","ui.preview")
	subtitle.tooltip_text = LocalizationManager.get_string("ui.campaign_intro")
	subtitle.set_meta("locale_tooltip","ui.campaign_intro")
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(600, 0)
	subtitle.add_theme_font_size_override("font_size", 23)
	subtitle.add_theme_color_override("font_color", UITheme.CHALK)
	column.add_child(subtitle)
	column.add_child(_spacer(38))

func _build_actions(column: VBoxContainer) -> void:
	continue_button = action(column, "ui.continue", func()->void:
		CampaignSystem.pending_load = cached_save
		CampaignSystem.restore_state(saved_campaign())
		MarchTransition.go_to.call_deferred("res://scenes/world/march.tscn")
	)
	cached_save = SaveSystem.load_slot(SaveSystem.newest_slot())
	var campaign: Dictionary = saved_campaign()
	continue_button.disabled = cached_save.is_empty() or not campaign.get("active", false) or campaign.get("iron_dead", false)
	continue_button.tooltip_text = LocalizationManager.get_string("ui.no_campaign_save") if continue_button.disabled else ""
	column.add_child(_spacer(12))
	primary_button = action(column, "ui.new_campaign", func()->void:
		SettingsManager.language_confirmed=true
		SettingsManager.save_settings()
		CampaignSystem.new_campaign(difficulty_choice.selected, iron_choice.button_pressed)
		MarchTransition.go_to.call_deferred("res://scenes/world/march.tscn")
	)
	_style_primary(primary_button)
	column.add_child(_spacer(12))
	var credits_button:Button = action(column, "ui.credits", open_credits)
	credits_button.name = "CreditsButton"
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	action(column, "ui.exit", MarchTransition.quit_game)
	column.add_child(_spacer(20))
	column.add_child(_hairline(560, UITheme.LINE_SOFT))
	column.add_child(_spacer(18))

func _build_setup(column: VBoxContainer) -> void:
	var language_choice:OptionButton = OptionButton.new()
	language_choice.name="LanguageChoice"
	language_choice.auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	language_choice.add_item("Русский")
	language_choice.add_item("English")
	language_choice.selected = 0 if SettingsManager.language == "ru" else 1
	_setting_row(column, "ui.language", language_choice)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	language_choice.item_selected.connect(func(index:int)->void:
		SettingsManager.language = "ru" if index == 0 else "en"
		SettingsManager.language_confirmed=true
		SettingsManager.apply_settings()
		SettingsManager.save_settings()
		localize()
	)
	var slot_choice:OptionButton = OptionButton.new()
	slot_choice.name="SlotChoice"
	for index:int in 7:
		slot_choice.add_item(LocalizationManager.get_string("ui.slot") + " " + str(index + 1) if index < 5 else LocalizationManager.get_string("ui.autosave" if index == 5 else "ui.iron_save"))
	slot_choice.selected = SaveSystem.newest_slot()
	if slot_choice.selected < 5: SaveSystem.selected_slot = slot_choice.selected
	cached_save = SaveSystem.load_slot(slot_choice.selected)
	_setting_row(column, "ui.slot", slot_choice)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	slot_choice.item_selected.connect(func(index:int)->void:
		if index < 5: SaveSystem.selected_slot = index
		cached_save = SaveSystem.load_slot(index)
		var campaign_data: Dictionary = saved_campaign()
		continue_button.disabled = cached_save.is_empty() or not campaign_data.get("active", false) or campaign_data.get("iron_dead", false)
		continue_button.tooltip_text=LocalizationManager.get_string("ui.no_campaign_save") if continue_button.disabled else ""
	)
	difficulty_choice = OptionButton.new()
	difficulty_choice.name="DifficultyChoice"
	for id:String in ["story", "normal", "hard", "expert"]:
		difficulty_choice.add_item(LocalizationManager.get_string("difficulty." + id))
	difficulty_choice.selected = 1
	_setting_row(column, "ui.difficulty", difficulty_choice)
	iron_choice = CheckBox.new()
	iron_choice.text = LocalizationManager.get_string("ui.iron_mode")
	iron_choice.set_meta("locale_key","ui.iron_mode")
	iron_choice.add_theme_font_size_override("font_size", 19)
	iron_choice.add_theme_color_override("font_color", UITheme.MIST)
	iron_choice.add_theme_color_override("font_hover_color", UITheme.CHALK)
	iron_choice.add_theme_color_override("font_pressed_color", UITheme.BRASS)
	for state:String in ["normal","hover","pressed","disabled","hover_pressed"]:
		iron_choice.add_theme_stylebox_override(state, UITheme.field(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	column.add_child(_spacer(12))
	column.add_child(iron_choice)

# A settings ledger: quiet label on the left, the control aligned to a shared column.
func _setting_row(column: VBoxContainer, key: String, control: Control) -> void:
	var row:HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	var label:Label = Label.new()
	label.text = LocalizationManager.get_string(key)
	label.set_meta("locale_key", key)
	label.custom_minimum_size = Vector2(190, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(UITheme.CHALK, 0.82))
	row.add_child(label)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size = Vector2(0, 56)
	control.add_theme_font_size_override("font_size", 21)
	row.add_child(control)
	column.add_child(row)
	column.add_child(_spacer(8))
	column.add_child(_hairline(560, UITheme.LINE_SOFT))
	column.add_child(_spacer(8))

func _spacer(height: int) -> Control:
	var gap:Control = Control.new()
	gap.custom_minimum_size = Vector2(0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

func _hairline(width: int, color: Color) -> Control:
	var row:HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var bar:ColorRect = ColorRect.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(width, 1)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(bar)
	var filler:Control = Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(filler)
	return row

func _style_row(button: Button) -> void:
	for state:String in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state, UITheme.row_surface(state))
	button.add_theme_stylebox_override("hover_pressed", UITheme.row_surface("pressed"))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(560, 58)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", UITheme.CHALK)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UITheme.BRASS)
	button.add_theme_color_override("font_disabled_color", UITheme.MIST_DIM)

func _style_primary(button: Button) -> void:
	for state:String in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state, UITheme.primary_surface(state))
	button.add_theme_stylebox_override("hover_pressed", UITheme.primary_surface("pressed"))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(560, 64)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", UITheme.INK)
	button.add_theme_color_override("font_hover_color", UITheme.INK)
	button.add_theme_color_override("font_pressed_color", UITheme.INK)
	button.add_theme_color_override("font_disabled_color", UITheme.MIST_DIM)
	var focus:StyleBoxFlat = StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = UITheme.CHALK
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(6)
	focus.set_expand_margin_all(2)
	button.add_theme_stylebox_override("focus", focus)

func action(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("locale_key",key)
	parent.add_child(control)
	_style_row(control)
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
	if what==NOTIFICATION_WM_CLOSE_REQUEST:MarchTransition.quit_game()

func saved_campaign()->Dictionary:
	var simulation:Dictionary=cached_save.get("simulation",{})
	return simulation.get("campaign",{})
