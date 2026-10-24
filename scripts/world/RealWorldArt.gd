class_name RealWorldArt
extends RefCounted
## PBR architecture uses licensed surfaces and shared geometry; gameplay owns colliders.
static var materials: Dictionary = {}
static var houses: Dictionary = {}

static func banner(parent: Node3D, position: Vector3, tint: Color) -> void:
	box(parent,position+Vector3(0,2.5,0),Vector3(0.10,5.0,0.10),"wood")
	var mesh:=QuadMesh.new()
	mesh.size=Vector2(2.0,1.3)
	mesh.subdivide_width=20
	mesh.subdivide_depth=8
	var flag:=MeshInstance3D.new()
	flag.mesh=mesh
	flag.position=position+Vector3(1,4,0)
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode cull_disabled;
uniform vec4 heraldry : source_color;
void vertex(){VERTEX.z+=sin(TIME*1.7+UV.x*5.5)*UV.x*0.16;}
void fragment(){
 float edge=step(0.035,UV.x)*step(UV.x,0.965)*step(0.055,UV.y)*step(UV.y,0.945);
 float grain=0.94+0.06*sin(UV.x*650.0)*sin(UV.y*450.0);
 vec2 p=abs(UV-vec2(0.5,0.43));
 float crest=1.0-step(0.18,p.x+p.y*0.65);
 ALBEDO=mix(vec3(0.36,0.28,0.15),heraldry.rgb,edge)*grain;
 ALBEDO=mix(ALBEDO,vec3(0.56,0.44,0.23),crest*0.8);
 ROUGHNESS=0.98;
}
"""
	var mat:=ShaderMaterial.new()
	mat.shader=shader
	mat.set_shader_parameter("heraldry",tint.lerp(Color("65634e"),0.50).darkened(0.18))
	flag.material_override=mat
	parent.add_child(flag)

static func material(kind: String) -> StandardMaterial3D:
	if materials.has(kind): return materials[kind]
	var names := {"wood":"rough_wood","plaster":"damaged_plaster","roof":"roof_slates_02","stone":"cobblestone_floor_08"}
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.roughness = 0.88
	if names.has(kind):
		var id: String = names[kind]
		var base := "res://assets/art/realistic/materials/"+id+"/"+id
		mat.albedo_texture = load(base+"_diff_1k.jpg")
		mat.normal_enabled = true
		mat.normal_texture = load(base+"_nor_gl_1k.jpg")
		mat.normal_scale = 0.65
		if ResourceLoader.exists(base+"_rough_1k.jpg"):
			mat.roughness_texture = load(base+"_rough_1k.jpg")
		else:
			mat.roughness_texture = load(base+"_arm_1k.jpg")
			mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE*(0.6 if kind!="roof" else 0.85)
	if kind=="wood": mat.albedo_color = Color("665b4b")
	if kind=="plaster": mat.albedo_color = Color("b1aa95")
	if kind=="roof": mat.albedo_color = Color("536371")
	if kind=="stone": mat.albedo_color = Color("969a94")
	if kind=="metal":
		mat.albedo_color = Color("746b58")
		mat.metallic = 0.8
		mat.roughness = 0.36
	if kind=="glass":
		mat.albedo_color = Color("342f24")
		mat.roughness = 0.14
		mat.emission_enabled = true
		mat.emission = Color("dca665")
		mat.emission_energy_multiplier = 0.8
	if kind=="canvas": mat.albedo_color = Color("8c8572")
	if kind=="water":
		mat.albedo_color = Color("243c45")
		mat.roughness = 0.12
		mat.metallic = 0.15
	materials[kind] = mat
	return mat

static func part(parent: Node3D, mesh: Mesh, pos: Vector3, kind: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.layers = 3
	instance.material_override = material(kind)
	instance.position = pos
	instance.rotation = rotation
	instance.visibility_range_end = 280
	instance.visibility_range_end_margin = 35
	parent.add_child(instance)
	return instance

static func box(parent: Node3D, pos: Vector3, size: Vector3, kind: String, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return part(parent,mesh,pos,kind,rotation)

static func bake(parent: Node3D) -> void:
	var groups: Dictionary = {}
	for child in parent.get_children():
		if not child is MeshInstance3D: continue
		var key: int = child.material_override.get_instance_id()
		if not groups.has(key): groups[key] = {"tool":SurfaceTool.new(),"material":child.material_override}
		groups[key].tool.append_from(child.mesh,0,child.transform)
		child.free()
	for group in groups.values():
		var mesh := MeshInstance3D.new()
		mesh.layers = 3
		mesh.mesh = group.tool.commit()
		mesh.material_override = group.material
		mesh.visibility_range_end = 280
		mesh.visibility_range_end_margin = 35
		parent.add_child(mesh)

static func house(root: Node3D, variant: String) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0,2.3,3.1)
	lamp.light_color = Color("ffb96f")
	lamp.light_energy = 0.6
	lamp.omni_range = 5
	lamp.light_cull_mask = 2
	lamp.distance_fade_enabled = true
	lamp.distance_fade_begin = 35
	lamp.distance_fade_length = 15
	root.add_child(lamp)
	if houses.has(variant):
		for template in houses[variant]:
			var node := MeshInstance3D.new()
			node.layers = 3
			node.mesh = template.mesh
			node.material_override = template.material
			node.visibility_range_end = 280
			node.visibility_range_end_margin = 35
			root.add_child(node)
		return
	box(root,Vector3(0,0.23,0),Vector3(4.35,0.46,5.65),"stone")
	box(root,Vector3(0,1.9,0),Vector3(4.18,3.1,5.48),"stone" if variant=="blacksmith" else "plaster")
	var roof := PrismMesh.new()
	roof.size = Vector3(5.15,2.15,6.15)
	part(root,roof,Vector3(0,4.36,0),"roof")
	for side in [-1,1]:
		for front in [-1,1]:
			box(root,Vector3(side*2.03,1.88,front*2.71),Vector3(0.18,3.2,0.18),"wood")
		for height in [0.68,2.95,3.43]: box(root,Vector3(side*2.13,height,0),Vector3(0.15,0.15,5.6),"wood")
		box(root,Vector3(side*2.62,3.28,0),Vector3(0.09,0.11,6.3),"metal")
	for front in [-1,1]:
		var z: float = front*2.8
		for height in [0.68,2.95,3.43]: box(root,Vector3(0,height,z),Vector3(4.28,0.15,0.16),"wood")
		box(root,Vector3(0,1.35,z+front*0.04),Vector3(1.0,2.15,0.09),"wood")
		for side in [-1,1]:
			box(root,Vector3(side*0.57,1.37,z+front*0.08),Vector3(0.12,2.3,0.16),"stone")
			box(root,Vector3(side*1.25,2.0,z+front*0.07),Vector3(0.68,0.9,0.06),"glass")
			box(root,Vector3(side*1.25,1.48,z+front*0.12),Vector3(0.94,0.1,0.2),"stone")
			for shutter in [-1,1]:
				box(root,Vector3(side*1.25+shutter*0.44,2.0,z+front*0.12),Vector3(0.18,1.0,0.08),"wood")
			box(root,Vector3(side*1.25,2.0,z+front*0.13),Vector3(0.7,0.055,0.05),"wood")
			box(root,Vector3(side*1.25,2.0,z+front*0.13),Vector3(0.055,0.9,0.05),"wood")
			box(root,Vector3(side*1.02,4.18,front*3.09),Vector3(2.85,0.13,0.13),"wood",Vector3(0,0,-side*0.69))
		box(root,Vector3(0,2.51,z+front*0.06),Vector3(1.25,0.14,0.16),"stone")
		box(root,Vector3(0.33,1.32,z+front*0.14),Vector3(0.09,0.13,0.07),"metal")
		box(root,Vector3(0,0.28,front*3.04),Vector3(1.5,0.2,0.48),"stone")
	box(root,Vector3(1.12,4.7,0.9),Vector3(0.58,2.25,0.62),"stone")
	box(root,Vector3(1.12,5.83,0.9),Vector3(0.78,0.13,0.82),"stone")
	if variant=="tavern":
		box(root,Vector3(-1.65,2.55,-3.13),Vector3(0.8,0.62,0.13),"wood")
		box(root,Vector3(-1.65,2.95,-3.13),Vector3(1.1,0.06,0.06),"metal")
	bake(root)
	var templates: Array = []
	for child in root.get_children():
		if child is MeshInstance3D: templates.append({"mesh":child.mesh,"material":child.material_override})
	houses[variant] = templates

static func market(parent: Node3D, position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	box(root,Vector3(0,0.9,0),Vector3(3.4,0.16,1.25),"wood")
	for side in [-1,1]:
		box(root,Vector3(side*1.5,1.35,0.4),Vector3(0.12,2.7,0.12),"wood")
		box(root,Vector3(side*1.35,0.46,0),Vector3(0.16,0.92,0.16),"wood")
	box(root,Vector3(0,2.65,0.0),Vector3(3.9,0.055,1.85),"canvas",Vector3(-0.12,0,0))
	for index in 4: box(root,Vector3(index*0.76-1.14,1.12,0),Vector3(0.65,0.3,0.65),"wood")
	bake(root)
	MarchAssets.place(root,"realistic/models/wine_barrel_01/wine_barrel_01.gltf",Vector3(2.4,0,0.4),Vector3(1.4,1.5,1.4))

static func well(parent: Node3D, position: Vector3) -> void:
	var root := Node3D.new()
	root.position = position
	parent.add_child(root)
	for index in 12:
		var angle := index*TAU/12
		box(root,Vector3(cos(angle)*0.88,0.4,sin(angle)*0.88),Vector3(0.28,0.8,0.48),"stone",Vector3(0,-angle,0))
	var water := CylinderMesh.new()
	water.top_radius = 0.73
	water.bottom_radius = 0.73
	water.height = 0.025
	part(root,water,Vector3(0,0.34,0),"water")
	for side in [-1,1]: box(root,Vector3(side*1.0,1.4,0),Vector3(0.16,2.8,0.16),"wood")
	var roof := PrismMesh.new()
	roof.size = Vector3(2.55,0.8,1.7)
	part(root,roof,Vector3(0,2.8,0),"roof")
	bake(root)
