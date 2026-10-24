extends Node3D

var home: Vector3
var workplace: Vector3
var plaza: Vector3
var town_id: String
var occupation: int = 0
var visual: Node3D
var destination: Vector3
var scan_timer: float = 0
var walk_phase: float = 0
var fleeing: bool = false

func _ready() -> void:
	add_to_group("civilians")
	var colors := [Color("8d8262"), Color("668179"), Color("9b6c56")]
	visual = MarchArt.humanoid(self, colors[occupation % colors.size()], false, false)
	global_position = home
	destination = home

func schedule_target(day_fraction: float) -> Vector3:
	if day_fraction >= 0.28 and day_fraction < 0.7: return workplace
	if day_fraction >= 0.7 and day_fraction < 0.9: return plaza
	return home

func threat_destination(threat: Vector3) -> Vector3:
	var direction := global_position - threat
	direction.y = 0
	if direction.length_squared() < 0.01: direction = Vector3.RIGHT
	return global_position + direction.normalized() * 14

func _physics_process(delta: float) -> void:
	if not CampaignSystem.active: return
	scan_timer -= delta
	if scan_timer <= 0:
		scan_timer = 0.5
		var player := get_tree().get_first_node_in_group("player") as Node3D
		var nearby := is_instance_valid(player) and global_position.distance_squared_to(player.global_position) < 25600
		visible = nearby
		fleeing = false
		destination = schedule_target(fposmod(TimeSystem.game_time_seconds / TimeSystem.day_duration_seconds + 0.25, 1.0))
		if nearby:
			var closest := 14.0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy.is_dead: continue
				var distance: float = global_position.distance_to(enemy.global_position)
				if distance < closest:
					closest = distance
					destination = threat_destination(enemy.global_position)
					fleeing = true
	# Distant residents need no per-frame visual or geometry work.
	if not visible: return
	var direction := destination - global_position
	direction.y = 0
	var distance := direction.length()
	if distance > 0.25:
		var speed := 3.8 if fleeing else 1.4
		var next := global_position + direction.normalized() * minf(distance, speed * delta)
		# Probe physical architecture without making residents block the player.
		var world_space := get_world_3d().direct_space_state
		var probe := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.9, next + direction.normalized() * 0.8 + Vector3.UP * 0.9, 1)
		if world_space.intersect_ray(probe).is_empty():
			global_position = next
		else:
			var sideways := Vector3(-direction.z, 0, direction.x).normalized()
			var detour := global_position + sideways * speed * delta
			probe.to = detour + sideways * 0.8 + Vector3.UP * 0.9
			if world_space.intersect_ray(probe).is_empty(): global_position = detour
		look_at(global_position + direction)
		var world := get_tree().current_scene
		if world and world.get("terrain") != null:
			global_position.y = world.terrain.ground_at(global_position.x, global_position.z)
		walk_phase += delta * speed * 3
		MarchArt.animate_walk(visual, walk_phase, 0.55)
	else:
		MarchArt.animate_walk(visual, 0, 0)
