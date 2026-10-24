extends Node3D

const GRID: int = 129
var width: float = 4000
var step: float
var noise := FastNoiseLite.new()
var flat_points: Array = []

func generate() -> void:
	width = CampaignSystem.definition.world_size
	step = width / (GRID - 1)
	noise.seed = int(CampaignSystem.definition.seed)
	noise.frequency = 0.0028
	noise.fractal_octaves = 3
	flat_points = CampaignSystem.definition.towns + CampaignSystem.definition.points
	var heights := PackedFloat32Array()
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z in GRID:
		for x in GRID:
			var px: float = x * step - width * 0.5
			var pz: float = z * step - width * 0.5
			var h := height_at(px, pz)
			heights.append(h)
			vertices.append(Vector3(px, h, pz))
			var color := Color("687252")
			if pz > 500: color = Color("77715c")
			if px > 700 and pz > 0: color = Color("546357")
			if h > 70: color = Color("858679")
			colors.append(color.lightened((noise.get_noise_2d(px * 7, pz * 7) + 1) * 0.055))
			if x < GRID - 1 and z < GRID - 1:
				var index := z * GRID + x
				indices.append_array(PackedInt32Array([index, index + 1, index + GRID, index + 1, index + GRID + 1, index + GRID]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var tool := SurfaceTool.new()
	var temporary := ArrayMesh.new()
	temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	tool.create_from(temporary, 0)
	tool.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.mesh = tool.commit()
	var mat := MarchArt.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	terrain.material_override = mat
	add_child(terrain)
	var body := StaticBody3D.new()
	body.set_meta("surface", "grass")
	add_child(body)
	var collider := CollisionShape3D.new()
	var heightmap := HeightMapShape3D.new()
	heightmap.map_width = GRID
	heightmap.map_depth = GRID
	heightmap.map_data = heights
	collider.shape = heightmap
	collider.scale = Vector3(step, 1, step)
	body.add_child(collider)
	forest()

func height_at(x: float, z: float) -> float:
	var distance := Vector2(x, z).length()
	var height: float = noise.get_noise_2d(x, z) * 28 + maxf(0, absf(x) - 1450) * 0.3 + maxf(0, absf(z) - 1650) * 0.35
	height *= smoothstep(180, 360, distance)
	for point in flat_points:
		var d := Vector2(x - point.x, z - point.z).length()
		if d < 65:
			var center_height: float = noise.get_noise_2d(point.x, point.z) * 28 * smoothstep(180, 360, Vector2(point.x, point.z).length())
			height = lerpf(center_height, height, smoothstep(22, 65, d))
	return height

func ground_at(x: float, z: float) -> float:
	# Sample the same triangles as the rendered/collidable heightmap.
	var gx: float = clampf((x + width * 0.5) / step, 0, GRID - 1.001)
	var gz: float = clampf((z + width * 0.5) / step, 0, GRID - 1.001)
	var ix := int(gx)
	var iz := int(gz)
	var u: float = gx - ix
	var v: float = gz - iz
	var px: float = ix * step - width * 0.5
	var pz: float = iz * step - width * 0.5
	var a := height_at(px, pz)
	var b := height_at(px + step, pz)
	var c := height_at(px, pz + step)
	var d := height_at(px + step, pz + step)
	return a + (b - a) * u + (c - a) * v if u + v <= 1 else d + (c - d) * (1 - u) + (b - d) * (1 - v)

func forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(CampaignSystem.definition.seed)
	var transforms: Array[Transform3D] = []
	for attempt in 6000:
		var x := rng.randf_range(-1950, 1950)
		var z := rng.randf_range(-1950, 1950)
		if Vector2(x, z).length() < 38:
			continue
		var blocked := false
		for point in flat_points:
			if Vector2(x - point.x, z - point.z).length() < 29:
				blocked = true
				break
		if blocked:
			continue
		var size := rng.randf_range(0.7, 1.65)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
		transforms.append(Transform3D(basis, Vector3(x, ground_at(x, z), z)))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.19
	trunk.bottom_radius = 0.32
	trunk.height = 4.5
	trunk.radial_segments = 5
	instances(trunk, transforms, Vector3(0, 2.25, 0), Color("574631"))
	for layer in 3:
		var crown := CylinderMesh.new()
		crown.top_radius = 0
		crown.bottom_radius = 2.7 - layer * 0.6
		crown.height = 4.2 - layer * 0.5
		crown.radial_segments = 6
		instances(crown, transforms, Vector3(0, 4.5 + layer * 1.5, 0), Color("3d5746").lightened(layer * 0.035))

func instances(mesh: Mesh, transforms: Array[Transform3D], offset: Vector3, color: Color) -> void:
	# A single map-wide MultiMesh is always visible and submits the entire
	# forest to every shadow pass. Spatial batches let the renderer cull it.
	var buckets: Dictionary = {}
	for transform in transforms:
		var key := Vector2i(floori(transform.origin.x / 400), floori(transform.origin.z / 400))
		if not buckets.has(key): buckets[key] = []
		buckets[key].append(transform)
	var shared_material := MarchArt.material(color)
	for key in buckets:
		var center := Vector3(key.x * 400 + 200, 0, key.y * 400 + 200)
		var group: Array = buckets[key]
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = group.size()
		for index in group.size():
			var transform: Transform3D = group[index]
			transform.origin += transform.basis * offset - center
			batch.set_instance_transform(index, transform)
		var node := MultiMeshInstance3D.new()
		node.position = center
		node.multimesh = batch
		node.material_override = shared_material
		node.visibility_range_end = 600
		node.visibility_range_end_margin = 80
		if offset.y > 6: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
