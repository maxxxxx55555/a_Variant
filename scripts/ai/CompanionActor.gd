extends CharacterBody3D
const EnemyView=preload("res://scripts/ai/Enemy.gd")

var companion_id: String
var data:CompanionData
var health: float
var cooldown: float = 0
var downed_time: float = 0
var visual: Node3D
var walk_phase: float = 0

func _ready() -> void:
	add_to_group("allies")
	data=load("res://data/companions/"+companion_id+".tres") as CompanionData
	health = data.health
	collision_layer = 2
	collision_mask = 1
	var collider:CollisionShape3D= CollisionShape3D.new()
	var shape:CapsuleShape3D= CapsuleShape3D.new()
	shape.height = 1.7
	shape.radius = 0.3
	collider.shape = shape
	collider.position.y = 0.85
	add_child(collider)
	visual = MarchArt.humanoid(self, Color("7c8163"), companion_id in ["warrior_shield", "mercenary_commander"])
	# The label is parent-owned and updates through the locale signal.
	@warning_ignore("return_value_discarded")
	MarchArt.localized_label(self, "companion." + companion_id + ".name", Vector3(0, 2.3, 0))

func take_damage(amount: float) -> void:
	if downed_time > 0: return
	health -= amount * 100.0 / (100.0 + data.defense)
	if health <= 0:
		downed_time = 45
		visual.rotation.z = PI * 0.5
		remove_from_group("allies")

func _physics_process(delta: float) -> void:
	var players:Array[Node]= get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var player: Node3D = players[0]
	if downed_time > 0:
		downed_time -= delta
		if downed_time <= 0:
			health = data.health * 0.4
			visual.rotation.z = 0
			global_position = player.global_position + Vector3(3, 0, 3)
			add_to_group("allies")
		return
	cooldown -= delta
	var destination: Vector3 = player.global_position + player.global_basis * Vector3(3, 0, 3)
	var enemy_target:EnemyView
	var nearest: float = 14
	for enemy:EnemyView in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_dead: continue
		var distance:float= global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			enemy_target = enemy
	if is_instance_valid(enemy_target):
		destination = enemy_target.global_position
		var reach: float = 14.0 if companion_id=="archer_scout" else 2.2
		if nearest <= reach and cooldown <= 0 and preload("res://scripts/characters/CombatSight.gd").clear(self, enemy_target):
			cooldown = 1.25
			MarchArt.animate_attack(visual)
			enemy_target.take_damage(data.damage)
			# AudioManager owns and recycles the spatial voice.
			@warning_ignore("return_value_discarded")
			AudioManager.play_at("swing", global_position)
			destination = global_position
	elif companion_id == "healer_alchemist" and cooldown <= 0:
		cooldown = 10
		GameState.player_hp = minf(GameState.max_hp, GameState.player_hp + 5)
		EventBus.player_hp_changed.emit(GameState.player_hp, GameState.max_hp)
	var direction:Vector3= destination - global_position
	direction.y = 0
	if direction.length() > 2:
		velocity.x = direction.normalized().x * 6
		velocity.z = direction.normalized().z * 6
		if direction.length() > 50:
			global_position = player.global_position + Vector3(4, 0, 3)
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 9.8 * delta
	# Collision state is read through the body API; this caller does not branch on the summary bool.
	@warning_ignore("return_value_discarded")
	move_and_slide()
	walk_phase += delta * Vector2(velocity.x, velocity.z).length() * 2
	MarchArt.animate_walk(visual,walk_phase,minf(0.5,Vector2(velocity.x,velocity.z).length()*0.12),Vector2(get_real_velocity().x,get_real_velocity().z).length())
