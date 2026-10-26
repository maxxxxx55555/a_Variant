extends Node3D

const GRID: int = 129
var width: float = 4000
var step: float
var noise:FastNoiseLite= FastNoiseLite.new()
var flat_points: Array = []
var surface_heights:PackedFloat32Array= PackedFloat32Array()

func generate() -> void:
	width = CampaignSystem.definition.world_size
	step = width / (GRID - 1)
	noise.seed=CampaignSystem.definition.seed
	noise.frequency = 0.0028
	noise.fractal_octaves = 3
	flat_points = CampaignSystem.definition.towns + CampaignSystem.definition.points
	var heights:PackedFloat32Array= PackedFloat32Array()
	var vertices:PackedVector3Array= PackedVector3Array()
	var colors:PackedColorArray= PackedColorArray()
	var indices:PackedInt32Array= PackedInt32Array()
	for z:int in GRID:
		for x:int in GRID:
			var px: float = x * step - width * 0.5
			var pz: float = z * step - width * 0.5
			var h:float= height_at(px, pz)
			if heights.append(h):return
			if vertices.append(Vector3(px,h,pz)):return
			var color:Color= Color("738b48")
			if pz > 500: color = Color("77715c")
			if px > 700 and pz > 0: color = Color("546357")
			if h > 70: color = Color("858679")
			if colors.append(color.lightened((noise.get_noise_2d(px*7,pz*7)+1)*0.055)):return
			if x < GRID - 1 and z < GRID - 1:
				var index:int= z * GRID + x
				indices.append_array(PackedInt32Array([index, index + 1, index + GRID, index + 1, index + GRID + 1, index + GRID]))
	surface_heights = heights
	var arrays:Array= []
	if arrays.resize(Mesh.ARRAY_MAX)!=OK:return
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var tool:SurfaceTool= SurfaceTool.new()
	var temporary:ArrayMesh= ArrayMesh.new()
	temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	tool.create_from(temporary, 0)
	tool.generate_normals()
	var terrain:MeshInstance3D= MeshInstance3D.new()
	terrain.mesh = tool.commit()
	terrain.material_override = preload("res://scripts/world/GroundMaterial.gd").create()
	add_child(terrain)
	var body:StaticBody3D= StaticBody3D.new()
	body.set_meta("surface", "grass")
	add_child(body)
	var collider:CollisionShape3D= CollisionShape3D.new()
	var heightmap:HeightMapShape3D= HeightMapShape3D.new()
	heightmap.map_width = GRID
	heightmap.map_depth = GRID
	heightmap.map_data = heights
	collider.shape = heightmap
	collider.scale = Vector3(step, 1, step)
	body.add_child(collider)
	forest()

func height_at(x: float, z: float) -> float:
	var distance:float= Vector2(x, z).length()
	var height: float = noise.get_noise_2d(x, z) * 28 + maxf(0, absf(x) - 1450) * 0.3 + maxf(0, absf(z) - 1650) * 0.35
	height *= smoothstep(180, 360, distance)
	for point:Dictionary in flat_points:
		var point_x:float=point.x
		var point_z:float=point.z
		var d:float= Vector2(x - point_x, z - point_z).length()
		if d < 65:
			var center_height: float = noise.get_noise_2d(point_x, point_z) * 28 * smoothstep(180, 360, Vector2(point_x, point_z).length())
			height = lerpf(center_height, height, smoothstep(22, 65, d))
	return height

