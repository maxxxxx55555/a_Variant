extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)
func run() -> void:
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	for armored in [false,true]:
		var actor := MarchArt.humanoid(stage,Color("668179"),armored,true)
		var triangles := 0
		var textured := 0
		for part in actor.find_children("*","MeshInstance3D",true,false):
			if not part.is_visible_in_tree(): continue
			for surface in part.mesh.get_surface_count():
				triangles += int(part.mesh.surface_get_array_index_len(surface)/3)
				var mat: Material = part.get_active_material(surface)
				if mat is StandardMaterial3D and mat.normal_enabled and mat.normal_texture!=null: textured+=1
		check(triangles>12000,"Visible character has detailed clothing/head geometry (observed "+str(triangles)+" triangles)")
		check(textured>=2,"Character uses actual normal-mapped surfaces")
		var skeleton: Skeleton3D = actor.find_child("Skeleton3D",true,false)
		check(skeleton!=null and skeleton.find_bone("hand_r")>=0,"Detailed rig retains a humanoid hand attachment")
		var player: AnimationPlayer = actor.find_child("AnimationPlayer",true,false)
		check(player!=null and player.has_animation("Idle") and player.has_animation("Walking_A"),"Detailed figure retains idle and walking")
		check(actor.has_method("attack") and player!=null and player.has_animation("Attack"),"Detailed figure has an actual one-shot combat animation")
		if skeleton!=null and player!=null and skeleton.find_bone("thigh_l")>=0:
			MarchArt.animate_walk(actor,0.5,0.7)
			player.advance(0.15)
			var before := skeleton.get_bone_pose_rotation(skeleton.find_bone("thigh_l"))
			player.advance(0.35)
			check(not before.is_equal_approx(skeleton.get_bone_pose_rotation(skeleton.find_bone("thigh_l"))),"Walking actually deforms the new rig")
		if actor.has_method("attack"):
			actor.attack()
			MarchArt.animate_walk(actor,1.0,0.5)
			check(player.current_animation=="Attack","Locomotion cannot cancel the attack pose immediately")
		actor.queue_free()
		await process_frame
		await process_frame
	print("DETAILED FIGURES RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
