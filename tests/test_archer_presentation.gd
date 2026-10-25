extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var army: Node=root.get_node("ArmySystem")
	var recruited: bool=army.recruit("archers",1)
	if not recruited:
		print("FAIL: Archer fixture could not recruit")
		quit(1)
		return
	var actor: Node3D=load("res://scripts/ai/SoldierActor.gd").new()
	actor.squad_id=army.squads[0].squad_id
	root.add_child(actor)
	actor.set_physics_process(false)
	for index in 8: await process_frame
	var weapon:=actor.find_child("HeldWeapon",true,false) as MeshInstance3D
	var ok: bool=weapon!=null and weapon.mesh.get_aabb().size.x>weapon.mesh.get_aabb().size.y*2
	if ok: ok=weapon.global_basis.z.normalized().dot(-actor.global_basis.z)>0.8
	print("ARCHER PRESENTATION RESULT: ","PASS" if ok else "FAIL: ranged units need a ranged weapon silhouette")
	quit(0 if ok else 1)
