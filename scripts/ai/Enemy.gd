extends CharacterBody3D
const HitSparkScene=preload("res://scripts/vfx/HitSpark.gd")

@export var max_hp: float = 80.0
@export var damage: float = 12.0
@export var attack_range: float = 1.8
@export var move_speed: float = 3.0
@export var detection_range: float = 10.0

var current_hp: float = 80.0
var target_player: Node3D = null
var is_dead: bool = false
var attack_cooldown: float = 0.0
var visual: Node3D
var windup: float = 0.0
var walk_phase: float = 0.0
var home_position: Vector3 = Vector3.INF
var flash_time: float = 0.0
var flash_material: StandardMaterial3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	current_hp = max_hp
	var old_mesh:Node3D=get_node_or_null("MeshInstance3D") as Node3D
	if old_mesh: old_mesh.hide()
	visual = MarchArt.humanoid(self, Color("824e3f"), max_hp > 120)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if flash_time > 0.0:
		flash_time = maxf(0.0, flash_time - delta)
		if flash_time <= 0.0:
			_set_overlay(null)
	if home_position == Vector3.INF: home_position = global_position

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_instance_valid(target_player) or target_player.is_queued_for_deletion():
		target_player = null
	elif global_position.distance_to(target_player.global_position) > detection_range * 3 or (not target_player.is_in_group("player") and not target_player.is_in_group("allies")):
		target_player = null
		windup = 0
	var nearest: float = detection_range
	for candidate:Node3D in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("allies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var distance:float= global_position.distance_to(candidate.global_position)
		if distance < nearest and preload("res://scripts/characters/CombatSight.gd").clear(self, candidate):
			nearest = distance
			target_player = candidate
	if windup > 0:
		windup -= delta
		if windup <= 0 and is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= attack_range + 0.45 and preload("res://scripts/characters/CombatSight.gd").clear(self, target_player):
			# Player, SoldierActor and CompanionActor share this group-owned damage contract.
			@warning_ignore("return_value_discarded")
			target_player.call("take_damage",damage)
			# AudioManager owns and recycles the spatial voice.
			@warning_ignore("return_value_discarded")
			AudioManager.play_at("swing", global_position)

	if target_player:
		var dist:float= global_position.distance_to(target_player.global_position)
		if dist <= attack_range:
			if attack_cooldown <= 0:
				attack_player()
		else:
			if nav_agent and NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) > 0:
				nav_agent.target_position = target_player.global_position
				if not nav_agent.is_navigation_finished():
					var next_pos:Vector3= nav_agent.get_next_path_position()
					var dir:Vector3= (next_pos - global_position).normalized()
					velocity.x = dir.x * move_speed
					velocity.z = dir.z * move_speed
			if not nav_agent or nav_agent.is_navigation_finished():
				var dir:Vector3= (target_player.global_position - global_position).normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
		if dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
		var face:Vector3= target_player.global_position
		face.y = global_position.y
		if face.distance_squared_to(global_position) > 0.01:
			look_at(face)
	else:
		velocity.x = 0
		velocity.z = 0
		var home_direction:Vector3= home_position - global_position
		home_direction.y = 0
		if home_direction.length() > 1:
			velocity.x = home_direction.normalized().x * move_speed
			velocity.z = home_direction.normalized().z * move_speed
	velocity.y -= 9.8 * delta
	# Collision state is read through the body API; this caller does not branch on the summary bool.
	@warning_ignore("return_value_discarded")
	move_and_slide()
	walk_phase += delta * velocity.length() * 2
	if visual:
		MarchArt.animate_walk(visual,walk_phase,minf(0.5,Vector2(velocity.x,velocity.z).length()*0.12),Vector2(get_real_velocity().x,get_real_velocity().z).length())
		visual.rotation.z = sin(walk_phase) * 0.035
		visual.rotation.x = -0.22 if windup > 0 else 0.0

func attack_player() -> void:
	MarchArt.animate_attack(visual)
	attack_cooldown = 1.5
	windup = 0.35

func hit_impact(source_point: Vector3) -> void:
	if is_dead:
		return
	var center: Vector3 = global_position + Vector3.UP
	var direction: Vector3 = center - source_point
	if direction.length_squared() < 0.01:
		direction = -global_transform.basis.z
	var spark: Node3D = HitSparkScene.new()
	var spark_parent: Node = get_parent() if get_parent() else self
	spark_parent.add_child(spark)
	spark.global_position = center + direction.normalized() * 0.2
	# HitSpark owns its burst motion; spawn arguments are passed through one guarded call.
	@warning_ignore("return_value_discarded")
	spark.call("setup", direction, Color("ffd9a0"))
	flash_time = 0.12
	_set_overlay(_flash_material())

func _flash_material() -> StandardMaterial3D:
	if flash_material == null:
		flash_material = StandardMaterial3D.new()
		flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		flash_material.albedo_color = Color(1.0, 0.94, 0.84, 0.38)
	return flash_material

func _set_overlay(material: Material) -> void:
	if visual == null:
		return
	for node: Node in visual.find_children("*", "MeshInstance3D", true, false):
		node.set("material_overlay", material)

func take_damage(amount: float) -> void:
	if is_dead or not is_finite(amount) or amount<=0:
		return
	current_hp -= amount
	# AudioManager owns and recycles the spatial voice.
	@warning_ignore("return_value_discarded")
	AudioManager.play_at("enemy_hurt", global_position)
	EventBus.enemy_damaged.emit(self, amount, current_hp, max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	if is_dead:return
	is_dead = true
	# AudioManager owns and recycles the spatial voice.
	@warning_ignore("return_value_discarded")
	AudioManager.play_at("enemy_death", global_position)
	EventBus.enemy_died.emit(self)
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.enemy_slain"), false)
	queue_free()
