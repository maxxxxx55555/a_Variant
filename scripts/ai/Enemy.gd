extends CharacterBody3D

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

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	current_hp = max_hp
	var old_mesh := get_node_or_null("MeshInstance3D")
	if old_mesh: old_mesh.hide()
	visual = MarchArt.humanoid(self, Color("824e3f"), max_hp > 120)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if home_position == Vector3.INF: home_position = global_position

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not is_instance_valid(target_player) or target_player.is_queued_for_deletion():
		target_player = null
	elif global_position.distance_to(target_player.global_position) > detection_range * 3 or (not target_player.is_in_group("player") and not target_player.is_in_group("allies")):
		target_player = null
		windup = 0
	var nearest: float = detection_range
	for candidate in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("allies"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest:
			nearest = distance
			target_player = candidate
	if windup > 0:
		windup -= delta
		if windup <= 0 and is_instance_valid(target_player) and global_position.distance_to(target_player.global_position) <= attack_range + 0.45:
			target_player.take_damage(damage)
			AudioManager.play_at("swing", global_position)

	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= attack_range:
			if attack_cooldown <= 0:
				attack_player()
		else:
			if nav_agent and NavigationServer3D.map_get_iteration_id(nav_agent.get_navigation_map()) > 0:
				nav_agent.target_position = target_player.global_position
				if not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					var dir = (next_pos - global_position).normalized()
					velocity.x = dir.x * move_speed
					velocity.z = dir.z * move_speed
			if not nav_agent or nav_agent.is_navigation_finished():
				var dir = (target_player.global_position - global_position).normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
		if dist <= attack_range:
			velocity.x = 0
			velocity.z = 0
		var face := target_player.global_position
		face.y = global_position.y
		if face.distance_squared_to(global_position) > 0.01:
			look_at(face)
	else:
		velocity.x = 0
		velocity.z = 0
		var home_direction := home_position - global_position
		home_direction.y = 0
		if home_direction.length() > 1:
			velocity.x = home_direction.normalized().x * move_speed
			velocity.z = home_direction.normalized().z * move_speed
	velocity.y -= 9.8 * delta
	move_and_slide()
	walk_phase += delta * velocity.length() * 2
	if visual:
		visual.rotation.z = sin(walk_phase) * 0.035
		visual.rotation.x = -0.22 if windup > 0 else 0.0

func attack_player() -> void:
	attack_cooldown = 1.5
	windup = 0.35

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	AudioManager.play_at("enemy_hurt", global_position)
	EventBus.enemy_damaged.emit(self, amount, current_hp, max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	AudioManager.play_at("enemy_death", global_position)
	EventBus.enemy_died.emit(self)
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.enemy_slain"), false)
	queue_free()
