extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures+=1;print("FAIL: ",message)
func scan(screen:Node) -> void:
	for node in screen.find_children("*","BaseButton",true,false):
		if node.disabled:check(not node.tooltip_text.strip_edges().is_empty(),"Disabled action explains its requirement: "+str(node.get_path()))
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1,false)
	var screen:Node=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(screen);current_scene=screen
	await process_frame
	scan(screen)
	screen.town_ui.open("greenhaven")
	await process_frame
	scan(screen)
	print("DISABLED EXPLANATIONS RESULT: ","PASS" if failures==0 else "FAIL")
	paused=false
	quit(0 if failures==0 else 1)
