extends RefCounted
## Sparse local ground cover; never changes movement or quest navigation.

static func build(parent: Node3D, terrain: Node3D, center: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(center) + 482
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	for angle in [0.0,PI/3,PI*2/3]:
		var across:=Vector3(cos(angle),0,sin(angle))
		var bend:=Vector3(-sin(angle),0,cos(angle))*0.10
		var left:=-across*0.024
		var right:=across*0.024
		var mid:=Vector3(0,0.27,0)+bend*0.3
		var tip:=Vector3(0,0.45,0)+bend
		vertices.append_array(PackedVector3Array([left,right,mid-across*0.013,right,mid+across*0.013,mid-across*0.013,mid-across*0.013,mid+across*0.013,tip]))
		uvs.append_array(PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,0.6),Vector2(1,0),Vector2(1,0.6),Vector2(0,0.6),Vector2(0,0.6),Vector2(1,0.6),Vector2(0.5,1)]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex() {
 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 VERTEX.x += sin(TIME * 1.7 + world.x * 0.2 + world.z * 0.4) * UV.y * 0.07;
 NORMAL = vec3(0.0, 1.0, 0.0);
}
void fragment() {
 float hue = fract(sin(floor(world.x * 2.0) * 12.3 + floor(world.z * 2.0) * 7.1) * 483.5);
 ALBEDO = mix(vec3(0.19, 0.28, 0.12), vec3(0.45, 0.53, 0.25), UV.y) * mix(0.8, 1.12, hue);
 ROUGHNESS = 1.0;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	var transforms: Array[Transform3D] = []
	for i in 7000:
		var x := center.x + rng.randf_range(-70, 70)
		var z := center.y + rng.randf_range(-70, 70)
		# Keep the central settlement street, houses and courtyard open.
		if absf(x - center.x) < 5: continue
		if absf(x - center.x) < 18 and absf(z - center.y) < 20: continue
		var scale := rng.randf_range(0.7, 1.7)
		transforms.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * scale), Vector3(x, terrain.ground_at(x, z), z)))
	batch.instance_count = transforms.size()
	for i in transforms.size(): batch.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.visibility_range_end = 160
	node.visibility_range_end_margin = 30
	parent.add_child(node)
