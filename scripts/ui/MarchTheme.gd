class_name MarchTheme
extends RefCounted

# Premium frontier ledger: deep ink, brass hairlines, one accent, no ornament.
const INK:Color = Color("0d161c")
const SLATE:Color = Color("16232b")
const SLATE_RAISED:Color = Color("1d2d37")
const SLATE_SUNK:Color = Color("111c23")
const LINE:Color = Color("2b3c46")
const LINE_SOFT:Color = Color("223139")
const CHALK:Color = Color("e8edf0")
const MIST:Color = Color("94a3ab")
const MIST_DIM:Color = Color("6d7d86")
const BRASS:Color = Color("d9bf8b")
const BRASS_DEEP:Color = Color("a98d5d")
const SAGE:Color = Color("6f9185")
const CLAY:Color = Color("b8837f")

const RADIUS_PANEL:int = 8
const RADIUS_CONTROL:int = 6

static var surfaces:Dictionary = {}
static var fonts:Dictionary = {}

static func display_font() -> Font:
	if fonts.has("display"): return fonts["display"]
	var font:Font = load("res://assets/fonts/Literata.ttf")
	fonts["display"] = font
	return font

static func body_font(weight:int = 500, tracking:int = 0) -> FontVariation:
	var key:String = "body-%d-%d" % [weight, tracking]
	if fonts.has(key): return fonts[key]
	var font:FontVariation = FontVariation.new()
	font.base_font = load("res://assets/fonts/GolosText.ttf")
	font.variation_opentype = {0x77676874: float(weight)}
	if tracking != 0:
		font.spacing_glyph = tracking
	fonts[key] = font
	return font

static func panel(color: Color, edge: Color = LINE) -> StyleBoxFlat:
	var box:StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(RADIUS_PANEL)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	return panel(color, border)

# A flat field: hairline edge, no gradient, no shadow.
static func field(color: Color = SLATE_RAISED, edge: Color = LINE, radius: int = RADIUS_CONTROL) -> StyleBoxFlat:
	var box:StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

# A rule with a single brass hairline; used as a section divider.
static func rule(color: Color = LINE, height: int = 1) -> ColorRect:
	var bar:ColorRect = ColorRect.new()
	bar.color = color
	bar.custom_minimum_size.y = height
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar

static func eyebrow(text: String, color: Color = BRASS_DEEP) -> Label:
	var label:Label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_override("font", body_font(500, 3))
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

static func caption(text: String, color: Color = MIST) -> Label:
	var label:Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

static func surface(state: String) -> StyleBoxTexture:
	if surfaces.has(state): return surfaces[state]
	var box:StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load("res://assets/ui/button-" + state + ".svg")
	box.set_texture_margin_all(12)
	box.content_margin_left = 28
	box.content_margin_right = 28
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	surfaces[state] = box
	return box

# Title-screen rows read as ledger lines: hairline under each entry.
static func row_surface(state: String) -> StyleBoxTexture:
	var key:String = "row-" + state
	if surfaces.has(key): return surfaces[key]
	var box:StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load("res://assets/ui/menu-row-" + state + ".svg")
	box.set_texture_margin_all(12)
	box.content_margin_left = 26
	box.content_margin_right = 16
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	surfaces[key] = box
	return box

# The single brass call to action; every other control stays quiet.
static func primary_surface(state: String) -> StyleBoxTexture:
	var key:String = "primary-" + state
	if surfaces.has(key): return surfaces[key]
	var box:StyleBoxTexture = StyleBoxTexture.new()
	box.texture = load("res://assets/ui/button-primary-" + state + ".svg")
	box.set_texture_margin_all(12)
	box.content_margin_left = 30
	box.content_margin_right = 30
	box.content_margin_top = 16
	box.content_margin_bottom = 16
	surfaces[key] = box
	return box

