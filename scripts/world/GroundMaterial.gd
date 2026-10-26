extends RefCounted

static func create(road: bool = false) -> ShaderMaterial:
	var shader:Shader= Shader.new()
	shader.code = """shader_type spatial;
render_mode cull_disabled;
uniform bool road = false;
uniform float wetness : hint_range(0.0,1.0) = 0.28;
uniform sampler2D meadow_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D ground_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D ground_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D ground_rough : filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D road_color : source_color,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D road_normal : hint_normal,filter_linear_mipmap_anisotropic,repeat_enable;
uniform sampler2D road_rough : filter_linear_mipmap_anisotropic,repeat_enable;
varying vec3 world;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=world.xz*(road?0.36:0.28);
 vec3 base=road?texture(road_color,uv).rgb:texture(ground_color,uv).rgb;
 vec3 normal_tex=road?texture(road_normal,uv).rgb:texture(ground_normal,uv).rgb;
 float rough=road?texture(road_rough,uv).r:texture(ground_rough,uv).r;
 float patches=noise(world.xz*0.25);
 float puddle=wetness*smoothstep(0.60,0.78,patches);
 vec3 meadow=texture(meadow_color,world.xz*0.19).rgb*vec3(0.70,0.82,0.64);
 float clearing=smoothstep(0.2,0.8,noise(world.xz*0.022));
 if(!road){base=mix(meadow,base,clearing*0.42);}
 else{base*=vec3(0.65,0.69,0.66);}
 ALBEDO=base*mix(0.86,0.98,patches)*mix(1.0,0.60,puddle);
 ROUGHNESS=mix(max(0.65,rough),0.15,puddle);
 SPECULAR=0.45;
 vec3 perturb=vec3(normal_tex.r-0.5,0.0,normal_tex.g-0.5)*0.55;
 vec3 surface_normal=road?mat3(VIEW_MATRIX)*vec3(0,1,0):NORMAL;
 NORMAL=normalize(surface_normal+mat3(VIEW_MATRIX)*perturb);
}
"""
	var material:ShaderMaterial= ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("road",road)
	material.set_shader_parameter("meadow_color",load("res://assets/art/meadow_painted.png"))
	var root:String= "res://assets/art/realistic/materials/"
	for pair:Array in [["ground","forest_ground_04"],["road","cobblestone_floor_08"]]:
		for maps:Array in [["color","diff"],["normal","nor_gl"],["rough","rough"]]:
			var uniform:String=str(pair[0])+"_"+str(maps[0])
			var texture_path:String=root+str(pair[1])+"/"+str(pair[1])+"_"+str(maps[1])+"_1k.jpg"
			material.set_shader_parameter(uniform,load(texture_path))
	return material
