extends CharacterBody3D

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
var weapon_view: Node3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if camera:
		original_cam_y = camera.position.y
		weapon_view = preload("res://scripts/characters/WeaponView.gd").new()
		camera.add_child(weapon_view)

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		var sens = SettingsManager.mouse_sensitivity
		rotate_y(-event.relative.x * sens)
		if camera:
			camera.rotate_x(-event.relative.y * sens)
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
	var is_sprinting = Input.is_action_pressed("sprint") and GameState.player_stamina > 5.0
	var speed_mod = GameState.get_speed_modifier()
	var current_speed = (sprint_speed if is_sprinting else speed) * speed_mod

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if is_sprinting:
			GameState.consume_stamina(10.0 * delta)
		else:
			GameState.restore_stamina(15.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		GameState.restore_stamina(20.0 * delta)

	var previous_position := global_position
	move_and_slide()
	if is_on_floor() and direction.length() > 0.1:
		footstep_distance += Vector2(global_position.x - previous_position.x, global_position.z - previous_position.z).length()
		if footstep_distance >= (1.8 if is_sprinting else 1.45):
			footstep_distance = 0
			var surface := "grass"
			if get_slide_collision_count() > 0:
				var floor_body = get_slide_collision(0).get_collider()
				if floor_body:
					surface = str(floor_body.get_meta("surface", "grass"))
			AudioManager.play_footstep(surface, global_position)

	# Camera Bobbing & Shake Recovery
	shake_offset = shake_offset.move_toward(Vector3.ZERO, delta * 2.0)

	var target_y = original_cam_y
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

func take_damage(amount: float) -> void:
	if Input.is_action_pressed("block") and GameState.consume_stamina(8.0):
		amount *= 0.3
		AudioManager.play_at("block", global_position)
	else:
		AudioManager.play_at("hit", global_position)
	GameState.take_damage(amount)

func check_interaction() -> void:
	if interact_ray and interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider and collider.has_method("get_interaction_prompt"):
			var prompt = collider.get_interaction_prompt()
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
		var collider = interact_ray.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact(self)
			last_prompt = ""

func use_quick_potion() -> void:
	for i in range(GameState.inventory.size()):
		var item = GameState.inventory[i]
		var path = item.get("resource_path", "")
		if not path.is_empty():
			var res = load(path)
			if res is PotionData and (res.heal_amount > 0 or res.stamina_amount > 0 or res.id == "stamina_potion"):
				if GameState.use_potion(i):
					return

func perform_attack() -> void:
	if attack_cooldown > 0 or GameState.player_hp <= 0 or get_tree().paused:
		return
	var weapon = GameState.equipment.get("weapon")
	var stamina_cost = 12.0
	var dmg = 15.0
	var reach = 2.0
	var attacks_per_second: float = 1.5

	if weapon and weapon.get("resource_path"):
		var w_res = load(weapon.get("resource_path"))
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
		AudioManager.play_at("swing", global_position)
		# Melee raycast
		var space_state = get_world_3d().direct_space_state
		var origin = camera.global_position
		var end = origin - camera.global_transform.basis.z * reach
		var query = PhysicsRayQueryParameters3D.create(origin, end, 0xFFFFFFFF, [self.get_rid()])
		var result = space_state.intersect_ray(query)
		if result and result.collider:
			if result.collider.has_method("take_damage"):
				AudioManager.play_at("hit_flesh", result.position)
				result.collider.take_damage(dmg)

func apply_camera_shake(intensity: float) -> void:
	if SettingsManager.camera_shake:
		shake_offset += Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), 0)
