extends CharacterBody3D

var squad_id: int = 0
var formation_index: int = 0
var represented_count: int = 1
var health: float = 100
var data: Resource
var attack_cooldown: float = 0
var visual: Node3D
var walk_phase: float = 0

func _ready() -> void:
	add_to_group("allies")
	collision_layer = 2
	collision_mask = 1
	data = load(ArmySystem.squad_by_id(squad_id).unit_res_path)
	health = data.health * represented_count
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.7
	shape.radius = 0.3
	collider.shape = shape
	collider.position.y = 0.85
	add_child(collider)
	visual = MarchArt.humanoid(self, Color("446879"), true)

func take_damage(amount: float) -> void:
	health -= amount * 100.0 / (100.0 + data.defense)
	AudioManager.play_at("hit_metal", global_position)
	if health <= 0:
		ArmySystem.register_casualty(squad_id, represented_count)
		queue_free()

func resize_representation(count: int) -> void:
	if count != represented_count:
		health = clampf(health + data.health * (count - represented_count), 1, data.health * count)
		represented_count = count

func _physics_process(delta: float) -> void:
	var squad := ArmySystem.squad_by_id(squad_id)
	var players := get_tree().get_nodes_in_group("player")
	if squad.is_empty() or squad.count <= 0 or players.is_empty():
		queue_free()
		return
	attack_cooldown = maxf(0, attack_cooldown - delta)
	var player: Node3D = players[0]
	var spacing: float = 3.0 if squad.formation == "loose" else 1.0 if squad.formation == "shield_wall" else 1.8
	var destination: Vector3 = player.global_position + player.global_basis * Vector3((formation_index - 1.5) * spacing, 0, 3.0 + squad_id)
	if squad.order in ["hold", "attack"]:
		var target = squad.get("target", [player.position.x, player.position.y, player.position.z])
		destination = Vector3(target[0], target[1], target[2]) + Vector3((formation_index - 1.5) * spacing, 0, 1)
	elif squad.order == "retreat":
		destination = player.global_position + player.global_basis.z * 8
	var target_enemy: Node3D
	var best_distance: float = 35 if squad.order == "attack" else 8
	if squad.order != "retreat":
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.is_dead:
				continue
			var distance := global_position.distance_to(enemy.global_position)
			if distance < best_distance:
				best_distance = distance
				target_enemy = enemy
	if is_instance_valid(target_enemy):
		if squad.order != "hold":
			destination = target_enemy.global_position
		var reach: float = data.range_distance * (WeatherSystem.archery_range_modifier if "archers" in squad.unit_res_path else 1.0)
		if best_distance <= reach and attack_cooldown <= 0 and preload("res://scripts/characters/CombatSight.gd").clear(self, target_enemy):
			attack_cooldown = 1.1
			MarchArt.animate_attack(visual)
			target_enemy.take_damage(data.damage * represented_count * (0.5 + squad.morale / 200.0))
			AudioManager.play_at("swing", global_position)
			destination = global_position
	var direction := destination - global_position
	direction.y = 0
	if direction.length() > 1.2:
		velocity.x = direction.normalized().x * data.speed
		velocity.z = direction.normalized().z * data.speed
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= 9.8 * delta
	move_and_slide()
	walk_phase += delta * Vector2(velocity.x, velocity.z).length() * 2
	MarchArt.animate_walk(visual,walk_phase,minf(0.5,Vector2(velocity.x,velocity.z).length()*0.12),Vector2(get_real_velocity().x,get_real_velocity().z).length())
