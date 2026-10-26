extends RefCounted
const TerrainView=preload("res://scripts/world/MarchTerrain.gd")

static func dress_town(parent: Node3D, terrain:TerrainView, data: Dictionary) -> void:
	var point_x:float=data.x
	var point_z:float=data.z
	var origin:Vector3= Vector3(point_x - 32, terrain.ground_at(point_x - 32, point_z), point_z)
	var plot:MeshInstance3D= MarchArt.box(parent, origin + Vector3(0, 0.08, 0), Vector3(13, 0.12, 18), Color("665b40")) as MeshInstance3D
	plot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for side:int in [-1, 1]:
		for index:int in 6:
			var post:Vector3= origin + Vector3(side * 7, 0.6, index * 3.6 - 9)
			# The generated mesh is attached to its parent; no separate handle is needed here.
			@warning_ignore("return_value_discarded")
			MarchArt.box(parent, post, Vector3(0.12, 1.2, 0.12), Color("6f6248"))
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(parent, origin + Vector3(side * 7, 0.7, 0), Vector3(0.1, 0.1, 18), Color("827457"))
	var blades:PackedVector3Array= PackedVector3Array()
	for side:int in [-1, 1]:
		blades.append_array(PackedVector3Array([Vector3(side * 0.16, 0, 0), Vector3(0, 0.8, 0), Vector3(0, 0, side * 0.12)]))
	var arrays:Array= []
	if arrays.resize(Mesh.ARRAY_MAX)!=OK:return
	arrays[Mesh.ARRAY_VERTEX] = blades
	var mesh:ArrayMesh= ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var plants:MultiMesh= MultiMesh.new()
	plants.transform_format = MultiMesh.TRANSFORM_3D
	plants.mesh = mesh
	plants.instance_count = 240
	for index:int in 240:
		var pos:Vector3= Vector3((index % 12) * 1.0 - 5.5, 0.16, floori(float(index)/12.0) * 0.8 - 7.6)
		plants.set_instance_transform(index, Transform3D(Basis(Vector3.UP, index * 2.4), pos))
	var crops:MultiMeshInstance3D= MultiMeshInstance3D.new()
	crops.position = origin
	crops.multimesh = plants
	var mat:StandardMaterial3D= MarchArt.material(Color("6f7951") if data.faction != "marsh_keepers" else Color("58684e"))
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crops.material_override = mat
	crops.visibility_range_end = 140
	crops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(crops)
	# Local stores and working equipment make each inhabited stop readable.
	var yard:Vector3= Vector3(point_x + 22, terrain.ground_at(point_x + 22, point_z - 9), point_z - 9)
	for index:int in 5:
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(parent, yard + Vector3(index * 0.55, 0.22, 0), Vector3(0.4, 0.4, 2.6), Color("716046"))
	for index:int in 3:
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(parent, yard + Vector3(index * 1.2, 0.5, 4), Vector3(1, 1, 1), Color("8d7853"))
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(parent, yard + Vector3(index * 1.2, 0.5, 4.52), Vector3(1.03, 0.1, 0.05), Color("4c5145"))
	var cart:Node3D= Node3D.new()
	cart.position = yard + Vector3(-1, 0, -5)
	parent.add_child(cart)
	# The generated mesh is attached to its parent; no separate handle is needed here.
	@warning_ignore("return_value_discarded")
	MarchArt.box(cart, Vector3(0, 0.65, 0), Vector3(1.8, 0.18, 2.7), Color("756449"))
	for side:int in [-1, 1]:
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(cart, Vector3(side * 0.9, 1.0, 0), Vector3(0.12, 0.7, 2.7), Color("847154"))
		var wheel:CylinderMesh= CylinderMesh.new()
		wheel.top_radius = 0.5
		wheel.bottom_radius = 0.5
		wheel.height = 0.16
		wheel.radial_segments = 10
		# The figure owner retains this attached mesh part.
		@warning_ignore("return_value_discarded")
		MarchArt.shape(cart, wheel, Vector3(side * 1.05, 0.5, 0.4), Color("4a4436"), Vector3(0, 0, PI * 0.5))
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(cart, Vector3(side * 0.55, 0.5, -2), Vector3(0.1, 0.12, 2), Color("726148"))
