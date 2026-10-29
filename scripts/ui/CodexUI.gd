extends PanelContainer

signal closed

const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const IconView=preload("res://scripts/ui/IconSet.gd")
const LOCKED_LABEL:String="???"

var title_label: Label
var progress_label: Label
var close_button: Button
var tabs: TabContainer
var category_ids: Array[String] = []
var lists: Array[ItemList] = []
var bodies: Array[RichTextLabel] = []
var headers: Array[Label] = []

func _ready() -> void:
	name="CodexPanel"
	process_mode=Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style:StyleBoxFlat=ThemeRef.panel(Color(0.09,0.11,0.13,0.985),Color("c9a227"))
	style.content_margin_left=56
	style.content_margin_right=56
	style.content_margin_top=30
	style.content_margin_bottom=30
	add_theme_stylebox_override("panel",style)
	var column:VBoxContainer=VBoxContainer.new()
	column.add_theme_constant_override("separation",16)
	add_child(column)
	var header:HBoxContainer=HBoxContainer.new()
	header.add_theme_constant_override("separation",24)
	column.add_child(header)
	header.add_child(IconView.rect("codex",Color("c9a227"),Vector2(34,34),"CodexIcon"))
	title_label=Label.new()
	title_label.add_theme_font_override("font",ThemeRef.heading_font(700))
	title_label.add_theme_font_size_override("font_size",40)
	title_label.add_theme_color_override("font_color",Color("e8dcc3"))
	title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	progress_label=Label.new()
	progress_label.name="CodexProgress"
	progress_label.add_theme_font_size_override("font_size",23)
	progress_label.add_theme_color_override("font_color",Color("c9a227"))
	header.add_child(progress_label)
	close_button=Button.new()
	close_button.name="CloseCodex"
	close_button.custom_minimum_size=Vector2(170,52)
	header.add_child(close_button)
	IconView.apply(close_button,"close",20)
	# This signal is wired once per owning node; the owner decides whether to hide or free the panel.
	@warning_ignore("return_value_discarded")
	close_button.pressed.connect(func()->void:closed.emit())
	tabs=TabContainer.new()
	tabs.name="CodexTabs"
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	for category:Dictionary in CodexSystem.categories():
		category_ids.append(str(category.get("id","")))
		var tab:VBoxContainer=VBoxContainer.new()
		tab.name="Category_"+str(category.get("id",""))
		tab.add_theme_constant_override("separation",12)
		tabs.add_child(tab)
		var category_header:Label=Label.new()
		category_header.add_theme_font_size_override("font_size",21)
		category_header.add_theme_color_override("font_color",Color("72968b"))
		tab.add_child(category_header)
		headers.append(category_header)
		var split:HBoxContainer=HBoxContainer.new()
		split.add_theme_constant_override("separation",24)
		split.size_flags_vertical=Control.SIZE_EXPAND_FILL
		tab.add_child(split)
		var list:ItemList=ItemList.new()
		list.custom_minimum_size=Vector2(330,0)
		list.size_flags_vertical=Control.SIZE_EXPAND_FILL
		list.add_theme_font_size_override("font_size",22)
		split.add_child(list)
		lists.append(list)
		var body:RichTextLabel=RichTextLabel.new()
		body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		body.size_flags_vertical=Control.SIZE_EXPAND_FILL
		body.bbcode_enabled=true
		body.fit_content=false
		body.scroll_active=true
		body.custom_minimum_size.x=420
		body.add_theme_font_size_override("font_size",24)
		split.add_child(body)
		bodies.append(body)
		var tab_index:int=lists.size()-1
		# This signal is wired once per owning node; the captured tab index is stable for this panel.
		@warning_ignore("return_value_discarded")
		list.item_selected.connect(func(item_index:int)->void:show_entry(tab_index,item_index))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CodexSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:refresh())
	refresh()
	if not lists.is_empty() and lists[0].item_count>0:
		lists[0].select(0)
		show_entry(0,0)

func entries_for(tab_index:int) -> Array:
	if tab_index<0 or tab_index>=category_ids.size():
		return []
	var result:Array=[]
	for item:Dictionary in CodexSystem.entries():
		if str(item.get("category",""))==category_ids[tab_index]:
			result.append(item)
	return result

func refresh() -> void:
	title_label.text=LocalizationManager.get_string("codex.title")
	progress_label.text=CodexSystem.progress_text()
	close_button.text=LocalizationManager.get_string("ui.close")
	for tab_index:int in category_ids.size():
		var category_id:String=category_ids[tab_index]
		tabs.set_tab_title(tab_index,CodexSystem.category_title(category_id))
		headers[tab_index].text=CodexSystem.category_title(category_id)+"  ·  "+CodexSystem.progress_text(category_id)
		var list:ItemList=lists[tab_index]
		var selected:int=list.get_selected_items()[0] if not list.get_selected_items().is_empty() else 0
		list.clear()
		for item:Dictionary in entries_for(tab_index):
			var unlocked:bool=CodexSystem.is_unlocked(str(item.get("id","")))
			var label:String=CodexSystem.entry_title(item) if unlocked else LOCKED_LABEL
			# The list owns the row; selection is restored below.
			@warning_ignore("return_value_discarded")
			list.add_item(label)
			list.set_item_disabled(list.item_count-1,not unlocked)
		if list.item_count>0:
			var clamped:int=clampi(selected,0,list.item_count-1)
			list.select(clamped)
			show_entry(tab_index,clamped)
		else:
			bodies[tab_index].text=""

func show_entry(tab_index:int,item_index:int) -> void:
	if tab_index<0 or tab_index>=bodies.size():
		return
	var entries:Array=entries_for(tab_index)
	if item_index<0 or item_index>=entries.size():
		bodies[tab_index].text=""
		return
	var item:Dictionary=entries[item_index]
	var unlocked:bool=CodexSystem.is_unlocked(str(item.get("id","")))
	var body:RichTextLabel=bodies[tab_index]
	if not unlocked:
		body.text="[b]"+LOCKED_LABEL+"[/b]\n\n"+LocalizationManager.get_string("codex.locked_body")
		return
	body.text="[font_size=32][b]"+CodexSystem.entry_title(item)+"[/b][/font_size]\n\n"+CodexSystem.entry_body(item)

func focus_first() -> void:
	if not lists.is_empty() and lists[0].item_count>0:
		lists[0].grab_focus()
	else:
		(find_child("CloseCodex",true,false) as Button).grab_focus()

func _unhandled_key_input(event:InputEvent) -> void:
	# A hidden journal must stay out of the key path; other world panels own Escape then.
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
