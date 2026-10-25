extends RefCounted
static var surfaces := {}
static func panel(color: Color, edge: Color = Color("61717a")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

static func style(color: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	return panel(color,border)

static func surface(state: String) -> StyleBoxTexture:
	if surfaces.has(state): return surfaces[state]
	var box := StyleBoxTexture.new()
	box.texture = load("res://assets/ui/button-"+state+".svg")
	box.set_texture_margin_all(12)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 12
	box.content_margin_bottom = 14
	surfaces[state] = box
	return box

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 23
	var body := FontVariation.new()
	body.base_font = load("res://assets/fonts/GolosText.ttf")
	body.variation_opentype = {0x77676874:500.0}
	theme.default_font = body
	for type in ["Label","RichTextLabel"]: theme.set_color("font_color",type,Color("dce3e9"))
	for type in ["PanelContainer","Panel"]: theme.set_stylebox("panel",type,panel(Color("1c2932")))
	for type in ["Button","OptionButton","CheckBox"]:
		for state in ["normal","hover","pressed","disabled"]: theme.set_stylebox(state,type,surface(state))
		var focus := panel(Color.TRANSPARENT,Color("b6c2c5"))
		focus.set_border_width_all(2)
		theme.set_stylebox("focus",type,focus)
		theme.set_color("font_color",type,Color("e7e9e9"))
		theme.set_color("font_hover_color",type,Color.WHITE)
		theme.set_color("font_pressed_color",type,Color("efe1ce"))
		theme.set_color("font_disabled_color",type,Color("91a0a7"))
	for type in ["ItemList","Tree","PopupMenu","TabContainer"]:
		theme.set_stylebox("panel",type,panel(Color("1c2932")))
		theme.set_color("font_color",type,Color("e7e9e9"))
	theme.set_stylebox("background","ProgressBar",panel(Color("1c252d")))
	theme.set_stylebox("fill","ProgressBar",panel(Color("8d5d60"),Color("bd8a87")))
	theme.set_color("font_color","ProgressBar",Color("e7e9e9"))
	for type in ["TabBar","TabContainer"]:
		for state in ["tab_selected","tab_unselected","tab_hovered","tab_disabled"]:
			var tab:=panel(Color("344b59") if state=="tab_selected" else Color("1b2b35"),Color("69818f"))
			tab.content_margin_left=30
			tab.content_margin_right=30
			tab.content_margin_top=17
			tab.content_margin_bottom=17
			theme.set_stylebox(state,type,tab)
	return theme
