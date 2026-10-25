extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1,false)
	var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
	var original:Sky=world.get_node("WorldEnvironment").environment.sky
	root.add_child(world)
	current_scene=world
	var ok:bool=world.get_node("WorldEnvironment").environment.sky==original and original.sky_material is PanoramaSkyMaterial
	for i in 3:await process_frame
	world.queue_free()
	current_scene=null
	original=null
	for i in 3:await process_frame
	print("WORLD SKY LIFETIME: ","PASS" if ok else "FAIL: preserve the scene-owned Sky while changing its material")
	quit(0 if ok else 1)
