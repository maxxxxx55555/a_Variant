extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1,false)
	var map:Control=load("res://scripts/ui/MarchMap.gd").new()
	root.add_child(map);map.size=Vector2(800,500)
	var towns:Array=root.get_node("CampaignSystem").definition.towns
	check(map.focus_mode==Control.FOCUS_ALL,"Atlas accepts keyboard focus")
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_RIGHT
	map._gui_input(key)
	check(map.selected==towns[1].id,"Right selects the next actual town")
	var activated:Array=[]
	map.town_selected.connect(func(id):activated.append(id))
	key.keycode=KEY_ENTER;map._gui_input(key)
	check(activated==[towns[1].id],"Enter activates exactly the selected town")
	key.keycode=KEY_LEFT;map._gui_input(key)
	check(map.selected==towns[0].id,"Left restores previous selection")
	var texts:Array=[]
	for label in map.find_children("*","Label",true,false):texts.append(label.text)
	check(texts.size()>=4,"Atlas provides a visible symbol legend")
	root.get_node("LocalizationManager").set_language("ru")
	var ru:Array=[]
	for label in map.find_children("*","Label",true,false):ru.append(label.text)
	root.get_node("LocalizationManager").set_language("en")
	var en:Array=[]
	for label in map.find_children("*","Label",true,false):en.append(label.text)
	check(ru!=en and ru.size()==en.size(),"Legend updates on live locale switch")
	check(map.selected==towns[0].id,"Locale switch preserves map selection")
	print("MAP NAVIGATION RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
