extends CharacterBody3D
const WeaponView=preload("res://scripts/characters/WeaponView.gd")

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var gravity: float = 9.8

@onready var camera: Camera3D = $Camera3D
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay

var bob_time: float = 0.0
var original_cam_y: float = 0.0
var last_prompt: String = ""
var shake_offset: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0
var footstep_distance: float = 0.0
var weapon_view:WeaponView

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		original_cam_y = camera.position.y
		weapon_view = preload("res://scripts/characters/WeaponView.gd").new()
		camera.add_child(weapon_view)

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		var sens:float= SettingsManager.mouse_sensitivity
		rotate_y(-(event as InputEventMouseMotion).relative.x * sens)
		if camera:
			camera.rotate_x(-(event as InputEventMouseMotion).relative.y * sens)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func _physics_process(delta: float) -> void:
	# Pause handling
	if get_tree().paused or GameState.player_hp <= 0:
		return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	if global_position.y < -15:
		global_position = Vector3(0, 1, 5)
		velocity = Vector3.ZERO

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if GameState.consume_stamina(15.0):
			velocity.y = jump_velocity

	# Movement & Sprinting
	var is_sprinting:bool= Input.is_action_pressed("sprint") and GameState.player_stamina > 5.0
	var speed_mod:float= GameState.get_speed_modifier()
	var current_speed:float= (sprint_speed if is_sprinting else speed) * speed_mod

	var input_dir:Vector2= Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction:Vector3= (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if is_sprinting:
			# Sprint input is re-evaluated each frame against the remaining stamina.
			@warning_ignore("return_value_discarded")
			GameState.consume_stamina(10.0*delta)
		else:
			GameState.restore_stamina(15.0 * delta)
	else:
		brake_horizontal(delta, current_speed)
		GameState.restore_stamina(20.0 * delta)

	var previous_position:Vector3= global_position
	# Collision state is read through the body API; this caller does not branch on the summary bool.
	@warning_ignore("return_value_discarded")
	move_and_slide()
	if is_on_floor() and direction.length() > 0.1:
		footstep_distance += Vector2(global_position.x - previous_position.x, global_position.z - previous_position.z).length()
		if footstep_distance >= (1.8 if is_sprinting else 1.45):
			footstep_distance = 0
			var surface:String= "grass"
			if get_slide_collision_count() > 0:
				var floor_body:Object= get_slide_collision(0).get_collider()
				if floor_body:
					surface = str(floor_body.get_meta("surface", "grass"))
			AudioManager.play_footstep(surface, global_position)

	# Camera Bobbing & Shake Recovery
	shake_offset = shake_offset.move_toward(Vector3.ZERO, delta * 2.0)

	var target_y:float= original_cam_y
	if SettingsManager.camera_bobbing and is_on_floor() and direction:
		bob_time += delta * (12.0 if is_sprinting else 8.0)
		target_y += sin(bob_time) * (0.08 if is_sprinting else 0.04)
	else:
		bob_time = 0.0

	camera.position = Vector3(shake_offset.x, target_y + shake_offset.y, shake_offset.z)

	# Interaction Ray
	check_interaction()

	# Quick Potion
	if Input.is_action_just_pressed("quick_potion"):
		use_quick_potion()

	# Attack
	if Input.is_action_just_pressed("attack"):
		perform_attack()

func brake_horizontal(delta: float, current_speed: float) -> void:
	var amount:float= maxf(24.0, current_speed * 8.0) * delta
	velocity.x = move_toward(velocity.x, 0, amount)
	velocity.z = move_toward(velocity.z, 0, amount)

func take_damage(amount: float) -> void:
	if GameState.player_hp<=0 or not is_finite(amount) or amount<=0:return
	if Input.is_action_pressed("block") and GameState.consume_stamina(8.0):
		amount *= 0.3
		# AudioManager owns and recycles the spatial voice.
		@warning_ignore("return_value_discarded")
		AudioManager.play_at("block", global_position)
	else:
		# AudioManager owns and recycles the spatial voice.
		@warning_ignore("return_value_discarded")
		AudioManager.play_at("hit", global_position)
	GameState.take_damage(amount)

func check_interaction() -> void:
	if interact_ray and interact_ray.is_colliding():
		var collider:Object= interact_ray.get_collider()
		if collider and collider.has_method("get_interaction_prompt"):
			var prompt:String=collider.call("get_interaction_prompt")
			if prompt != last_prompt:
				EventBus.notification_posted.emit(prompt, false)
				last_prompt = prompt
			if Input.is_action_just_pressed("interact"):
				interact()
	else:
		last_prompt = ""

func interact() -> void:
	if get_tree().paused or GameState.player_hp <= 0:
		return
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var collider:Object= interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			# WorldItem/MarchMarker interaction is guarded by has_method above.
			@warning_ignore("return_value_discarded")
			collider.call("interact",self)
			last_prompt = ""

func use_quick_potion() -> void:
	for i:int in range(GameState.inventory.size()):
		var item:Dictionary=GameState.inventory[i]
		var path:String=item.get("resource_path", "")
		if not path.is_empty():
			var res:PotionData=load(path) as PotionData
			if res and (res.heal_amount > 0 or res.stamina_amount > 0 or res.id == "stamina_potion"):
				if GameState.use_potion(i):
					return

func perform_attack() -> void:
	if attack_cooldown > 0 or GameState.player_hp <= 0 or get_tree().paused:
		return
	var weapon:Dictionary={}
	if GameState.equipment.weapon!=null:weapon=GameState.equipment.weapon
	var stamina_cost:float= 12.0
	var dmg:float= 15.0
	var reach:float= 2.0
	var attacks_per_second: float = 1.5

	if weapon and weapon.get("resource_path"):
		var weapon_path:String=weapon.get("resource_path")
		var w_res:WeaponData=load(weapon_path) as WeaponData
		if w_res:
			stamina_cost = w_res.get("stamina_cost")
			dmg = w_res.get("damage")
			reach = w_res.get("reach")
			attacks_per_second = w_res.get("speed")
			if "hunter_bow" in w_res.id: reach *= WeatherSystem.archery_range_modifier
			if weapon.get("durability", w_res.durability) <= 0:
				dmg *= 0.5

	dmg *= GameState.get_damage_modifier()

	if GameState.consume_stamina(stamina_cost):
		if weapon_view: weapon_view.attack()
		GameState.wear_equipment("weapon", 1.0)
		attack_cooldown = 1.0 / maxf(0.1, attacks_per_second)
		apply_camera_shake(0.05)
		# AudioManager owns and recycles the spatial voice.
		@warning_ignore("return_value_discarded")
		AudioManager.play_at("swing", global_position)
		# Melee raycast
		var space_state:PhysicsDirectSpaceState3D= get_world_3d().direct_space_state
		var origin:Vector3= camera.global_position
		var end:Vector3= origin - camera.global_transform.basis.z * reach
		var query:PhysicsRayQueryParameters3D= PhysicsRayQueryParameters3D.create(origin, end, 0xFFFFFFFF, [self.get_rid()])
		var result:Dictionary= space_state.intersect_ray(query)
		if result and result.collider:
			var collider:Object=result.collider
			var hit_position:Vector3=result.position
			if collider.has_method("take_damage"):
				# AudioManager owns and recycles the spatial voice.
				@warning_ignore("return_value_discarded")
				AudioManager.play_at("hit_flesh",hit_position)
				# Combat actors and siege gates share the raycast damage contract.
				@warning_ignore("return_value_discarded")
				collider.call("take_damage",dmg)

func apply_camera_shake(intensity: float) -> void:
	if SettingsManager.camera_shake:
		shake_offset += Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), 0)