static func create() -> Theme:
	var theme:Theme = Theme.new()
	theme.default_font_size = 23
	theme.default_font = body_font(500)
	theme.set_font("font", "Label", body_font(400))
	theme.set_font("normal_font", "RichTextLabel", body_font(400))
	theme.set_font("bold_font", "RichTextLabel", body_font(600))
	for type:String in ["Label", "RichTextLabel"]:
		theme.set_color("font_color", type, CHALK)
		theme.set_color("default_color", type, CHALK)
	for type:String in ["PanelContainer", "Panel", "PopupPanel"]:
		theme.set_stylebox("panel", type, panel(SLATE))
	# Tab bodies inherit the card they sit on; only the tab strip draws.
	var hollow:StyleBoxFlat = StyleBoxFlat.new()
	hollow.bg_color = Color.TRANSPARENT
	hollow.set_corner_radius_all(0)
	hollow.set_content_margin_all(0)
	theme.set_stylebox("panel", "TabContainer", hollow)
	for type:String in ["Button", "OptionButton", "CheckBox", "CheckButton", "MenuButton"]:
		for state:String in ["normal", "hover", "pressed", "disabled"]:
			theme.set_stylebox(state, type, surface(state))
		theme.set_stylebox("hover_pressed", type, surface("pressed"))
		var focus:StyleBoxFlat = StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = BRASS
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(RADIUS_CONTROL)
		focus.set_expand_margin_all(1)
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, CHALK)
		theme.set_color("font_hover_color", type, Color.WHITE)
		theme.set_color("font_focus_color", type, Color.WHITE)
		theme.set_color("font_pressed_color", type, BRASS)
		theme.set_color("font_hover_pressed_color", type, BRASS)
		theme.set_color("font_disabled_color", type, MIST_DIM)
		theme.set_constant("h_separation", type, 10)
	for type:String in ["ItemList", "Tree", "PopupMenu"]:
		theme.set_stylebox("panel", type, panel(SLATE))
		theme.set_color("font_color", type, CHALK)
		theme.set_color("font_selected_color", type, BRASS)
		theme.set_color("font_hovered_color", type, Color.WHITE)
		theme.set_stylebox("selected", type, field(SLATE_RAISED, LINE_SOFT))
		theme.set_stylebox("selected_focus", type, field(SLATE_RAISED, BRASS))
		theme.set_stylebox("hovered", type, field(SLATE_RAISED, LINE_SOFT))
		theme.set_stylebox("cursor", type, field(Color.TRANSPARENT, LINE))
		theme.set_stylebox("cursor_unfocused", type, field(Color.TRANSPARENT, LINE_SOFT))
	for type:String in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", type, field(SLATE_SUNK, LINE))
		theme.set_stylebox("focus", type, field(SLATE_SUNK, BRASS))
		theme.set_stylebox("read_only", type, field(SLATE_SUNK, LINE_SOFT))
		theme.set_color("font_color", type, CHALK)
		theme.set_color("font_placeholder_color", type, MIST_DIM)
		theme.set_color("caret_color", type, BRASS)
		theme.set_color("selection_color", type, Color(BRASS, 0.22))
	# Thin brass meter; the bar is a measuring line, not a pill.
	theme.set_stylebox("background", "ProgressBar", field(SLATE_SUNK, LINE_SOFT, 2))
	theme.set_stylebox("fill", "ProgressBar", field(CLAY, Color.TRANSPARENT, 2))
	theme.set_color("font_color", "ProgressBar", CHALK)
	theme.set_font_size("font_size", "ProgressBar", 17)
	# Sliders and bars are measuring lines: 2px tracks, no padding, no pill shapes.
	theme.set_stylebox("slider", "HSlider", _track(SLATE_SUNK, true, 1))
	theme.set_stylebox("grabber_area", "HSlider", _track(BRASS_DEEP, true, 1))
	theme.set_stylebox("grabber_area_highlight", "HSlider", _track(BRASS, true, 1))
	theme.set_constant("grabber_offset", "HSlider", 0)
	theme.set_icon("grabber", "HSlider", _grabber())
	theme.set_icon("grabber_highlight", "HSlider", _grabber())
	theme.set_stylebox("scroll", "VScrollBar", _track(Color.TRANSPARENT, false, 1))
	theme.set_stylebox("grabber", "VScrollBar", _track(LINE, false, 2))
	theme.set_stylebox("grabber_highlight", "VScrollBar", _track(MIST_DIM, false, 2))
	theme.set_stylebox("grabber_pressed", "VScrollBar", _track(BRASS_DEEP, false, 2))
	theme.set_stylebox("scroll", "HScrollBar", _track(Color.TRANSPARENT, true, 1))
	theme.set_stylebox("grabber", "HScrollBar", _track(LINE, true, 2))
	theme.set_stylebox("grabber_highlight", "HScrollBar", _track(MIST_DIM, true, 2))
	for type:String in ["TabBar", "TabContainer"]:
		for state:String in ["tab_selected", "tab_unselected", "tab_hovered", "tab_disabled"]:
			var tab:StyleBoxFlat = StyleBoxFlat.new()
			tab.bg_color = Color.TRANSPARENT
			tab.set_corner_radius_all(0)
			tab.border_color = BRASS if state == "tab_selected" else (LINE if state == "tab_hovered" else Color.TRANSPARENT)
			tab.border_width_bottom = 2 if state == "tab_selected" else 1
			tab.content_margin_left = 26
			tab.content_margin_right = 26
			tab.content_margin_top = 14
			tab.content_margin_bottom = 12
			theme.set_stylebox(state, type, tab)
		theme.set_color("font_selected_color", type, BRASS)
		theme.set_color("font_unselected_color", type, MIST)
		theme.set_color("font_hovered_color", type, CHALK)
		theme.set_font_size("font_size", type, 21)
	var horizontal:StyleBoxLine = StyleBoxLine.new()
	horizontal.color = LINE_SOFT
	horizontal.thickness = 1
	horizontal.grow_begin = 0
	horizontal.grow_end = 0
	theme.set_stylebox("separator", "HSeparator", horizontal)
	var vertical:StyleBoxLine = StyleBoxLine.new()
	vertical.color = LINE_SOFT
	vertical.thickness = 1
	vertical.vertical = true
	vertical.grow_begin = 0
	vertical.grow_end = 0
	theme.set_stylebox("separator", "VSeparator", vertical)
	theme.set_icon("checked", "CheckBox", _check_icon(true))
	theme.set_icon("unchecked", "CheckBox", _check_icon(false))
	theme.set_icon("checked", "CheckButton", _check_icon(true))
	theme.set_icon("unchecked", "CheckButton", _check_icon(false))
	theme.set_constant("h_separation", "CheckBox", 12)
	theme.set_stylebox("panel", "TooltipPanel", field(INK, LINE))
	theme.set_color("font_color", "TooltipLabel", CHALK)
	theme.set_font_size("font_size", "TooltipLabel", 19)
	theme.set_stylebox("panel", "AcceptDialog", panel(SLATE))
	theme.set_constant("separation", "VBoxContainer", 12)
	theme.set_constant("separation", "HBoxContainer", 12)
	return theme

