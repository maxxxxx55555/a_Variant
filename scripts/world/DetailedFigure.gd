extends Node3D
## Licensed modular graphics. Damage, movement, collision and saves stay on the actor.
static var templates := {}
static var libraries := {}
static var fabrics := {}
var animator: AnimationPlayer
var scan_time := 0.0

static func template(name: String) -> PackedScene:
	if not templates.has(name):
		templates[name] = load("res://assets/art/humans/"+name+(".glb" if name=="Animations" else ".gltf"))
	return templates[name]

static func merge_part(skeleton: Skeleton3D, name: String) -> void:
	var part: Node3D = template(name).instantiate()
	for mesh in part.find_children("*","MeshInstance3D",true,false):
		mesh.set_meta("part_id",name)
		mesh.owner = null
		mesh.get_parent().remove_child(mesh)
		skeleton.add_child(mesh)
		mesh.skeleton = NodePath("..")
	part.free()

static func clips(sex: String, armed: bool, target: Skeleton3D, ranged: bool = false) -> AnimationLibrary:
	var key := sex+str(armed)+str(ranged)
	if libraries.has(key): return libraries[key]
	var source: Node3D = template("Animations").instantiate()
	var source_skeleton := source.find_child("Skeleton3D",true,false) as Skeleton3D
	var player := source.find_child("AnimationPlayer",true,false) as AnimationPlayer
	var library := AnimationLibrary.new()
	var aliases := {"Idle":"Sword_Idle" if armed else "Idle","Walking_A":"Walk","Jogging_A":"Jog_Fwd","Running_A":"Sprint","Attack":"Sword_Attack"}
	if ranged:
		aliases.Idle="Pistol_Idle"
		aliases.Attack="Pistol_Shoot"
	for alias in aliases:
		var animation := player.get_animation(aliases[alias]).duplicate(true) as Animation
		animation.loop_mode = Animation.LOOP_NONE if alias=="Attack" else Animation.LOOP_LINEAR
		for track in range(animation.get_track_count()-1,-1,-1):
			var path := animation.track_get_path(track)
			var bone := str(path.get_subname(0)) if path.get_subname_count()>0 else ""
			var destination := target.find_bone(bone)
			var origin := source_skeleton.find_bone(bone)
			if destination<0 or origin<0:
				animation.remove_track(track)
				continue
			var from := source_skeleton.get_bone_rest(origin)
			var to := target.get_bone_rest(destination)
			for frame in animation.track_get_key_count(track):
				var value: Variant = animation.track_get_key_value(track,frame)
				if animation.track_get_type(track)==Animation.TYPE_POSITION_3D:
					animation.track_set_key_value(track,frame,value+to.origin-from.origin)
				elif animation.track_get_type(track)==Animation.TYPE_ROTATION_3D:
					animation.track_set_key_value(track,frame,to.basis.get_rotation_quaternion()*from.basis.get_rotation_quaternion().inverse()*value)
		library.add_animation(alias,animation)
	source.free()
	libraries[key] = library
	return library

static func build(parent: Node3D, armored: bool, armed: bool, tint: Color) -> Node3D:
	var wrapper: Node3D = load("res://scripts/world/DetailedFigure.gd").new()
	wrapper.name = "MarchFigure"
	parent.add_child(wrapper)
	var seed: int = hash(str(tint)+str(parent.get_meta("campaign_id",""))+str(parent.get("companion_id"))+str(parent.get("occupation")))
	var sex := "Female" if posmod(seed,3)==1 else "Male"
	var unit: Variant=parent.get("data")
	var ranged: bool=parent.get("companion_id")=="archer_scout" or (unit is Resource and "archers" in unit.resource_path)
	var model: Node3D = template(sex+("_Ranger" if armed or armored else "_Peasant")).instantiate()
	model.name = "CharacterModel"
	model.rotation.y = PI
	wrapper.add_child(model)
	var skeleton := model.find_child("Skeleton3D",true,false) as Skeleton3D
	merge_part(skeleton,"Head_"+sex)
	merge_part(skeleton,"Hair_Buzzed" if armed or armored else "Hair_Buns" if sex=="Female" else "Hair_SimpleParted")
	if sex=="Male" and posmod(seed,2)==0: merge_part(skeleton,"Hair_Beard")
	for part in model.find_children("*","MeshInstance3D",true,false):
		part.visibility_range_end = 120
		part.visibility_range_end_margin = 18
		for surface in part.mesh.get_surface_count():
			var original: Material = part.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D: continue
			if str(part.get_meta("part_id","")).begins_with("Hair_") or "Eyebrows" in part.name:
				var hair_key := original.resource_path+"hair"+str(posmod(seed,3))
				if not fabrics.has(hair_key):
					var hair := original.duplicate() as StandardMaterial3D
					hair.albedo_color = [Color("30251f"),Color("5c4130"),Color("61554b")][posmod(seed,3)]
					hair.roughness = 0.68
					fabrics[hair_key] = hair
				part.set_surface_override_material(surface,fabrics[hair_key])
				continue
			var cloth: bool = original.albedo_texture!=null and ("Ranger" in original.albedo_texture.resource_path or "Peasant" in original.albedo_texture.resource_path)
			if not cloth: continue
			var key := original.resource_path+str(tint)+str(armored)+str("Pauldron" in part.name or "Bracer" in part.name)
			if not fabrics.has(key):
				var material := original.duplicate() as StandardMaterial3D
				material.albedo_color = tint.lerp(Color.WHITE,0.78)
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if armored and ("Pauldron" in part.name or "Bracer" in part.name):
					material.metallic = 0.55
					material.roughness = 0.48
				fabrics[key] = material
			part.set_surface_override_material(surface,fabrics[key])
	var animation := AnimationPlayer.new()
	animation.name = "AnimationPlayer"
	model.add_child(animation)
	animation.add_animation_library("",clips(sex,armed,skeleton,ranged))
	animation.play("Idle")
	# Establish the pose before distance culling or a paused first frame.
	animation.advance(0.0)
	wrapper.animator = animation
	wrapper.set_meta("animation_player",animation)
	if armed:
		var hand := BoneAttachment3D.new()
		hand.bone_name = "hand_r"
		skeleton.add_child(hand)
		var weapon: MeshInstance3D
		if ranged:
			weapon=MeshInstance3D.new()
			weapon.mesh=preload("res://scripts/world/DetailedWeapons.gd").crossbow()
			hand.add_child(weapon)
			weapon.basis=Basis(Vector3.LEFT,Vector3.BACK,Vector3.UP)
			weapon.position=Vector3(0,0.035,0.10)
		else:
			weapon=MarchAssets.place(hand,"weapons/sword_1handed.gltf",Vector3(-0.09,0.08,0),Vector3(0.20,0.85,0.12))
			weapon.rotation.z = -PI/2
		weapon.name = "HeldWeapon"
	return wrapper

func attack() -> void:
	if is_instance_valid(animator):
		animator.speed_scale=1.0
		animator.play("Attack",0.08,1.7)

func _process(delta: float) -> void:
	scan_time -= delta
	if scan_time>0 or not is_instance_valid(animator): return
	scan_time = 0.5
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if is_instance_valid(player): animator.active = global_position.distance_squared_to(player.global_position)<19600
