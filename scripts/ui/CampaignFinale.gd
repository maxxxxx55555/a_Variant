extends Control
const OathView=preload("res://scripts/ui/OathPanel.gd")
const IconView=preload("res://scripts/ui/IconSet.gd")
const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const MotionView=preload("res://scripts/ui/UIMotion.gd")
signal continued
var route:String= "diplomatic"
var quests:int= 0
var days:int= 1
var brand_label:Label
var title_label:Label
var body_label:Label
var titles_label:Label
var banner_label:Label
var continue_button:Button
var oath_button:Button

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
	margin.add_theme_constant_override("margin_right",800)
	margin.add_theme_constant_override("margin_top",90)
	margin.add_theme_constant_override("margin_bottom",90)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column:VBoxContainer=VBoxContainer.new()
	column.add_theme_constant_override("separation",24)
	margin.add_child(column)
	var brand:Label=Label.new()
	brand_label=brand
	brand.text=LocalizationManager.get_string("ui.title")
	brand.add_theme_color_override("font_color",ThemeRef.MIST)
	column.add_child(brand)
	title_label=Label.new()
	title_label.name="EndingTitle"
	title_label.add_theme_font_override("font",ThemeRef.heading_font(700))
	title_label.add_theme_font_size_override("font_size",52)
	title_label.add_theme_color_override("font_color",ThemeRef.PARCHMENT)
	title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title_label)
	banner_label=Label.new()
	banner_label.name="EndingBanner"
	banner_label.add_theme_font_size_override("font_size",22)
	banner_label.add_theme_color_override("font_color",ThemeRef.BRASS)
	column.add_child(banner_label)
	body_label=Label.new()
	body_label.add_theme_font_size_override("font_size",26)
	body_label.add_theme_color_override("font_color",ThemeRef.CHALK)
	body_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(body_label)
	titles_label=Label.new()
	titles_label.name="EndingTitles"
	titles_label.add_theme_font_size_override("font_size",21)
	titles_label.add_theme_color_override("font_color",ThemeRef.MIST)
	titles_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	column.add_child(titles_label)
	var space:Control=Control.new()
	space.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(space)
	var buttons:HBoxContainer=HBoxContainer.new()
	buttons.add_theme_constant_override("separation",16)
	column.add_child(buttons)
	oath_button=Button.new()
	oath_button.name="SecondOathButton"
	oath_button.custom_minimum_size.y=72
	oath_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	buttons.add_child(oath_button)
	IconView.apply(oath_button,"oath",22)
	MotionView.attach(oath_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	oath_button.pressed.connect(open_oath)
	continue_button=Button.new()
	continue_button.name="ContinueEnding"
	continue_button.custom_minimum_size=Vector2(210,72)
	buttons.add_child(continue_button)
	IconView.apply(continue_button,"continue",20)
	MotionView.attach(continue_button)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	continue_button.pressed.connect(func()->void: continued.emit())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:localize())
	localize()
	oath_button.grab_focus()

func localize() -> void:
	if is_instance_valid(brand_label):
		brand_label.text=LocalizationManager.get_string("ui.title")
	title_label.text=LocalizationManager.get_string("ending."+route)
	body_label.text=LocalizationManager.get_string("ending.body",{"quests":quests,"days":days})
	var banner_text:String=""
	if not CampaignSystem.ng_banner.is_empty():
		banner_text=LocalizationManager.get_string(CampaignSystem.ng_banner)
	banner_label.text=banner_text
	banner_label.visible=not banner_text.is_empty()
	var earned:Array[String]=[]
	for key:String in CampaignSystem.titles.slice(maxi(0,CampaignSystem.titles.size()-2),CampaignSystem.titles.size()):
		earned.append(LocalizationManager.get_string(key))
	if earned.is_empty():
		titles_label.text=LocalizationManager.get_string("ending.no_titles")
	else:
		titles_label.text=LocalizationManager.get_string("ending.titles",{"titles":", ".join(earned)})
	continue_button.text=LocalizationManager.get_string("ui.continue_world")
	oath_button.text=LocalizationManager.get_string("oath.second.start")
	oath_button.disabled=not CampaignSystem.second_oath_available()

func open_oath() -> void:
	if not CampaignSystem.second_oath_available() or is_instance_valid(find_child("SecondOathPanel",true,false)):
		return
	var panel:OathView=OathView.new()
	add_child(panel)
	# This signal is wired once per owning panel; the panel frees itself after the choice.
	@warning_ignore("return_value_discarded")
	panel.started.connect(func(selected:Array)->void:
		CampaignSystem.pending_load={}
		if CampaignSystem.begin_second_oath(selected):
			MarchTransition.go_to.call_deferred("res://scenes/world/march.tscn")
		elif is_instance_valid(oath_button):
			oath_button.grab_focus()
	)
	# This signal is wired once per owning panel; the panel frees itself after cancellation.
	@warning_ignore("return_value_discarded")
	panel.closed.connect(func()->void:
		if is_instance_valid(oath_button):oath_button.grab_focus()
	)
