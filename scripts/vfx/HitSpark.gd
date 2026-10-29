extends Node3D

const LIFETIME: float = 0.34

var _bits: Array[MeshInstance3D] = []
var _velocities: Array[Vector3] = []
var _age: float = 0.0

func setup(direction: Vector3, color: Color) -> void:
	var forward: Vector3 = direction.normalized()
	if forward.length_squared() < 0.01:
		forward = Vector3(0.0, 0.35, 1.0).normalized()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.4
	for index: int in 7:
		var bit: MeshInstance3D = MeshInstance3D.new()
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3.ONE * randf_range(0.035, 0.07)
		bit.mesh = box
		bit.material_override = material
		add_child(bit)
		_bits.append(bit)
		var spread: Vector3 = Vector3(randf_range(-0.8, 0.8), randf_range(-0.1, 0.9), randf_range(-0.8, 0.8))
		var velocity: Vector3 = (forward * 1.3 + spread).normalized() * randf_range(1.8, 3.4)
		_velocities.append(velocity)
		bit.position = forward * 0.1

func _process(delta: float) -> void:
	_age += delta
	var fade: float = maxf(0.0, 1.0 - _age / LIFETIME)
	for index: int in _bits.size():
		var bit: MeshInstance3D = _bits[index]
		var velocity: Vector3 = _velocities[index]
		bit.position += velocity * delta
		velocity.y -= 9.8 * delta
		_velocities[index] = velocity
		bit.scale = Vector3.ONE * maxf(0.12, fade)
	if _age >= LIFETIME:
		queue_free()
