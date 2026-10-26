extends Control

signal town_selected(id:String)
var selected:String="greenhaven"
var legend:HBoxContainer
const SYMBOLS:Array[String]=["●","━","◆","▲"]
const LEGEND_KEYS:Array[String]=["map.town","map.road","map.explored","map.player"]
const LEGEND_COLORS:Array[Color]=[Color("d7bc81"),Color("747561"),Color("a6b294"),Color("e7efed")]
func _ready() -> void:
	custom_minimum_size=Vector2(650,480)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	focus_mode=Control.FOCUS_ALL
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.changed.connect(queue_redraw)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	resized.connect(place_legend)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:refresh_copy())
	legend=HBoxContainer.new()
	legend.mouse_filter=Control.MOUSE_FILTER_IGNORE
	legend.add_theme_constant_override("separation",24)
	add_child(legend)
	for index:int in 4:
		var label:Label=Label.new()
		label.add_theme_font_size_override("font_size",24)
		label.add_theme_color_override("font_color",LEGEND_COLORS[index])
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		legend.add_child(label)
	refresh_copy();place_legend()
func refresh_copy() -> void:
	for index:int in 4:(legend.get_child(index) as Label).text=SYMBOLS[index]+" "+LocalizationManager.get_string(LEGEND_KEYS[index])
	queue_redraw()
func place_legend() -> void:
	if not is_instance_valid(legend):return
	legend.position=Vector2(16,size.y-32)
	legend.size=Vector2(size.x-32,24)
	queue_redraw()
func map_position(x:float,z:float) -> Vector2:
	var span:float=CampaignSystem.definition.world_size
	return Vector2((x/span+0.5)*(size.x-80)+40,(z/span+0.5)*(size.y-112)+40)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("273438"))
	for index:int in 9:
		var point:float=index/8.0
		draw_line(Vector2(point*size.x,0),Vector2(point*size.x,size.y-48),Color(0.55,0.6,0.55,0.1))
		draw_line(Vector2(0,point*(size.y-48)),Vector2(size.x,point*(size.y-48)),Color(0.55,0.6,0.55,0.1))
	for link:Array in preload("res://scripts/world/MarchRoads.gd").route_links():
		var origin:Vector2=link[0]
		var destination:Vector2=link[1]
		draw_line(map_position(origin.x,origin.y),map_position(destination.x,destination.y),LEGEND_COLORS[1],2)
	for point:Dictionary in CampaignSystem.definition.points:
		if point.id in CampaignSystem.explored:
			var at:Vector2=catalog_position(point)
			draw_colored_polygon(PackedVector2Array([at+Vector2(0,-4),at+Vector2(4,0),at+Vector2(0,4),at+Vector2(-4,0)]),LEGEND_COLORS[2])
	var font:Font=load("res://assets/fonts/GolosText.ttf")
	for data:Dictionary in CampaignSystem.definition.towns:
		var point:Vector2=catalog_position(data)
		var color:Color=LEGEND_COLORS[0] if data.id in CampaignSystem.roads else Color("9aa8a8")
		draw_circle(point,6,color)
		if data.id==selected:draw_arc(point,10,0,TAU,24,Color("e7d5a4"),2)
		var title:String=LocalizationManager.get_string(str(data.name))
		var width:float=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
		var at:Vector2=Vector2(clampf(point.x+10,8,maxf(8,size.x-width-8)),clampf(point.y-10,24,size.y-64))
		draw_string_outline(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,3,Color("273438"))
		draw_string(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,color)
	var players:Array[Node]=get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player_position:Vector3=(players[0] as Node3D).global_position
		var at:Vector2=map_position(player_position.x,player_position.z)
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(5,5),at+Vector2(-5,5)]),LEGEND_COLORS[3])
	if has_focus():draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("b6c2c5"),false,2)
func _gui_input(event:InputEvent) -> void:
	var towns:Array=CampaignSystem.definition.towns
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var index:int=0
		for i:int in towns.size():
			if towns[i].id==selected:index=i;break
		if (event as InputEventKey).keycode in [KEY_LEFT,KEY_UP]:selected=towns[posmod(index-1,towns.size())].id
		elif (event as InputEventKey).keycode in [KEY_RIGHT,KEY_DOWN]:selected=towns[(index+1)%towns.size()].id
		elif event.is_action_pressed("ui_accept"):town_selected.emit(selected)
		else:return
		accept_event();queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index==MOUSE_BUTTON_LEFT:
		grab_focus()
		var nearest:float=45
		var chosen:String=""
		for data:Dictionary in towns:
			var distance:float=(event as InputEventMouseButton).position.distance_to(catalog_position(data))
			if distance<nearest:chosen=data.id;nearest=distance
		if not chosen.is_empty():selected=chosen;town_selected.emit(selected);queue_redraw()

func catalog_position(record:Dictionary)->Vector2:
	var x:float=record.x
	var z:float=record.z
	return map_position(x,z)
