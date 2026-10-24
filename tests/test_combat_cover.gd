extends SceneTree

class Target extends CharacterBody3D:
	var health: float = 100
	func take_damage(amount: float) -> void: health -= amount

func _initialize() -> void: call_deferred("run")

func run() -> void:
	await process_frame
	var stage := Node3D.new()
	root.add_child(stage)
	var enemy: Node3D = load("res://scenes/enemies/enemy.tscn").instantiate()
	stage.add_child(enemy)
	enemy.set_physics_process(false)
	var target := Target.new()
	target.add_to_group("player")
	stage.add_child(target)
	target.position = Vector3(0, 0, -1.5)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 1.8, 0.5)
	collider.shape = shape
	collider.position.y = 0.9
	target.add_child(collider)
	var wall := StaticBody3D.new()
	stage.add_child(wall)
	wall.position = Vector3(0, 0.9, -0.75)
	var wall_collider := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(3, 2, 0.15)
	wall_collider.shape = wall_shape
	wall.add_child(wall_collider)
	await physics_frame
	await physics_frame
	enemy.target_player = target
	enemy.windup = 0.1
	enemy.attack_cooldown = 2
	enemy._physics_process(0.2)
	var blocked: bool = target.health == 100
	if not blocked: print("FAIL: A solid wall must block an already winding-up enemy strike")
	wall.queue_free()
	await physics_frame
	await physics_frame
	enemy.windup = 0.1
	enemy._physics_process(0.2)
	var exposed: bool = target.health < 100
	if not exposed: print("FAIL: An unobstructed enemy strike must still deal damage")
	print("COMBAT COVER RESULT: ", "PASS" if blocked and exposed else "FAIL")
	quit(0 if blocked and exposed else 1)
