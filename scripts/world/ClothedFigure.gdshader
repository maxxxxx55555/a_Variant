shader_type spatial;
uniform sampler2D palette : source_color,filter_linear_mipmap;
uniform bool armored=false;
void fragment(){
 vec3 color=texture(palette,UV).rgb;
 float value=dot(color,vec3(0.299,0.587,0.114));
 bool skin=color.r>color.b*1.28 && color.r>color.g*1.1 && color.g>color.b*1.05;
 ALBEDO=skin?mix(color,vec3(value)*vec3(1.14,0.93,0.80),0.35):mix(vec3(value)*vec3(0.56,0.64,0.60),color,0.12);
 ROUGHNESS=skin?0.82:(armored?0.43:0.94);
 METALLIC=armored && !skin?0.55:0.0;
}
