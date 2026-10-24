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

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	current_hp = max_hp

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			if global_position.distance_to(p.global_position) <= detection_range:
				target_player = p

	if target_player:
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= attack_range:
			if attack_cooldown <= 0:
				attack_player()
		else:
			if nav_agent:
				nav_agent.target_position = target_player.global_position
				if not nav_agent.is_navigation_finished():
					var next_pos = nav_agent.get_next_path_position()
					var dir = (next_pos - global_position).normalized()
					velocity.x = dir.x * move_speed
					velocity.z = dir.z * move_speed
					move_and_slide()
			else:
				var dir = (target_player.global_position - global_position).normalized()
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
				move_and_slide()

func attack_player() -> void:
	attack_cooldown = 1.5
	if target_player and target_player.has_method("take_damage"):
		target_player.take_damage(damage)
		if AudioManager: AudioManager.play_sound("attack")

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	if AudioManager: AudioManager.play_sound("enemy_hurt")
	EventBus.enemy_damaged.emit(self, amount, current_hp, max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	if AudioManager: AudioManager.play_sound("enemy_death")
	EventBus.enemy_died.emit(self)
	EventBus.notification_posted.emit(LocalizationManager.get_string("msg.enemy_slain"), false)
	queue_free()
