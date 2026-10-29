extends Control

signal town_selected(id:String)
var selected:String="greenhaven"
var legend:HBoxContainer
var legend_labels:Array[Label]=[]
var legend_icons:Array[TextureRect]=[]
const IconView=preload("res://scripts/ui/IconSet.gd")
const LEGEND_KEYS:Array[String]=["map.town","map.road","map.explored","map.player","map.objective"]
const LEGEND_ICONS:Array[String]=["town","road","explored","player","objective"]
const LEGEND_COLORS:Array[Color]=[Color("c9a227"),Color("6a7a72"),Color("72968b"),Color("dce3e9"),Color("e8dcc3")]
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
	legend.name="MapLegend"
	legend.mouse_filter=Control.MOUSE_FILTER_IGNORE
	legend.add_theme_constant_override("separation",12)
	add_child(legend)
	for index:int in 5:
		var row:HBoxContainer=HBoxContainer.new()
		row.name="LegendRow"+str(index)
		row.add_theme_constant_override("separation",5)
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		legend.add_child(row)
		var picture:TextureRect=IconView.rect(LEGEND_ICONS[index],LEGEND_COLORS[index],Vector2(18,18),"LegendIcon"+str(index))
		row.add_child(picture)
		legend_icons.append(picture)
		var label:Label=Label.new()
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",LEGEND_COLORS[index])
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		legend_labels.append(label)
	refresh_copy();place_legend()
func legend_label(index:int) -> Label:
	return legend_labels[index]
func legend_icon(index:int) -> TextureRect:
	return legend_icons[index]
func refresh_copy() -> void:
	for index:int in 5:legend_labels[index].text=LocalizationManager.get_string(LEGEND_KEYS[index])
	queue_redraw()
func place_legend() -> void:
	if not is_instance_valid(legend):return
	legend.position=Vector2(16,size.y-34)
	legend.size=Vector2(size.x-32,26)
	queue_redraw()
func map_position(x:float,z:float) -> Vector2:
	var span:float=CampaignSystem.definition.world_size
	return Vector2((x/span+0.5)*(size.x-80)+40,(z/span+0.5)*(size.y-112)+40)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("1e242a"))
	for index:int in 9:
		var point:float=index/8.0
		draw_line(Vector2(point*size.x,0),Vector2(point*size.x,size.y-48),Color(0.45,0.5,0.47,0.12))
		draw_line(Vector2(0,point*(size.y-48)),Vector2(size.x,point*(size.y-48)),Color(0.45,0.5,0.47,0.12))
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
		draw_string_outline(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,3,Color("1e242a"))
		draw_string(font,at,title,HORIZONTAL_ALIGNMENT_LEFT,size.x-16,24,color)
	var players:Array[Node]=get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player_position:Vector3=(players[0] as Node3D).global_position
		var at:Vector2=map_position(player_position.x,player_position.z)
		draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(5,5),at+Vector2(-5,5)]),LEGEND_COLORS[3])
	var marker:Dictionary=objective_marker()
	if not marker.is_empty():
		# Marker fields are authored by objective_marker() with these exact types.
		@warning_ignore("unsafe_call_argument")
		draw_arc(marker.position,marker.radius,0,TAU,28,marker.color,3)
		@warning_ignore("unsafe_call_argument")
		draw_circle(marker.position,4,marker.color)
	if has_focus():draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("e8dcc3"),false,2)

func objective_marker() -> Dictionary:
	var objective:Dictionary=CampaignSystem.tracked_objective()
	if objective.is_empty():
		return {}
	var location:Dictionary=CampaignSystem.objective_location(objective)
	if location.is_empty():
		return {}
	return {
		"position": map_position(_coordinate(location.get("x",0.0)),_coordinate(location.get("z",0.0))),
		"color": LEGEND_COLORS[4],
		"radius": 14.0
	}

func _coordinate(value:Variant)->float:
	if value is int or value is float:
		# Campaign coordinates are validated numeric catalog fields.
		@warning_ignore("unsafe_call_argument")
		return float(value)
	return 0.0
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
