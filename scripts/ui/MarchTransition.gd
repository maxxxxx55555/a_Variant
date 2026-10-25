extends CanvasLayer
## Persistent scene handoff: show a real stage before threaded resource loading.
var overlay:Control
var loading_tip:Label
var busy:=false
var unsaved_dialog:ConfirmationDialog
const TITLE="res://scenes/ui/main_menu.tscn"
func _ready() -> void:
	layer=100
	process_mode=Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit=false
func show_loading() -> void:
	if is_instance_valid(overlay):
		overlay.show()
		loading_tip.text=LocalizationManager.get_string("flow.tip."+str(Time.get_ticks_msec()%3))
		for label in overlay.find_children("*","Label",true,false):
			if label.has_meta("locale_key"):label.text=LocalizationManager.get_string(label.get_meta("locale_key"))
		return
	overlay=Control.new()
	overlay.name="MarchLoading"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.theme=preload("res://scripts/ui/MarchTheme.gd").create()
	add_child(overlay)
	var backdrop:=ColorRect.new()
	backdrop.color=Color("101b24")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column:=VBoxContainer.new()
	column.custom_minimum_size.x=600
	column.add_theme_constant_override("separation",24)
	center.add_child(column)
	var crest:=TextureRect.new()
	crest.texture=load("res://assets/ui/app-icon.png")
	crest.custom_minimum_size=Vector2(112,112)
	crest.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(crest)
	var title:=Label.new()
	title.text=LocalizationManager.get_string("ui.title")
	title.set_meta("locale_key","ui.title")
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font",load("res://assets/fonts/Literata.ttf"))
	title.add_theme_font_size_override("font_size",38)
	column.add_child(title)
	var status:=Label.new()
	status.text=LocalizationManager.get_string("flow.loading")
	status.set_meta("locale_key","flow.loading")
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color",Color("b7c2c8"))
	column.add_child(status)
	var rule:=ColorRect.new()
	rule.color=Color("b89c72")
	rule.custom_minimum_size.y=2
	column.add_child(rule)
	loading_tip=Label.new()
	loading_tip.text=LocalizationManager.get_string("flow.tip."+str(Time.get_ticks_msec()%3))
	loading_tip.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	loading_tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	loading_tip.custom_minimum_size.x=600
	loading_tip.add_theme_font_size_override("font_size",20)
	column.add_child(loading_tip)
func hide_loading() -> void:
	if is_instance_valid(overlay):overlay.hide()
func go_to(path:String) -> void:
	if busy:return
	busy=true
	get_tree().paused=false
	show_loading()
	await get_tree().process_frame
	await get_tree().process_frame
	var error:=ResourceLoader.load_threaded_request(path,"PackedScene")
	if error!=OK:
		loading_failed(path)
		return
	while ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:
		var scene:PackedScene=ResourceLoader.load_threaded_get(path)
		error=get_tree().change_scene_to_packed(scene)
		await get_tree().process_frame
		await get_tree().process_frame
		if error==OK:hide_loading()
		else:loading_failed(path)
	else:loading_failed(path)
	busy=false
func confirm_unsaved(retry:Callable,leave:Callable) -> void:
	if is_instance_valid(unsaved_dialog):unsaved_dialog.popup_centered();return
	unsaved_dialog=ConfirmationDialog.new()
	unsaved_dialog.theme=preload("res://scripts/ui/MarchTheme.gd").create()
	unsaved_dialog.title=LocalizationManager.get_string("ui.unsaved_title")
	unsaved_dialog.dialog_text=LocalizationManager.get_string("ui.unsaved_body")
	unsaved_dialog.ok_button_text=LocalizationManager.get_string("ui.retry_save")
	unsaved_dialog.cancel_button_text=LocalizationManager.get_string("ui.stay")
	unsaved_dialog.add_button(LocalizationManager.get_string("ui.discard_exit"),true,"discard")
	add_child(unsaved_dialog)
	unsaved_dialog.confirmed.connect(func():
		if retry.call():
			close_unsaved()
			leave.call()
		else:unsaved_dialog.popup_centered.call_deferred()
	)
	unsaved_dialog.custom_action.connect(func(action):
		if action=="discard":
			close_unsaved()
			leave.call()
	)
	unsaved_dialog.canceled.connect(close_unsaved)
	unsaved_dialog.popup_centered(Vector2i(660,240))

func close_unsaved() -> void:
	if is_instance_valid(unsaved_dialog):
		unsaved_dialog.hide()
		unsaved_dialog.queue_free()
	unsaved_dialog=null

func loading_failed(path:String) -> void:
	busy=false
	loading_tip.text=LocalizationManager.get_string("flow.error")
	var back:Button=overlay.find_child("LoadingBack",true,false)
	if not back:
		back=Button.new()
		back.name="LoadingBack"
		loading_tip.get_parent().add_child(back)
		back.pressed.connect(func():
			back.queue_free()
			if path==TITLE:get_tree().quit()
			else:go_to(TITLE)
		)
	back.text=LocalizationManager.get_string("ui.exit" if path==TITLE else "ui.to_menu")
	back.grab_focus()

func _notification(what:int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		var current:Node=get_tree().current_scene
		if current!=null and current.name=="MarchBoot":get_tree().quit()
