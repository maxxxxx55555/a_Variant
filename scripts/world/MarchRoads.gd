extends RefCounted

static func build(parent: Node3D, terrain: Node3D) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var links:Array=route_links()
	for link in links:
		var origin: Vector2 = link[0]
		var destination: Vector2 = link[1]
		var direction := (destination - origin).normalized()
		var across := Vector2(-direction.y, direction.x) * 2.3
		var steps := maxi(1, ceili(origin.distance_to(destination) / 12.0))
		for step in steps:
			var a := origin.lerp(destination, float(step) / steps)
			var b := origin.lerp(destination, float(step + 1) / steps)
			var points := [a - across, a + across, b - across, b + across]
			for corner in [0, 1, 2, 1, 3, 2]:
				var point: Vector2 = points[corner]
				vertices.append(Vector3(point.x, terrain.ground_at(point.x, point.y) + 0.06, point.y))
				colors.append(Color("a39470") if corner % 2 == 0 else Color("928364"))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var tool := SurfaceTool.new()
	tool.create_from(mesh, 0)
	tool.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "MarchRoadNetwork"
	road.mesh = tool.commit()
	# Junction strips overlap. A single unlit dirt color keeps their shared
	# surface identical and avoids flickering gradients at intersections.
	road.material_override = preload("res://scripts/world/GroundMaterial.gd").create(true)
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(road)
	build_landmarks(parent,terrain,links)

static func route_links() -> Array:
	var towns: Array = CampaignSystem.definition.towns
	var previous := Vector2(0, 20)
	var links: Array = []
	for index in towns.size():
		var town: Dictionary = towns[index]
		var destination := Vector2(town.x, town.z + 28)
		var origin := previous
		if index >= 8:
			for main in towns.slice(0, 8):
				if main.faction == town.faction: origin = Vector2(main.x, main.z + 28)
		links.append([origin, destination])
		links.append([destination, Vector2(town.x, town.z + 5)])
		if index < 8: previous = destination
	return links

static func build_landmarks(parent:Node3D,terrain:Node3D,links:Array) -> void:
	var meshes:Array[Mesh]=[]
	for variant in 3:meshes.append(landmark_mesh(variant))
	var rng:=RandomNumberGenerator.new()
	rng.seed=72539
	var buckets:Dictionary={}
	var number:=0
	for link in links:
		var a:Vector2=link[0]
		var b:Vector2=link[1]
		var length:float=a.distance_to(b)
		if length<40:continue
		var direction:Vector2=(b-a).normalized()
		var count:=maxi(2,ceili(length/90.0))
		for index in range(1,count):
			var side:float=1.0 if number%2==0 else -1.0
			var at:Vector2=a.lerp(b,float(index)/count)+Vector2(-direction.y,direction.x)*6.8*side
			var variant:int=number%3
			var key:=Vector3i(floori(at.x/240.0),floori(at.y/240.0),variant)
			if not buckets.has(key):buckets[key]=[]
			var yaw:float=-atan2(direction.y,direction.x)+rng.randf_range(-0.18,0.18)
			var scale:float=rng.randf_range(0.9,1.15)
			buckets[key].append(Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3.ONE*scale),Vector3(at.x,terrain.ground_at(at.x,at.y),at.y)))
			number+=1
	for key in buckets:
		var center:=Vector3(key.x*240+120,0,key.y*240+120)
		var transforms:Array=buckets[key]
		var batch:=MultiMesh.new()
		batch.transform_format=MultiMesh.TRANSFORM_3D
		batch.mesh=meshes[key.z]
		batch.instance_count=transforms.size()
		for index in transforms.size():
			var transform:Transform3D=transforms[index]
			transform.origin-=center
			batch.set_instance_transform(index,transform)
		var instance:=MultiMeshInstance3D.new()
		instance.name="Roadside_%d_%d_%d" % [key.x,key.y,key.z]
		instance.position=center
		instance.multimesh=batch
		instance.material_override=RealWorldArt.material("stone" if key.z==0 else "wood")
		instance.visibility_range_end=220
		instance.visibility_range_end_margin=24
		parent.add_child(instance)
static func landmark_mesh(variant:int) -> Mesh:
	var tool:=SurfaceTool.new()
	if variant==0:
		var stone:=SphereMesh.new()
		stone.radial_segments=8
		stone.rings=4
		for piece in [Vector3(0,0.25,0),Vector3(0.08,0.66,0),Vector3(-0.02,0.95,0.04)]:
			var scale:Vector3=Vector3(0.84,0.48,0.7)*(1.0-piece.y*0.45)
			tool.append_from(stone,0,Transform3D(Basis.IDENTITY.scaled(scale),piece))
	elif variant==1:
		append_box(tool,Vector3(0,1.2,0),Vector3(0.16,2.4,0.16))
		append_box(tool,Vector3(0.32,2.1,0),Vector3(0.9,0.28,0.12))
		append_box(tool,Vector3(-0.2,1.75,0),Vector3(0.64,0.22,0.12))
	else:
		for side in [-1,1]:append_box(tool,Vector3(side*0.9,0.65,0),Vector3(0.16,1.3,0.16))
		for height in [0.45,0.95]:append_box(tool,Vector3(0,height,0),Vector3(2.1,0.13,0.12))
	return tool.commit()
static func append_box(tool:SurfaceTool,at:Vector3,dimensions:Vector3) -> void:
	var mesh:=BoxMesh.new()
	mesh.size=dimensions
	tool.append_from(mesh,0,Transform3D(Basis.IDENTITY,at))
