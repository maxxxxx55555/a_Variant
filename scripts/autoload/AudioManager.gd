extends Node

var audio_players: Dictionary = {}

func _ready() -> void:
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	setup_audio_players()

func setup_audio_players() -> void:
	var sound_names = ["footstep", "attack", "hit", "potion", "pickup", "inventory_open", "ui_click", "enemy_hurt", "enemy_death"]
	for s_name in sound_names:
		var p = AudioStreamPlayer.new()
		add_child(p)
		audio_players[s_name] = p

func play_sound(sound_name: String, bus_name: String = "") -> void:
	if not audio_players.has(sound_name):
		return
	var player: AudioStreamPlayer = audio_players[sound_name]
	player.bus = bus_name if not bus_name.is_empty() else ("UI" if sound_name in ["ui_click", "inventory_open"] else "SFX")

	# Procedurally generated audio tone for Stage 1 feedback if wav files absent
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.1
	player.stream = stream
	player.play()

	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var freq = 440.0
		match sound_name:
			"footstep": freq = 120.0
			"attack": freq = 300.0
			"hit": freq = 180.0
			"potion": freq = 600.0
			"pickup": freq = 800.0
			"ui_click": freq = 1000.0
			"enemy_hurt": freq = 220.0
			"enemy_death": freq = 90.0

		var frames = int(22050 * 0.08)
		for i in range(frames):
			var sample = sin(2.0 * PI * freq * i / 22050.0) * 0.2
			playback.push_frame(Vector2(sample, sample))

func set_bus_volume(bus_name: String, volume_linear: float) -> void:
	var idx = AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(volume_linear))
