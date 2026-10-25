extends SceneTree
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-"+name+".png"))
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").new_campaign(1,false)
	var world: Node3D = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	var town: Dictionary = root.get_node("CampaignSystem").definition.towns[0]
	world.player.position=Vector3(town.x,world.terrain.ground_at(town.x,town.z+7)+0.2,town.z+7)
	for index in 20: await physics_frame
	world.player.set_physics_process(false)
	world.player.weapon_view.hide()
	world.player.camera.fov=58
	world.player.camera.global_position=Vector3(town.x,world.terrain.ground_at(town.x,town.z+5)+1.6,town.z+7.0)
	world.player.camera.look_at(Vector3(town.x,world.terrain.ground_at(town.x,town.z+5)+1.45,town.z+5))
	for index in 8: await process_frame
	await shot("premium-reeve")
	var stage:=Node3D.new()
	world.add_child(stage)
	stage.position=Vector3(town.x+3,world.terrain.ground_at(town.x+3,town.z+5),town.z+5)
	var ranger:=MarchArt.humanoid(stage,Color("824e3f"),true,true)
	ranger.rotation.y=PI
	world.player.camera.global_position=stage.global_position+Vector3(0,1.45,2.1)
	world.player.camera.look_at(stage.global_position+Vector3(0,1.22,0))
	for index in 8: await process_frame
	await shot("premium-ranger")
	MarchArt.animate_attack(ranger)
	for index in 14: await process_frame
	await shot("premium-attack")
	stage.hide()
	var army: Node=root.get_node("ArmySystem")
	army.recruit("archers",1)
	var archer: Node3D=load("res://scripts/ai/SoldierActor.gd").new()
	archer.squad_id=army.squads[0].squad_id
	world.add_child(archer)
	archer.position=stage.position
	archer.rotation.y=PI
	archer.set_physics_process(false)
	for index in 8: await process_frame
	await shot("premium-archer")
	print("PREMIUM CHARACTER CAPTURES: PASS")
	quit()
