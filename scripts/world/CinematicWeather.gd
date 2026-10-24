extends Node3D
var environment: Environment
var sunlight: DirectionalLight3D
var player: Node3D
var terrain: Node3D
var rain: MultiMeshInstance3D
var seeds: Array[Vector3] = []
var elapsed := 0.0
var last_weather := -1

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 44107
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var drop := QuadMesh.new()
	drop.size = Vector2(0.018,0.3)
	batch.mesh = drop
	batch.instance_count = 260
	for index in batch.instance_count: seeds.append(Vector3(rng.randf_range(-10,10),rng.randf_range(0,14),rng.randf_range(-10,10)))
	rain = MultiMeshInstance3D.new()
	rain.multimesh = batch
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(0.62,0.76,0.83,0.22)
	rain.material_override = material
	add_child(rain)
	apply_weather()

func apply_weather() -> void:
	last_weather = int(WeatherSystem.current_weather)
	var raining: bool = last_weather in [WeatherSystem.WeatherType.RAIN,WeatherSystem.WeatherType.STORM]
	var mist: bool = last_weather in [WeatherSystem.WeatherType.FOG,WeatherSystem.WeatherType.STORM]
	rain.visible = raining
	var wet := 0.85 if raining else 0.28
	for mesh in [terrain.get_child(0),get_parent().get_node("MarchRoadNetwork")]:
		if mesh.material_override is ShaderMaterial: mesh.material_override.set_shader_parameter("wetness",wet)
	for kind in RealWorldArt.materials:
		if kind in ["wood","roof","stone"]: RealWorldArt.materials[kind].roughness = 0.58 if raining else 0.84
	environment.fog_density = 0.004 if mist else (0.0028 if raining else 0.0018)
	environment.fog_light_color = Color("536c7d") if raining else Color("829095")
	sunlight.light_energy = 0.38 if raining else 0.72

func _process(delta: float) -> void:
	if last_weather != int(WeatherSystem.current_weather): apply_weather()
	if not rain.visible or not is_instance_valid(player): return
	elapsed = fmod(elapsed+delta,1000.0)
	rain.global_position = player.global_position
	for index in seeds.size():
		var p := seeds[index]
		p.y = fposmod(p.y-elapsed*12,14)-1
		p.x += sin(elapsed*0.25+index)*0.25
		rain.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,p))
