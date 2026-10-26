extends Control
signal continued
var route:String= "diplomatic"
var quests:int= 0
var days:int= 1

func _ready() -> void:
	theme=preload("res://scripts/ui/MarchTheme.gd").create()
	var background:TextureRect=TextureRect.new()
	background.texture=load("res://assets/art/title_painting.png")
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:TextureRect=TextureRect.new()
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var colors:Gradient=Gradient.new()
	colors.offsets=PackedFloat32Array([0,0.48,1])
	colors.colors=PackedColorArray([Color(0.04,0.07,0.10,0.98),Color(0.04,0.07,0.10,0.88),Color(0.04,0.07,0.10,0.12)])
	var texture:GradientTexture2D=GradientTexture2D.new()
	texture.gradient=colors
	texture.width=256
	texture.height=8
	shade.texture=texture
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:MarginContainer=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",112)
	margin.add_theme_constant_override("margin_right",880)
	margin.add_theme_constant_override("margin_top",104)
	margin.add_theme_constant_override("margin_bottom",120)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column:VBoxContainer=VBoxContainer.new()
	column.add_theme_constant_override("separation",32)
	margin.add_child(column)
	var brand:Label=Label.new()
	brand.text="MARCHLAND OATHS"
	brand.add_theme_color_override("font_color",Color("b6c2c5"))
	column.add_child(brand)
	var title:Label=Label.new()
	title.text=LocalizationManager.get_string("ending."+route)
	title.add_theme_font_override("font",load("res://assets/fonts/Literata.ttf") as Font)
	title.add_theme_font_size_override("font_size",56)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	var body:Label=Label.new()
	body.text=LocalizationManager.get_string("ending.body",{"quests":quests,"days":days})
	body.add_theme_font_size_override("font_size",28)
	body.add_theme_color_override("font_color",Color("bdc9cf"))
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body)
	var space:Control=Control.new()
	space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(space)
	var button:Button=Button.new()
	button.name="ContinueEnding"
	button.text=LocalizationManager.get_string("ui.continue_world")
	button.custom_minimum_size.y=72
	column.add_child(button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	button.pressed.connect(func()->void: continued.emit())
	button.grab_focus()
