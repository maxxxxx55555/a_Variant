extends RefCounted

# Release palette: graphite base, pewter panels, parchment accent, clay danger.
const INK:Color = Color("1e242a")
const PANEL:Color = Color("2a323a")
const PANEL_DEEP:Color = Color("171c21")
const PARCHMENT:Color = Color("e8dcc3")
const DANGER:Color = Color("b4534b")
const BRASS:Color = Color("c9a227")
const CHALK:Color = Color("dce3e9")
const MIST:Color = Color("91a0a7")
const SAGE:Color = Color("72968b")
const FOCUS:Color = Color("e8dcc3")
const EDGE:Color = Color("61717a")
const INK_HEX:String = "1E242A"
const PANEL_HEX:String = "2A323A"
const PARCHMENT_HEX:String = "E8DCC3"
const DANGER_HEX:String = "B4534B"

static var surfaces:Dictionary = {}
static var _fonts:Dictionary = {}

static func panel(color: Color, edge: Color = EDGE) -> StyleBoxFlat:
	var box:StyleBoxFlat= StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

static func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	return panel(color,border)

static func focus() -> StyleBoxFlat:
	var box:StyleBoxFlat= panel(Color.TRANSPARENT,FOCUS)
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	return box

static func body_font(weight: float = 500.0) -> FontVariation:
	var key:String="body_"+str(int(weight))
	if _fonts.has(key):
		# The cache only stores FontVariation instances created below.
		@warning_ignore("unsafe_cast")
		return _fonts[key] as FontVariation
	var font:FontVariation= FontVariation.new()
	font.base_font = load("res://assets/fonts/GolosText.ttf")
	font.variation_opentype = {0x77676874: weight}
	# Tabular figures keep every HUD counter from shifting as digits change.
	font.opentype_features = {&"tnum": 1}
	_fonts[key]=font
	return font

static func heading_font(weight: float = 700.0) -> FontVariation:
	var key:String="heading_"+str(int(weight))
	if _fonts.has(key):
		# The cache only stores FontVariation instances created below.
		@warning_ignore("unsafe_cast")
		return _fonts[key] as FontVariation
	var font:FontVariation= FontVariation.new()
	font.base_font = load("res://assets/fonts/Literata.ttf")
	font.variation_opentype = {0x77676874: weight}
	_fonts[key]=font
	return font

static func numeric_font() -> FontVariation:
	return body_font(500.0)

static func accent_text(accent: Color) -> Color:
	var luminance:float=accent.get_luminance()
	if luminance >= 0.42:
		return accent
	return accent.lightened(0.42)

static func surface(state: String) -> StyleBoxTexture:
	if surfaces.has(state): return surfaces[state]
	var box:StyleBoxTexture= StyleBoxTexture.new()
	box.texture = load("res://assets/ui/button-"+state+".svg")
	box.set_texture_margin_all(12)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	surfaces[state] = box
	return box

static func create() -> Theme:
	var theme:Theme= Theme.new()
	theme.default_font_size = 23
	theme.default_font = body_font(500.0)
	for type:String in ["Label","RichTextLabel"]: theme.set_color("font_color",type,CHALK)
	for type:String in ["PanelContainer","Panel"]: theme.set_stylebox("panel",type,panel(PANEL))
	for type:String in ["Button","OptionButton","CheckBox"]:
		for state:String in ["normal","hover","pressed","disabled"]: theme.set_stylebox(state,type,surface(state))
		theme.set_stylebox("focus",type,focus())
		theme.set_color("font_color",type,PARCHMENT)
		theme.set_color("font_hover_color",type,Color.WHITE)
		theme.set_color("font_pressed_color",type,BRASS)
		theme.set_color("font_focus_color",type,PARCHMENT)
		theme.set_color("font_disabled_color",type,MIST)
		theme.set_color("icon_normal_color",type,PARCHMENT)
		theme.set_color("icon_hover_color",type,Color.WHITE)
		theme.set_color("icon_pressed_color",type,BRASS)
		theme.set_color("icon_disabled_color",type,MIST)
	for type:String in ["ItemList","Tree","PopupMenu","TabContainer"]:
		theme.set_stylebox("panel",type,panel(PANEL))
		theme.set_color("font_color",type,PARCHMENT)
		theme.set_color("font_selected_color",type,BRASS)
	for type:String in ["CheckBox","CheckButton"]:
		theme.set_color("font_color",type,PARCHMENT)
		theme.set_color("font_hover_color",type,Color.WHITE)
		theme.set_color("font_pressed_color",type,BRASS)
	theme.set_stylebox("background","ProgressBar",panel(PANEL_DEEP))
	theme.set_stylebox("fill","ProgressBar",panel(DANGER,Color("d08a84")))
	theme.set_color("font_color","ProgressBar",PARCHMENT)
	for type:String in ["TabBar","TabContainer"]:
		for state:String in ["tab_selected","tab_unselected","tab_hovered","tab_disabled"]:
			var tab:StyleBoxFlat=panel(Color("3a4650") if state=="tab_selected" else Color("232a31"),FOCUS if state=="tab_selected" else EDGE)
			tab.content_margin_left=30
			tab.content_margin_right=30
			tab.content_margin_top=17
			tab.content_margin_bottom=17
			theme.set_stylebox(state,type,tab)
	return theme
