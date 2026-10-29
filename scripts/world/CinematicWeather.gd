extends Node3D
var environment: Environment
var sunlight: DirectionalLight3D
var player: Node3D
var terrain: Node3D
var rain: MultiMeshInstance3D
var seeds: Array[Vector3] = []
var elapsed:float= 0.0
var last_weather:int= -1
var last_season:int= -1
var season_tint:Color= Color("cfe3b8")
var season_sun_energy:float= 1.0
var season_saturation:float= 0.9

func _ready() -> void:
	var rng:RandomNumberGenerator= RandomNumberGenerator.new()
	rng.seed = 44107
	var batch:MultiMesh= MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var drop:QuadMesh= QuadMesh.new()
	drop.size = Vector2(0.018,0.3)
	batch.mesh = drop
	batch.instance_count = 260
	for index:int in batch.instance_count: seeds.append(Vector3(rng.randf_range(-10,10),rng.randf_range(0,14),rng.randf_range(-10,10)))
	rain = MultiMeshInstance3D.new()
	rain.multimesh = batch
	rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material:StandardMaterial3D= StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = Color(0.62,0.76,0.83,0.22)
	rain.material_override = material
	add_child(rain)
	set_season(TimeSystem.current_season_idx)

func set_season(index: int) -> void:
	last_season = clampi(index, 0, 3)
	var tints: Array[Color] = [Color("cfe3b8"), Color("ffe2ae"), Color("e6b17c"), Color("bcd2e4")]
	var energies: Array[float] = [1.0, 1.06, 0.92, 0.8]
	var saturations: Array[float] = [0.9, 0.88, 0.8, 0.62]
	season_tint = tints[last_season]
	season_sun_energy = energies[last_season]
	season_saturation = saturations[last_season]
	apply_weather()

func apply_weather() -> void:
	last_weather = int(WeatherSystem.current_weather)
	var raining: bool = last_weather in [WeatherSystem.WeatherType.RAIN,WeatherSystem.WeatherType.STORM]
	var mist: bool = last_weather in [WeatherSystem.WeatherType.FOG,WeatherSystem.WeatherType.STORM]
	rain.visible = raining
	var wet:float= 0.85 if raining else 0.28
	for mesh:MeshInstance3D in [terrain.get_child(0),get_parent().get_node("MarchRoadNetwork")]:
		if mesh.material_override is ShaderMaterial:
			var shader:ShaderMaterial=mesh.material_override as ShaderMaterial
			shader.set_shader_parameter("wetness",wet)
	for kind:Variant in RealWorldArt.materials:
		if kind in ["wood","roof","stone"]: RealWorldArt.materials[kind].roughness = 0.58 if raining else 0.84
	environment.fog_density = 0.004 if mist else (0.0028 if raining else 0.0018)
	var weather_fog:Color= Color("536c7d") if raining else Color("829095")
	environment.fog_light_color = weather_fog.lerp(season_tint, 0.28)
	environment.adjustment_saturation = 0.7 if mist else season_saturation
	sunlight.light_energy = (0.38 if raining else 0.72) * season_sun_energy
	sunlight.light_color = Color("ffd0a1").lerp(season_tint, 0.22)

func _process(delta: float) -> void:
	if last_weather != int(WeatherSystem.current_weather): apply_weather()
	if last_season != TimeSystem.current_season_idx: set_season(TimeSystem.current_season_idx)
	if not rain.visible or not is_instance_valid(player): return
	elapsed = fmod(elapsed+delta,1000.0)
	rain.global_position = player.global_position
	for index:int in seeds.size():
		var p:Vector3= seeds[index]
		p.y = fposmod(p.y-elapsed*12,14)-1
		p.x += sin(elapsed*0.25+index)*0.25
		rain.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY,p))
