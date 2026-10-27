extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures+=1;print("FAIL: ",message)
func find_text(parent:Node,text:String) -> Label3D:
	for label in parent.find_children("*","Label3D",true,false):
		if label.text==text:return label
	return null
func run() -> void:
	await process_frame
	var locale:Node=root.get_node("LocalizationManager")
	locale.set_language("ru")
	root.get_node("CampaignSystem").new_campaign(1,false)
	var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world);current_scene=world
	var town:Dictionary=root.get_node("CampaignSystem").definition.towns[0]
	var home:Label3D=find_text(world,locale.get_string("ui.home"))
	var town_label:Label3D=find_text(world,locale.get_string(town.name)+" [E]")
	check(home!=null and town_label!=null,"Real home and town world labels are present")
	world.inventory_ui._on_item_selected(0)
	world.alchemy_ui._on_recipe_selected(3)
	var recipe:Resource=world.alchemy_ui.selected_recipe
	var inventory:Array=root.get_node("GameState").inventory.duplicate(true)
	var position:Vector3=world.player.position
	locale.set_language("en")
	check(home!=null and home.text==locale.get_string("ui.home"),"Home world label updates on live switch")
	check(town_label!=null and town_label.text==locale.get_string(town.name)+" [E]","Town world label updates on live switch")
	check(world.inventory_ui.selected_index==0 and not world.inventory_ui.item_card_label.text.is_empty(),"Live switch keeps the selected inventory item and refreshes its card")
	check(world.alchemy_ui.selected_recipe==recipe,"Live switch keeps the chosen recipe")
	check(inventory==root.get_node("GameState").inventory and world.player.position==position,"Localization does not mutate inventory or move the player")
	print("LIVE WORLD LOCALE RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