# A measuring line: content margins give the stylebox the only height or width it has.
static func _track(color: Color, horizontal: bool, thickness: int) -> StyleBoxFlat:
	var box:StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(1)
	box.set_content_margin_all(0)
	if horizontal:
		box.content_margin_top = thickness
		box.content_margin_bottom = thickness
	else:
		box.content_margin_left = thickness
		box.content_margin_right = thickness
	return box

# Square brass markers instead of the engine's default tick icons.
static func _check_icon(on: bool) -> ImageTexture:
	var image:Image = Image.create(18, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y:int in 18:
		for x:int in 18:
			var edge:bool = x == 0 or y == 0 or x == 17 or y == 17
			if edge:
				image.set_pixel(x, y, BRASS if on else MIST_DIM)
			elif on and 1 <= x and x <= 16 and 1 <= y and y <= 16:
				image.set_pixel(x, y, BRASS)
	if on:
		for step:int in 4:
			image.set_pixel(4 + step, 9 + step, INK)
			image.set_pixel(5 + step, 9 + step, INK)
			image.set_pixel(4 + step, 10 + step, INK)
		for step:int in 4:
			image.set_pixel(11 - step, 13 - step, INK)
			image.set_pixel(12 - step, 13 - step, INK)
			image.set_pixel(11 - step, 14 - step, INK)
	return ImageTexture.create_from_image(image)

static func _grabber() -> ImageTexture:
	# A 12px brass lozenge: flat, no glow.
	var image:Image = Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y:int in 12:
		for x:int in 12:
			var dx:float = absf(float(x) - 5.5)
			var dy:float = absf(float(y) - 5.5)
			if dx + dy <= 5.0:
				image.set_pixel(x, y, BRASS)
	return ImageTexture.create_from_image(image)
