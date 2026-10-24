extends RefCounted

static func panel(color: Color, edge: Color = Color("5b6655")) -> StyleBoxFlat:
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

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", Color("efe5cd"))
	theme.set_stylebox("panel", "PanelContainer", panel(Color("142a28")))
	theme.set_stylebox("panel", "Panel", panel(Color("142a28")))
	for type in ["Button", "OptionButton", "CheckBox"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var color: Color = {"normal": Color("203d36"), "hover": Color("3d5745"), "pressed": Color("4b6247"), "disabled": Color("172c29"), "focus": Color.TRANSPARENT}[state]
			theme.set_stylebox(state, type, panel(color, Color("c3a674") if state == "focus" else Color("61745c")))
		theme.set_color("font_color", type, Color("efe5cd"))
		theme.set_color("font_disabled_color", type, Color("6f8171"))
	theme.set_stylebox("background", "ProgressBar", panel(Color("152822")))
	theme.set_stylebox("fill", "ProgressBar", panel(Color("ac7459"), Color("c59a7b")))
	theme.set_color("font_color", "ProgressBar", Color("fff1d4"))
	return theme
