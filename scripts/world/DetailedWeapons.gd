extends RefCounted
## Authored geometry keeps blade, leather wrap and fittings as separate PBR surfaces.
static var cache := {}
static var base: ArrayMesh
static var ranged_mesh: ArrayMesh

static func crossbow() -> ArrayMesh:
	if ranged_mesh!=null: return ranged_mesh
	var mesh:=ArrayMesh.new()
	var wood:=StandardMaterial3D.new()
	wood.albedo_color=Color("51402e")
	wood.roughness=0.82
	var stock:=BoxMesh.new()
	stock.size=Vector3(0.075,0.09,0.58)
	append(mesh,stock,Transform3D(Basis.IDENTITY,Vector3(0,-0.025,0.13)),wood)
	var grip:=CylinderMesh.new()
	grip.height=0.13
	grip.top_radius=0.025
	grip.bottom_radius=0.022
	grip.radial_segments=12
	append(mesh,grip,Transform3D(Basis(Vector3.RIGHT,-0.2),Vector3(0,-0.10,-0.035)),wood)
	var iron:=metal(Color("5a686d"),0.46)
	var limb:=SurfaceTool.new()
	limb.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 16:
		var x:float=-0.34+index*0.0425
		var z:float=0.33-0.16*pow(absf(x)/0.34,1.5)
		var next_x:float=x+0.0425
		var next_z:float=0.33-0.16*pow(absf(next_x)/0.34,1.5)
		var piece:=BoxMesh.new()
		piece.size=Vector3(Vector2(next_x-x,next_z-z).length()+0.003,0.023,0.033)
		limb.append_from(piece,0,Transform3D(Basis(Vector3.UP,-atan2(next_z-z,next_x-x)),Vector3((x+next_x)*0.5,0,(z+next_z)*0.5)))
	limb.set_material(iron)
	limb.commit(mesh)
	var cord:=StandardMaterial3D.new()
	cord.albedo_color=Color("b7ad92")
	cord.roughness=0.95
	for side in [-1,1]:
		var a:=Vector3(side*0.34,0,0.17)
		var b:=Vector3(0,0,-0.045)
		var string:=CylinderMesh.new()
		string.top_radius=0.002
		string.bottom_radius=0.002
		string.height=a.distance_to(b)
		string.radial_segments=6
		var direction:Vector3=(b-a).normalized()
		var axes:=Basis(Quaternion(Vector3.UP,direction))
		append(mesh,string,Transform3D(axes,(a+b)*0.5),cord)
	var bolt:=CylinderMesh.new()
	bolt.top_radius=0.003
	bolt.bottom_radius=0.004
	bolt.height=0.48
	bolt.radial_segments=6
	append(mesh,bolt,Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(0,0.035,0.22)),wood)
	ranged_mesh=mesh
	return mesh

static func metal(color: Color, roughness: float) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.metallic=0.82
	mat.roughness=roughness
	return mat

static func sword(footprint: Vector3) -> ArrayMesh:
	var key:=str(footprint)
	if cache.has(key): return cache[key]
	if base==null: base=build_sword()
	var factor:=minf(footprint.x/base.get_aabb().size.x,minf(footprint.y/base.get_aabb().size.y,footprint.z/base.get_aabb().size.z))
	var combined:=ArrayMesh.new()
	for surface in base.get_surface_count():
		var tool:=SurfaceTool.new()
		tool.append_from(base,surface,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*factor),Vector3.ZERO))
		tool.set_material(base.surface_get_material(surface))
		tool.commit(combined)
	cache[key]=combined
	return combined

static func build_sword() -> ArrayMesh:
	var mesh:=ArrayMesh.new()
	var steel:=metal(Color("809098"),0.32)
	var ring_data:=[Vector3(0.18,0.034,0.009),Vector3(0.25,0.034,0.009),Vector3(0.62,0.028,0.007),Vector3(0.84,0.016,0.005),Vector3(0.94,0.0003,0.0003)]
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in ring_data.size()-1:
		var rings: Array=[]
		for data in [ring_data[layer],ring_data[layer+1]]:
			rings.append([Vector3(-data.y,data.x,0),Vector3(0,data.x,data.z),Vector3(data.y,data.x,0),Vector3(0,data.x,-data.z)])
		for side in 4:
			var a:Vector3=rings[0][side]
			var b:Vector3=rings[0][(side+1)%4]
			var c:Vector3=rings[1][side]
			var d:Vector3=rings[1][(side+1)%4]
			for point in [a,c,b,b,c,d]: tool.add_vertex(point)
	tool.generate_normals()
	tool.set_material(steel)
	tool.commit(mesh)
	var leather:=StandardMaterial3D.new()
	leather.albedo_color=Color("35271f")
	leather.roughness=0.86
	var grip:=CylinderMesh.new()
	grip.top_radius=0.018
	grip.bottom_radius=0.019
	grip.height=0.135
	grip.radial_segments=16
	append(mesh,grip,Transform3D(Basis.IDENTITY,Vector3(0,0.095,0)),leather)
	var wrap:=SurfaceTool.new()
	wrap.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 9:
		var band:=CylinderMesh.new()
		band.top_radius=0.020
		band.bottom_radius=0.019
		band.height=0.006
		band.radial_segments=12
		wrap.append_from(band,0,Transform3D(Basis(Vector3.FORWARD,0.10),Vector3(0,0.038+index*0.014,0)))
	wrap.set_material(leather)
	wrap.commit(mesh)
	var fittings:=metal(Color("8a7a55"),0.43)
	var guard:=CylinderMesh.new()
	guard.top_radius=0.011
	guard.bottom_radius=0.015
	guard.height=0.18
	guard.radial_segments=12
	append(mesh,guard,Transform3D(Basis(Vector3.FORWARD,PI/2),Vector3(0,0.175,0)),fittings)
	var pommel:=SphereMesh.new()
	pommel.radius=0.027
	pommel.height=0.045
	pommel.radial_segments=16
	pommel.rings=8
	append(mesh,pommel,Transform3D(Basis.IDENTITY,Vector3(0,0.025,0)),fittings)
	return mesh

static func append(mesh: ArrayMesh, part: Mesh, transform: Transform3D, material: Material) -> void:
	var tool:=SurfaceTool.new()
	tool.append_from(part,0,transform)
	tool.set_material(material)
	tool.commit(mesh)
