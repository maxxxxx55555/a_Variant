extends RefCounted

static func create(road: bool = false) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform bool road = false;
uniform sampler2D meadow : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
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
 vec3 painted = texture(meadow, world.xz * 0.25).rgb;
 vec3 grass = mix(COLOR.rgb, painted, 0.72) * mix(0.95, 1.08, patches);
 vec3 dirt = mix(vec3(0.39, 0.29, 0.18), vec3(0.65, 0.52, 0.31), patches);
 ALBEDO = (road ? dirt : grass) * mix(0.97, 1.02, grain);
 ROUGHNESS = 1.0;
}
"""
	if road: shader.code = shader.code.replace("render_mode cull_disabled;", "render_mode unshaded, cull_disabled;")
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("road", road)
	material.set_shader_parameter("meadow", load("res://assets/art/meadow_painted.png"))
	return material
