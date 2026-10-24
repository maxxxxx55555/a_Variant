extends RefCounted

static func create(road: bool = false) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform bool road = false;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 float patches = noise(world.xz * 0.19);
 float detail = 1.0 - smoothstep(0.08, 0.7, length(fwidth(world.xz)));
 float grain = road ? 0.5 : mix(0.5, noise(world.xz * 3.0), detail);
 vec3 grass = COLOR.rgb * mix(0.91, 1.05, patches);
 vec3 dirt = mix(vec3(0.39, 0.29, 0.18), vec3(0.65, 0.52, 0.31), patches);
 ALBEDO = (road ? dirt : grass * 0.83) * mix(0.94, 1.03, grain);
 ROUGHNESS = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("road", road)
	return material