func ground_at(x: float, z: float) -> float:
	# Sample the same triangles as the rendered/collidable heightmap.
	var gx: float = clampf((x + width * 0.5) / step, 0, GRID - 1.001)
	var gz: float = clampf((z + width * 0.5) / step, 0, GRID - 1.001)
	var ix:int= int(gx)
	var iz:int= int(gz)
	var u: float = gx - ix
	var v: float = gz - iz
	var px: float = ix * step - width * 0.5
	var pz: float = iz * step - width * 0.5
	var a: float = surface_heights[iz * GRID + ix] if not surface_heights.is_empty() else height_at(px, pz)
	var b: float = surface_heights[iz * GRID + ix + 1] if not surface_heights.is_empty() else height_at(px + step, pz)
	var c: float = surface_heights[(iz + 1) * GRID + ix] if not surface_heights.is_empty() else height_at(px, pz + step)
	var d: float = surface_heights[(iz + 1) * GRID + ix + 1] if not surface_heights.is_empty() else height_at(px + step, pz + step)
	return a + (b - a) * u + (c - a) * v if u + v <= 1 else d + (c - d) * (1 - u) + (b - d) * (1 - v)

func forest() -> void:
	var rng:RandomNumberGenerator= RandomNumberGenerator.new()
	rng.seed=CampaignSystem.definition.seed
	var transforms: Array[Transform3D] = []
	for attempt:int in 4500:
		var x:float= rng.randf_range(-1950, 1950)
		var z:float= rng.randf_range(-1950, 1950)
		# Broad wooded clusters leave natural meadows between forest regions.
		if noise.get_noise_2d(x * 2.4, z * 2.4) < -0.3: continue
		if Vector2(x, z).length() < 38:
			continue
		var blocked:bool= false
		for point:Dictionary in flat_points:
			var point_x:float=point.x
			var point_z:float=point.z
			if Vector2(x - point_x, z - point_z).length() < 29:
				blocked = true
				break
		if blocked:
			continue
		var size:float= rng.randf_range(0.7, 1.65)
		var tree_basis:Basis= Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
		transforms.append(Transform3D(tree_basis, Vector3(x, ground_at(x, z), z)))
	# Authored groves frame inhabited spaces without entering the street or
	# the unchanged building/interaction footprints.
	for point:Dictionary in flat_points:
		var point_x:float=point.x
		var point_z:float=point.z
		for i:int in 22:
			var angle:float= rng.randf()*TAU
			var radius:float= rng.randf_range(32,80)
			var x: float = point_x+cos(angle)*radius
			var z: float = point_z+sin(angle)*radius
			if absf(x-point_x)<7: continue
			var size:float= rng.randf_range(0.8,1.5)
			transforms.append(Transform3D(Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*size),Vector3(x,ground_at(x,z),z)))
	var mesh: Mesh = load("res://assets/art/realistic/trees/birch_game.res")
	instances(mesh, transforms, Vector3.ZERO, Color.WHITE, true)

func instances(mesh: Mesh, transforms: Array[Transform3D], offset: Vector3, color: Color, authored: bool = false) -> void:
	# A single map-wide MultiMesh is always visible and submits the entire
	# forest to every shadow pass. Spatial batches let the renderer cull it.
	var buckets: Dictionary = {}
	for instance_transform:Transform3D in transforms:
		var key:Vector2i= Vector2i(floori(instance_transform.origin.x / 100), floori(instance_transform.origin.z / 100))
		if not buckets.has(key): buckets[key] = []
		var bucket:Array=buckets[key]
		bucket.append(instance_transform)
	var shared_material:StandardMaterial3D= MarchArt.material(color)
	for key:Vector2i in buckets:
		var center:Vector3= Vector3(key.x * 100 + 50, 0, key.y * 100 + 50)
		var group: Array = buckets[key]
		var batch:MultiMesh= MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = group.size()
		for index:int in group.size():
			var instance_transform: Transform3D = group[index]
			instance_transform.origin += instance_transform.basis * offset - center
			batch.set_instance_transform(index, instance_transform)
		var node:MultiMeshInstance3D= MultiMeshInstance3D.new()
		node.position = center
		node.multimesh = batch
		if not authored: node.material_override = shared_material
		node.visibility_range_end = 240
		node.visibility_range_end_margin = 30
		if offset.y > 6: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
