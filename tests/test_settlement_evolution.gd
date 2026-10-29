extends "res://tests/AudioCleanTree.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func voices(audio: Node, cue: String) -> Array:
	var found: Array = []
	var stream: Variant = audio._stream(cue)
	for player: Variant in audio.effect_players + audio.spatial_players:
		if player.playing and player.stream == stream:
			found.append(player)
	return found

func stop_voices(audio: Node) -> void:
	for player: Variant in audio.effect_players + audio.spatial_players:
		player.stop()

func count_meshes(node: Node) -> int:
	var total: int = 0
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			total += 1
		total += count_meshes(child)
	return total

func run() -> void:
	await process_frame
	var audio: Node = root.get_node("AudioManager")
	var localization: Node = root.get_node("LocalizationManager")
	var workshop: Node = root.get_node("WorkshopSystem")
	var weather_system: Node = root.get_node("WeatherSystem")
	var time_system: Node = root.get_node("TimeSystem")
	var growth_script: GDScript = load("res://scripts/world/SettlementGrowth.gd")
	var weather_script: GDScript = load("res://scripts/world/CinematicWeather.gd")
	var saved_levels: Dictionary = workshop.levels.duplicate()
	var saved_season: int = time_system.current_season_idx
	workshop.levels = {}
	check(workshop.tier() == 0, "A settlement without buildings has no visible tier")
	workshop.levels = {"farm": 1}
	check(workshop.tier() == 1, "The first building raises the settlement to tier 1")
	workshop.levels = {"farm": 3, "housing": 3}
	check(workshop.tier() == 2, "Six building levels unlock the fortified tier")
	workshop.levels = {"farm": 3, "housing": 3, "well": 3, "market": 3, "sawmill": 3}
	check(workshop.tier() == 3, "Fifteen building levels unlock the town tier")
	workshop.levels = {"farm": 3, "housing": 3, "well": 3, "market": 3, "sawmill": 3, "quarry": 3, "forge": 3, "barracks": 3, "hall": 3}
	check(workshop.tier() == 4, "Twenty-five building levels unlock the citadel tier")
	workshop.levels = {}
	var host: Node3D = Node3D.new()
	root.add_child(host)
	var growth: Node3D = growth_script.new()
	host.add_child(growth)
	growth.build(Vector3.ZERO, func(_x: float, _z: float) -> float: return 0.0, Color("9d9276"))
	await process_frame
	check(growth._tier == 0 and count_meshes(growth) == 0, "An empty settlement grows no visible structures")
	stop_voices(audio)
	workshop.levels = {"farm": 1}
	growth.refresh()
	await process_frame
	var tier_one_meshes: int = count_meshes(growth)
	check(growth._tier == 1 and tier_one_meshes > 0, "Tier 1 raises the first palisade and gate")
	check(voices(audio, "upgrade").size() >= 1, "The first upgrade rings the settlement upgrade cue")
	stop_voices(audio)
	workshop.levels = {"farm": 3, "housing": 3}
	growth.refresh()
	await process_frame
	var tier_two_meshes: int = count_meshes(growth)
	check(growth._tier == 2 and tier_two_meshes > tier_one_meshes, "Tier 2 adds a market and housing to the skyline")
	check(voices(audio, "upgrade").size() >= 1, "Growing to tier 2 rings the upgrade cue")
	stop_voices(audio)
	workshop.levels = {"farm": 3, "housing": 3, "well": 3, "market": 3, "sawmill": 3}
	workshop.changed.emit()
	await process_frame
	var tier_three_meshes: int = count_meshes(growth)
	check(growth._tier == 3 and tier_three_meshes > tier_two_meshes, "Tier 3 raises the hall and its banner")
	check(voices(audio, "upgrade").size() >= 1, "The workshop signal drives the world upgrade and its cue")
	workshop.levels = {"farm": 3, "housing": 3, "well": 3, "market": 3, "sawmill": 3, "quarry": 3, "forge": 3, "barracks": 3, "hall": 3}
	growth.refresh()
	await process_frame
	var tier_four_meshes: int = count_meshes(growth)
	check(growth._tier == 4 and tier_four_meshes > tier_three_meshes, "Tier 4 adds the outer towers and citadel wall")
	stop_voices(audio)
	growth.refresh()
	await process_frame
	check(count_meshes(growth) == tier_four_meshes and voices(audio, "upgrade").is_empty(), "Refreshing an unchanged tier rebuilds nothing and stays silent")
	var settlement_ui: Control = load("res://scenes/ui/settlement_ui.tscn").instantiate()
	root.add_child(settlement_ui)
	await process_frame
	workshop.levels = {"farm": 3, "housing": 3}
	workshop.changed.emit()
	await process_frame
	var tier_two_text: String = localization.get_string("settlement.tier_badge", {"name": localization.get_string("settlement.tier.2"), "level": 2})
	check(settlement_ui.tier_label.text == tier_two_text, "The settlement badge names the current tier and level")
	check(settlement_ui.tier_label.get_theme_color("font_color") == Color("E8DCC3"), "Tier 1-2 badges use the settled parchment color")
	stop_voices(audio)
	workshop.levels = {"farm": 3, "housing": 3, "well": 3, "market": 3, "sawmill": 3}
	workshop.changed.emit()
	await process_frame
	check(settlement_ui.tier_label.get_theme_color("font_color") == Color("C9A227"), "Tier 3-4 badges switch to the gold accent")
	check(voices(audio, "upgrade").size() >= 1, "Clicking up a tier keeps the audible feedback")
	stop_voices(audio)
	workshop.levels = {"farm": 3, "housing": 3}
	workshop.changed.emit()
	await process_frame
	check(voices(audio, "upgrade").is_empty(), "Lowering the authored tier never fakes an upgrade cue")
	workshop.levels = {}
	workshop.changed.emit()
	await process_frame
	check(settlement_ui.tier_label.text.contains(localization.get_string("settlement.tier.0")), "The badge returns to the camp name without buildings")
	check(settlement_ui.tier_label.get_theme_color("font_color") == Color("9aa8a8"), "The empty tier uses the muted stone color")
	localization.set_language("en")
	workshop.levels = {"farm": 3, "housing": 3}
	workshop.changed.emit()
	await process_frame
	check(settlement_ui.tier_label.text == "Fortified Settlement · tier 2", "The settlement badge follows the active language")
	localization.set_language("ru")
	await process_frame
	var environment: Environment = Environment.new()
	var sunlight: DirectionalLight3D = DirectionalLight3D.new()
	var road_network: MeshInstance3D = MeshInstance3D.new()
	road_network.name = "MarchRoadNetwork"
	var terrain: Node3D = Node3D.new()
	terrain.add_child(MeshInstance3D.new())
	var weather_host: Node3D = Node3D.new()
	root.add_child(weather_host)
	weather_host.add_child(road_network)
	weather_host.add_child(terrain)
	weather_host.add_child(sunlight)
	weather_system.current_weather = weather_system.WeatherType.CLEAR
	var weather: Node3D = weather_script.new()
	weather.environment = environment
	weather.sunlight = sunlight
	weather.terrain = terrain
	weather_host.add_child(weather)
	weather.set_process(false)
	await process_frame
	var tints: Array[Color] = [Color("cfe3b8"), Color("ffe2ae"), Color("e6b17c"), Color("bcd2e4")]
	var energies: Array[float] = [1.0, 1.06, 0.92, 0.8]
	var saturations: Array[float] = [0.9, 0.88, 0.8, 0.62]
	check(weather.season_tint == tints[0], "Spring starts the world with its fresh green tint")
	var unique_tints: Dictionary = {}
	for index: int in 4:
		weather.set_season(index)
		check(weather.season_tint == tints[index] and is_equal_approx(weather.season_sun_energy, energies[index]) and is_equal_approx(weather.season_saturation, saturations[index]), "Season %d uses its authored tint, sun energy and saturation" % index)
		unique_tints[weather.season_tint.to_html(false)] = true
		check(is_equal_approx(environment.adjustment_saturation, saturations[index]), "Season %d drives the environment saturation" % index)
		check(is_equal_approx(sunlight.light_energy, 0.72 * energies[index]), "Season %d scales the sun energy" % index)
		check(sunlight.light_color == Color("ffd0a1").lerp(tints[index], 0.22), "Season %d warms the sunlight toward its tint" % index)
		check(environment.fog_light_color == Color("829095").lerp(tints[index], 0.28), "Season %d tints the clear-weather fog" % index)
	check(unique_tints.size() == 4, "All four seasons are visually distinct")
	weather.set_season(-4)
	check(weather.last_season == 0 and weather.season_tint == tints[0], "Negative season indices clamp to spring")
	weather.set_season(9)
	check(weather.last_season == 3 and weather.season_tint == tints[3], "Out-of-range season indices clamp to winter")
	weather.set_season(0)
	time_system.current_season_idx = 2
	weather._process(0.0)
	check(weather.last_season == 2 and weather.season_tint == tints[2], "The world follows the calendar when the season changes")
	check(weather.rain != null and weather.rain.get_parent() == weather, "The weather controller owns exactly one rain rig")
	weather_system.current_weather = weather_system.WeatherType.RAIN
	weather.apply_weather()
	check(weather.rain.visible and is_equal_approx(environment.fog_density, 0.0028), "Rain dampens the season with thicker fog")
	check(is_equal_approx(environment.adjustment_saturation, saturations[2]), "Rain keeps the seasonal saturation")
	check(environment.fog_light_color == Color("536c7d").lerp(tints[2], 0.28), "Rain blends the season tint into storm fog")
	weather_system.current_weather = weather_system.WeatherType.FOG
	weather.apply_weather()
	check(not weather.rain.visible and is_equal_approx(environment.fog_density, 0.004), "Fog hides the rain rig and thickens the air")
	check(is_equal_approx(environment.adjustment_saturation, 0.7), "Fog desaturates the world")
	weather_system.current_weather = weather_system.WeatherType.CLEAR
	time_system.current_season_idx = 0
	weather.apply_weather()
	settlement_ui.queue_free()
	weather_host.queue_free()
	host.queue_free()
	await process_frame
	workshop.levels = saved_levels
	time_system.current_season_idx = saved_season
	print("SETTLEMENT EVOLUTION RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
