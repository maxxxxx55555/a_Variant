extends Control

signal town_selected(id:String)
var selected:String="greenhaven"
var legend:HBoxContainer
const SYMBOLS:=["●","━","◆","▲"]
const LEGEND_KEYS:=["map.town","map.road","map.explored","map.player"]
const LEGEND_COLORS:=[Color("d7bc81"),Color("747561"),Color("a6b294"),Color("e7efed")]
func _ready() -> void:
	custom_minimum_size=Vector2(650,480)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	focus_mode=Control.FOCUS_ALL
	CampaignSystem.changed.connect(queue_redraw)
	focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
	resized.connect(place_legend)
	EventBus.language_changed.connect(func(_language):refresh_copy())
	legend=HBoxContainer.new()
	legend.mouse_filter=Control.MOUSE_FILTER_IGNORE
	legend.add_theme_constant_override("separation",24)
	add_child(legend)
	for index in 4:
		var label:=Label.new()
		label.add_theme_font_size_override("font_size",24)
		label.add_theme_color_override("font_color",LEGEND_COLORS[index])
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		legend.add_child(label)
	refresh_copy();place_legend()
func refresh_copy() -> void:
	for index in 4:legend.get_child(index).text=SYMBOLS[index]+" "+LocalizationManager.get_string(LEGEND_KEYS[index])
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
	for index in 9:
		var point:float=index/8.0
		draw_line(Vector2(point*size.x,0),Vector2(point*size.x,size.y-48),Color(0.55,0.6,0.55,0.1))
		draw_line(Vector2(0,point*(size.y-48)),Vector2(size.x,point*(size.y-48)),Color(0.55,0.6,0.55,0.1))
	for link in preload("res://scripts/world/MarchRoads.gd").route_links():
		draw_line(map_position(link[0].x,link[0].y),map_position(link[1].x,link[1].y),LEGEND_COLORS[1],2)
	for point in CampaignSystem.definition.points:
		if point.id in CampaignSystem.explored:
			var at:=map_position(point.x,point.z)
			draw_colored_polygon(PackedVector2Array([at+Vector2(0,-4),at+Vector2(4,0),at+Vector2(0,4),at+Vector2(-4,0)]),LEGEND_COLORS[2])
	var font:Font=load("res://assets/fonts/GolosText.ttf")
	for data in CampaignSystem.definition.towns:
		var point:=map_position(data.x,data.z)
		var color:=LEGEND_COLORS[0] if data.id in CampaignSystem.roads else Color("9aa8a8")
		draw_circle(point,6,color)
		if data.id==selected:draw_arc(point,10,0,TAU,24,Color("e7d5a4"),2)
		var title:String=LocalizationManager.get_string(data.name)
		var width:float=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
		var at:=Vector2(clampf(point.x+10,8,maxf(8,size.x-width-8)),clampf(point.y-10,24,size.y-64))
		draw_string_outline(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,3,Color("273438"))
		draw_string(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,color)
	var players:=get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var position:Vector3=players[0].global_position
		var at:=map_position(position.x,position.z)
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(5,5),at+Vector2(-5,5)]),LEGEND_COLORS[3])
	if has_focus():draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("b6c2c5"),false,2)
func _gui_input(event:InputEvent) -> void:
	var towns:Array=CampaignSystem.definition.towns
	if event is InputEventKey and event.pressed and not event.echo:
		var index:=0
		for i in towns.size():
			if towns[i].id==selected:index=i;break
		if event.keycode in [KEY_LEFT,KEY_UP]:selected=towns[posmod(index-1,towns.size())].id
		elif event.keycode in [KEY_RIGHT,KEY_DOWN]:selected=towns[(index+1)%towns.size()].id
		elif event.is_action_pressed("ui_accept"):town_selected.emit(selected)
		else:return
		accept_event();queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		grab_focus()
		var nearest:float=45
		var chosen:String=""
		for data in towns:
			var distance:float=event.position.distance_to(map_position(data.x,data.z))
			if distance<nearest:chosen=data.id;nearest=distance
		if not chosen.is_empty():selected=chosen;town_selected.emit(selected);queue_redraw()
