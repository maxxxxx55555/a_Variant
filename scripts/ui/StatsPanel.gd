extends Control

signal closed

const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const IconView=preload("res://scripts/ui/IconSet.gd")

var title_label: Label
var body: RichTextLabel
var close_button: Button

func _ready() -> void:
	name = "StatsPanel"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ThemeRef.create()
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color("12171b")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 140)
	for edge: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 64)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 26)
	margin.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	column.add_child(header)
	header.add_child(IconView.rect("stats", Color("c9a227"), Vector2(36,36), "StatsIcon"))
	title_label = Label.new()
	title_label.add_theme_font_override("font", ThemeRef.heading_font(700))
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color("e8dcc3"))
	header.add_child(title_label)
	body = RichTextLabel.new()
	body.name = "StatsBody"
	body.bbcode_enabled = true
	body.scroll_active = true
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 26)
	body.add_theme_font_size_override("bold_font_size", 28)
	column.add_child(body)
	close_button = Button.new()
	close_button.name = "CloseStats"
	close_button.custom_minimum_size = Vector2(220, 64)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(close_button)
	IconView.apply(close_button, "close", 20)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	close_button.pressed.connect(close)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void: localize())
	localize()
	close_button.grab_focus()

func localize() -> void:
	title_label.text = LocalizationManager.get_string("ui.stats")
	close_button.text = LocalizationManager.get_string("ui.close")
	var runs: int = _whole(ProfileStats.data, "runs")
	var wins: int = _whole(ProfileStats.data, "wins")
	var losses: int = _whole(ProfileStats.data, "losses")
	var regions: int = _whole(ProfileStats.data, "regions")
	var wealth: int = roundi(_decimal(ProfileStats.data, "max_wealth"))
	var minutes_total: int = floori(_decimal(ProfileStats.data, "seconds") / 60.0)
	var hours: int = floori(float(minutes_total) / 60.0)
	var minutes: int = minutes_total - hours * 60
	var time_text: String = LocalizationManager.get_string("stats.hours_minutes", {"hours": hours, "minutes": minutes})
	var text: String = "[color=#C9A227][font_size=32]" + LocalizationManager.get_string("stats.overview") + "[/font_size][/color]\n\n"
	text += _stat_line("stats.runs", runs) + "    " + _stat_line("stats.wins", wins) + "    " + _stat_line("stats.losses", losses) + "\n"
	text += _stat_line("stats.regions", regions) + "    " + _stat_line("stats.max_wealth", wealth) + "    " + LocalizationManager.get_string("stats.playtime") + ": " + time_text + "\n\n"
	text += "[color=#C9A227][font_size=30]" + LocalizationManager.get_string("stats.by_difficulty") + "[/font_size][/color]\n\n"
	for index: int in ProfileStats.DIFFICULTY_IDS.size():
		var row: Dictionary = ProfileStats.row(index)
		var difficulty: String = LocalizationManager.get_string("difficulty." + ProfileStats.DIFFICULTY_IDS[index])
		var best_day: int = _whole(row, "best_day")
		text += LocalizationManager.get_string("stats.row", {
			"difficulty": difficulty,
			"runs": _whole(row, "runs"),
			"wins": _whole(row, "wins"),
			"losses": _whole(row, "losses"),
			"best_day": str(best_day) if best_day > 0 else LocalizationManager.get_string("stats.none"),
			"best_wealth": roundi(_decimal(row, "best_wealth"))
		}) + "\n"
	text += "\n[color=#8ba0a4]" + LocalizationManager.get_string("stats.local_note") + "[/color]"
	body.text = text

func _stat_line(key: String, value: int) -> String:
	return LocalizationManager.get_string(key) + ": [b]" + str(value) + "[/b]"

func _whole(record: Dictionary, key: String) -> int:
	var value: Variant = record.get(key, 0)
	if value is int or value is float:
		# Profile rows are sanitized numbers written by ProfileStats.
		@warning_ignore("unsafe_call_argument")
		return int(value)
	return 0

func _decimal(record: Dictionary, key: String) -> float:
	var value: Variant = record.get(key, 0.0)
	if value is int or value is float:
		# Profile rows are sanitized numbers written by ProfileStats.
		@warning_ignore("unsafe_call_argument")
		return float(value)
	return 0.0

func close() -> void:
	closed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
