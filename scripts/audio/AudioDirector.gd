extends Node

const CATALOG_PATH := "res://assets/audio/catalog.json"
var catalog: Dictionary = {}
var streams: Dictionary = {}
var music_players: Array[AudioStreamPlayer] = []
var effect_players: Array[AudioStreamPlayer] = []
var spatial_players: Array[AudioStreamPlayer3D] = []
var current_music: String = ""
var music_index: int = -1
var crossfade: Tween
var footstep_index: int = 0
var spatial_cursor: int = 0
var effect_cursor: int = 0
var ambience: AudioStreamPlayer3D
var audio_rng := RandomNumberGenerator.new()
var force_mute: bool = OS.get_environment("GAME_AUDIO_MUTED") == "1"

func _ready() -> void:
	AudioServer.set_bus_mute(0, force_mute)
	audio_rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if not file:
		push_error("Audio catalog missing: " + CATALOG_PATH)
		return
	catalog = JSON.parse_string(file.get_as_text())
	var oaths: bool = catalog.music.has("exploration")
	var routes := {"Music": "Master", "SFX": "Master", "UI": "Master" if oaths else "SFX", "SFX_Combat": "SFX", "SFX_Environment": "SFX", "SFX_UI": "UI", "Voice": "Master"}
	for bus_name in routes:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), routes[bus_name])
	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
	for i in range(8):
		var player := AudioStreamPlayer.new()
		add_child(player)
		effect_players.append(player)
	for i in range(20):
		var player := AudioStreamPlayer3D.new()
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.max_distance = 38
		player.unit_size = 3.0
		player.volume_db = -6
		add_child(player)
		spatial_players.append(player)
	apply_gains()

func _stream(name: String, music: bool = false) -> AudioStreamWAV:
	var key := ("music/" if music else "sfx/") + name
	if streams.has(key):
		return streams[key]
	var group: Dictionary = catalog.get("music" if music else "sfx", {})
	if not group.has(name):
		return null
	var entry: Dictionary = group[name]
	var source = load("res://assets/audio/" + entry.path)
	if not source is AudioStreamWAV:
		push_error("Invalid audio asset: " + entry.path)
		return null
	var sound: AudioStreamWAV = source.duplicate()
	if entry.get("loop", false):
		sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sound.loop_begin = 0
		sound.loop_end = int(sound.get_length() * sound.mix_rate)
	streams[key] = sound
	return sound

func play_music(mood: String, fade_seconds: float = 1.2) -> void:
	if mood == current_music:
		return
	# A shared calm theme continues through state changes without repeating its intro.
	if catalog.get("music", {}).get(mood, {}).get("path", "") == catalog.get("music", {}).get(current_music, {}).get("path", "missing"):
		current_music = mood
		return
	var sound := _stream(mood, true)
	if not sound:
		return
	if is_instance_valid(crossfade):
		crossfade.kill()
	var previous := music_index
	music_index = 0 if music_index < 0 else 1 - music_index
	var next: AudioStreamPlayer = music_players[music_index]
	next.stream = sound
	next.volume_db = -60 if fade_seconds > 0 else 0
	next.play()
	current_music = mood
	if fade_seconds <= 0:
		if previous >= 0:
			music_players[previous].stop()
		return
	crossfade = create_tween().set_parallel(true)
	crossfade.tween_property(next, "volume_db", 0.0, fade_seconds).set_trans(Tween.TRANS_SINE)
	if previous >= 0:
		var old: AudioStreamPlayer = music_players[previous]
		crossfade.tween_property(old, "volume_db", -60.0, fade_seconds).set_trans(Tween.TRANS_SINE)
		crossfade.tween_callback(old.stop).set_delay(fade_seconds)

func play_sfx(sound_name: String, bus_name: String = "") -> AudioStreamPlayer:
	var sound := _stream(sound_name)
	if not sound:
		return null
	var player: AudioStreamPlayer
	for candidate in effect_players:
		if not candidate.playing:
			player = candidate
			break
	if not player:
		player = effect_players[effect_cursor % effect_players.size()]
		effect_cursor += 1
	player.stream = sound
	player.bus = bus_name if not bus_name.is_empty() else "SFX_UI"
	player.volume_db = -5
	player.pitch_scale = audio_rng.randf_range(0.97, 1.03) if sound_name in ["ui_click", "inventory_open", "coin"] else 1.0
	player.play()
	return player

func play_sound(sound_name: String, bus_name: String = "") -> void:
	if sound_name in ["potion", "hit", "enemy_hurt", "enemy_death"]:
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			play_at(sound_name, players[0].global_position, bus_name)
			return
	play_sfx(sound_name, bus_name)

func play_at(sound_name: String, position: Vector3, bus_name: String = "") -> AudioStreamPlayer3D:
	var sound := _stream(sound_name)
	if not sound:
		return null
	var player: AudioStreamPlayer3D
	for candidate in spatial_players:
		if not candidate.playing:
			player = candidate
			break
	if not player:
		player = spatial_players[spatial_cursor % spatial_players.size()]
		spatial_cursor += 1
	player.stream = sound
	player.global_position = position
	player.bus = bus_name if not bus_name.is_empty() else ("SFX_Combat" if sound_name in ["swing", "attack", "hit", "hit_metal", "hit_flesh", "block", "enemy_hurt", "enemy_death"] else "SFX_Environment")
	player.pitch_scale = audio_rng.randf_range(0.94, 1.06)
	player.play()
	return player

func play_footstep(surface: String, position: Vector3) -> void:
	if surface not in ["grass", "dirt", "stone", "wood", "snow"]:
		surface = "grass"
	footstep_index = (footstep_index + 1) % 3
	play_at("footstep_%s_%d" % [surface, footstep_index], position)

func start_ambience(kind: String, position: Vector3) -> void:
	if not is_instance_valid(ambience):
		ambience = AudioStreamPlayer3D.new()
		ambience.bus = "SFX_Environment"
		ambience.unit_size = 35
		ambience.max_distance = 180
		ambience.volume_db = -22
		ambience.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(ambience)
	ambience.stream = _stream("ambience_" + kind)
	ambience.global_position = position
	ambience.play()

func set_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_mute(index, value <= 0 or (bus_name == "Master" and force_mute))
		AudioServer.set_bus_volume_linear(index, clampf(value, 0.0001, 1))

func set_enabled(enabled: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), force_mute or not enabled)

func apply_gains() -> void:
	var settings := get_node_or_null("/root/GameManager")
	if settings:
		set_bus_volume("Music", settings.music_volume)
		set_bus_volume("SFX", settings.sfx_volume)
		set_enabled(settings.audio_enabled)
