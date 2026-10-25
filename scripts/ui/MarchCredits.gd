extends Control
signal closed
var title:Label
var body:Label
var close_button:Button
func _ready() -> void:
	name="CreditsPanel"
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index=200
	mouse_filter=Control.MOUSE_FILTER_STOP
	var backdrop:=TextureRect.new()
	backdrop.texture=load("res://assets/art/title_painting.png")
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var shade:=Panel.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_theme_stylebox_override("panel",preload("res://scripts/ui/MarchTheme.gd").panel(Color(0.04,0.10,0.10,0.94),Color("c7ab70")))
	add_child(shade)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]:margin.add_theme_constant_override("margin_"+edge,80)
	for edge in ["top","bottom"]:margin.add_theme_constant_override("margin_"+edge,55)
	add_child(margin)
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",30)
	margin.add_child(column)
	title=Label.new()
	title.add_theme_font_override("font",load("res://assets/fonts/Literata.ttf"))
	title.add_theme_font_size_override("font_size",48)
	title.add_theme_color_override("font_color",Color("ebd9ae"))
	column.add_child(title)
	var scroll:=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body=Label.new()
	body.name="CreditsBody"
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size",26)
	scroll.add_child(body)
	close_button=Button.new()
	close_button.name="CloseCredits"
	close_button.custom_minimum_size=Vector2(200,65)
	close_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	column.add_child(close_button)
	close_button.pressed.connect(close)
	EventBus.language_changed.connect(func(_language):localize())
	localize()
	close_button.grab_focus()
func localize() -> void:
	title.text=LocalizationManager.get_string("ui.credits")
	body.text=LocalizationManager.get_string("ui.credits_body")
	close_button.text=LocalizationManager.get_string("ui.close")
func close() -> void:
	closed.emit()
	queue_free()
func _unhandled_key_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
