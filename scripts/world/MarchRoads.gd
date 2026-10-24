extends RefCounted

static func build(parent: Node3D, terrain: Node3D) -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
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
	var mat := MarchArt.material(Color("a39470"))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	road.material_override = mat
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(road)
