extends Control
const IconView=preload("res://scripts/ui/IconSet.gd")
const MotionView=preload("res://scripts/ui/UIMotion.gd")
const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")

signal started(selected: Array)
signal closed

var checks: Dictionary = {}
var start_button: Button
var cancel_button: Button
var banner_preview: Panel
var title_label: Label
var subtitle_label: Label
var carry_label: Label
var start_hint: Label

func _ready() -> void:
	name = "SecondOathPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 210
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop: TextureRect = TextureRect.new()
	backdrop.texture = load("res://assets/art/title_painting.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var shade: Panel = Panel.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.055, 0.075, 0.09, 0.95), Color("c9a227")))
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge:String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 96)
	for edge:String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 48)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	title_label = Label.new()
	title_label.name = "OathTitle"
	title_label.add_theme_font_override("font", ThemeRef.heading_font(700))
	title_label.add_theme_font_size_override("font_size", 46)
	title_label.add_theme_color_override("font_color", ThemeRef.PARCHMENT)
	column.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", ThemeRef.CHALK)
	column.add_child(subtitle_label)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.name = "OathList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for entry:Dictionary in CampaignSystem.oath_list():
		var row: PanelContainer = PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var accent: Color = Color(str(entry.get("color", "#C9A227")))
		row.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.10, 0.13, 0.16, 0.94), accent))
		list.add_child(row)
		var check: CheckButton = CheckButton.new()
		check.name = "Oath_" + str(entry.get("id", ""))
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.add_theme_font_size_override("font_size", 23)
		check.add_theme_color_override("font_color", accent.lightened(0.25))
		row.add_child(check)
		checks[str(entry.get("id", ""))] = check
		# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
		@warning_ignore("return_value_discarded")
		check.toggled.connect(func(_pressed: bool) -> void: refresh_preview())
	banner_preview = Panel.new()
	banner_preview.name = "BannerPreview"
	banner_preview.custom_minimum_size = Vector2(0, 48)
	banner_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(banner_preview)
	carry_label = Label.new()
	carry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	carry_label.add_theme_font_size_override("font_size", 21)
	carry_label.add_theme_color_override("font_color", ThemeRef.MIST)
	column.add_child(carry_label)
	start_hint = Label.new()
	start_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_hint.add_theme_font_size_override("font_size", 20)
	start_hint.add_theme_color_override("font_color", ThemeRef.BRASS)
	column.add_child(start_hint)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	column.add_child(buttons)
	start_button = Button.new()
	start_button.name = "StartSecondOath"
	start_button.custom_minimum_size = Vector2(340, 62)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(start_button)
	IconView.apply(start_button, "oath", 22)
	MotionView.attach(start_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	start_button.pressed.connect(start)
	cancel_button = Button.new()
	cancel_button.name = "CancelSecondOath"
	cancel_button.custom_minimum_size = Vector2(200, 62)
	buttons.add_child(cancel_button)
	IconView.apply(cancel_button, "close", 20)
	MotionView.attach(cancel_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	cancel_button.pressed.connect(close)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language: Variant) -> void: localize())
	localize()
	refresh_preview()
	if not checks.is_empty():
		# checks only stores the CheckButton instances created above.
		@warning_ignore("unsafe_cast")
		(checks[checks.keys()[0]] as CheckButton).grab_focus()

func localize() -> void:
	title_label.text = LocalizationManager.get_string("oath.second.title")
	subtitle_label.text = LocalizationManager.get_string("oath.second.subtitle", {"level": CampaignSystem.ng_level + 1, "difficulty": LocalizationManager.get_string("difficulty." + str(["story", "normal", "hard", "expert"][clampi(CampaignSystem.difficulty, 0, 3)]))})
	for entry:Dictionary in CampaignSystem.oath_list():
		var check: CheckButton = checks.get(str(entry.get("id", "")))
		if check == null:
			continue
		check.text = LocalizationManager.get_string(str(entry.get("name", ""))) + "\n" + LocalizationManager.get_string(str(entry.get("description", "")))
	carry_label.text = LocalizationManager.get_string("oath.second.carry", {"titles": _titles_text(), "soldiers": ArmySystem.get_total_soldiers()})
	start_hint.text = LocalizationManager.get_string("oath.second.hint")
	start_button.text = LocalizationManager.get_string("oath.second.start")
	cancel_button.text = LocalizationManager.get_string("ui.back")

func _titles_text() -> String:
	if CampaignSystem.titles.is_empty():
		return LocalizationManager.get_string("oath.second.no_titles")
	var names: Array[String] = []
	for key:String in CampaignSystem.titles:
		names.append(LocalizationManager.get_string(key))
	return ", ".join(names)

func selected() -> Array:
	var result: Array = []
	for id:Variant in checks:
		# checks only stores the CheckButton instances created in _ready().
		@warning_ignore("unsafe_cast")
		if (checks[id] as CheckButton).button_pressed:
			result.append(str(id))
	return result

func refresh_preview() -> void:
	var chosen: Array = selected()
	var color: Color = Color("61717a")
	var name_key: String = "oath.second.none"
	if not chosen.is_empty():
		var entry: Dictionary = CampaignSystem.oath(str(chosen[0]))
		color = Color(str(entry.get("color", "#C9A227")))
		name_key = str(entry.get("banner", "oath.second.none"))
	banner_preview.add_theme_stylebox_override("panel", preload("res://scripts/ui/MarchTheme.gd").panel(color.darkened(0.35), color))
	banner_preview.tooltip_text = LocalizationManager.get_string(name_key)
	start_button.disabled = false

func start() -> void:
	var chosen: Array = selected()
	started.emit(chosen)
	queue_free()

func close() -> void:
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
