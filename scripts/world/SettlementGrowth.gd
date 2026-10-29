extends Node3D

const MarchArtRef=preload("res://scripts/world/MarchArt.gd")
const RealWorldArtRef=preload("res://scripts/world/RealWorldArt.gd")

var height_at: Callable
var accent: Color = Color("9c8a63")
var _tier: int = -1

func build(origin: Vector3, height_provider: Callable, tint: Color) -> void:
	position = origin
	height_at = height_provider
	accent = tint
	# This signal is wired once per owning node; lifecycle and save tests cover teardown.
	@warning_ignore("return_value_discarded")
	WorkshopSystem.changed.connect(_on_changed)
	refresh()

func _on_changed() -> void:
	refresh()

func refresh() -> void:
	var tier: int = WorkshopSystem.tier()
	if tier == _tier:
		return
	var previous: int = _tier
	_tier = tier
	if previous >= 0 and tier > previous:
		AudioManager.play_sound("upgrade")
	for child: Node in get_children():
		child.queue_free()
	if tier <= 0:
		return
	for index: int in 5:
		_box(_ground(Vector3(-12.0 + index * 6.0, 0.6, 22.0)), Vector3(0.22, 1.2, 0.22), Color("6d4c31"))
	_box(_ground(Vector3(0.0, 1.1, 22.0)), Vector3(30.0, 0.12, 0.14), Color("6d4c31"))
	for side: int in [-1, 1]:
		_box(_ground(Vector3(side * 13.0, 1.1, 14.0)), Vector3(0.18, 2.2, 0.18), Color("5d4127"))
		_box(_ground(Vector3(side * 13.0, 2.35, 14.0)), Vector3(0.34, 0.34, 0.34), Color("d9a35c"))
	if tier >= 2:
		_box(_ground(Vector3(14.0, 2.6, 21.0)), Vector3(2.4, 5.2, 2.4), Color("756044"))
		var roof: CylinderMesh = CylinderMesh.new()
		roof.top_radius = 0.0
		roof.bottom_radius = 2.1
		roof.height = 1.3
		_shape(roof, _ground(Vector3(14.0, 5.9, 21.0)), Color("55432d"))
		RealWorldArtRef.market(self, _ground(Vector3(-8.0, 0.0, 19.0)))
	if tier >= 3:
		_box(_ground(Vector3(0.0, 1.6, 29.0)), Vector3(9.0, 3.2, 6.0), Color("8a8677"))
		var hall_roof: PrismMesh = PrismMesh.new()
		hall_roof.size = Vector3(10.0, 2.4, 7.0)
		_shape(hall_roof, _ground(Vector3(0.0, 4.4, 29.0)), Color("6d4a35"))
		RealWorldArtRef.banner(self, _ground(Vector3(5.2, 0.0, 28.0)), accent)
	if tier >= 4:
		for side: int in [-1, 1]:
			_box(_ground(Vector3(side * 19.0, 1.8, 22.0)), Vector3(3.0, 3.6, 3.0), Color("77756a"))
			_box(_ground(Vector3(side * 19.0, 3.8, 22.0)), Vector3(3.4, 0.4, 3.4), Color("5f5d54"))
			RealWorldArtRef.banner(self, _ground(Vector3(side * 17.0, 0.0, 16.0)), accent)
		_box(_ground(Vector3(0.0, 1.9, 22.0)), Vector3(7.0, 3.2, 1.2), Color("77756a"))

func _box(at: Vector3, size: Vector3, color: Color) -> void:
	# Art helpers return the node; decor lifetime is owned by this container.
	@warning_ignore("return_value_discarded")
	MarchArtRef.box(self, at, size, color)

func _shape(mesh: Mesh, at: Vector3, color: Color) -> void:
	# Art helpers return the node; decor lifetime is owned by this container.
	@warning_ignore("return_value_discarded")
	MarchArtRef.shape(self, mesh, at, color)

func _ground(offset: Vector3) -> Vector3:
	var y: float = 0.0
	if height_at.is_valid():
		# The world supplies terrain heights; both coordinates are finite floats.
		@warning_ignore("unsafe_call_argument")
		y = float(height_at.call(global_position.x + offset.x, global_position.z + offset.z)) - global_position.y
	return Vector3(offset.x, y + offset.y, offset.z)
