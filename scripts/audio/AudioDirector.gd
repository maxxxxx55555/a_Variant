extends Node
const TypeRefUIFeedback=preload("res://scripts/audio/UIFeedback.gd")

const CATALOG_PATH:String= "res://assets/audio/catalog.json"
var catalog: Dictionary = {}
var streams: Dictionary = {}
var music_players: Array[AudioStreamPlayer] = []
var effect_players: Array[AudioStreamPlayer] = []
var spatial_players: Array[AudioStreamPlayer3D] = []
var current_music: String = ""
var finale_player:AudioStreamPlayer
var current_finale:String=""
var music_index: int = -1
var crossfade: Tween
var footstep_index: int = 0
var spatial_cursor: int = 0
var effect_cursor: int = 0
var ambience: AudioStreamPlayer3D
var feedback_serial:int=0
var audio_rng:RandomNumberGenerator= RandomNumberGenerator.new()
var force_mute: bool = OS.get_environment("GAME_AUDIO_MUTED") == "1"
var closing:bool=false
var shutdown_complete:bool=false
var shutdown_ok:bool=false

func _ready() -> void:
	AudioServer.set_bus_mute(0, force_mute)
	audio_rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	catalog = BuildIntegrity.read_json(CATALOG_PATH)
	var music_catalog:Dictionary=catalog.music
	var oaths:bool=music_catalog.has("exploration")
	var routes:Dictionary[String,String]= {"Music": "Master", "SFX": "Master", "UI": "Master" if oaths else "SFX", "SFX_Combat": "SFX", "SFX_Environment": "SFX", "SFX_UI": "UI", "Voice": "Master"}
	for bus_name:String in routes:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
		AudioServer.set_bus_send(AudioServer.get_bus_index(bus_name), routes[bus_name])
	for i:int in range(2):
		var player:AudioStreamPlayer= AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		music_players.append(player)
	for i:int in range(8):
		var player:AudioStreamPlayer= AudioStreamPlayer.new()
		add_child(player)
		effect_players.append(player)
	for i:int in range(20):
		var player:AudioStreamPlayer3D= AudioStreamPlayer3D.new()
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		player.max_distance = 38
		player.unit_size = 3.0
		player.volume_db = -6
		add_child(player)
		spatial_players.append(player)
	apply_gains()
	var feedback:TypeRefUIFeedback=preload("res://scripts/audio/UIFeedback.gd").new()
	add_child(feedback)
	feedback.start(self)

func _stream(sound_id: String, music: bool = false) -> AudioStreamWAV:
	if closing:return null
	var key:String= ("music/" if music else "sfx/") + sound_id
	if streams.has(key):
		return streams[key]
	var group: Dictionary = catalog.get("music" if music else "sfx", {})
	if not group.has(sound_id):
		return null
	var entry: Dictionary = group[sound_id]
	var asset_path:String=entry.path
	var source:Resource=load("res://assets/audio/"+asset_path)
	if not source is AudioStreamWAV:
		push_error("Invalid audio asset: " + entry.path)
		return null
	var sound: AudioStreamWAV = (source as AudioStreamWAV).duplicate()
	if entry.get("loop", false):
		sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sound.loop_begin = 0
		sound.loop_end = int(sound.get_length() * sound.mix_rate)
	streams[key] = sound
	return sound

func play_music(mood: String, fade_seconds: float = 1.2) -> void:
	if closing:return
	if is_instance_valid(finale_player):finale_player.stop()
	current_finale=""
	if mood == current_music:
		return
	# A shared calm theme continues through state changes without repeating its intro.
	var music_catalog:Dictionary=catalog.get("music",{})
	var incoming:Dictionary=music_catalog.get(mood,{})
	var existing:Dictionary=music_catalog.get(current_music,{})
	if incoming.get("path","")==existing.get("path","missing"):
		current_music = mood
		return
	var sound:AudioStreamWAV= _stream(mood, true)
	if not sound:
		return
	if is_instance_valid(crossfade):
		crossfade.kill()
	var previous:int= music_index
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
	# Tween retains this fluent configuration.
	@warning_ignore("return_value_discarded")
	crossfade.tween_property(next, "volume_db", 0.0, fade_seconds).set_trans(Tween.TRANS_SINE)
	if previous >= 0:
		var old: AudioStreamPlayer = music_players[previous]
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		crossfade.tween_property(old, "volume_db", -60.0, fade_seconds).set_trans(Tween.TRANS_SINE)
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		crossfade.tween_callback(old.stop).set_delay(fade_seconds)

func play_sfx(sound_name: String, bus_name: String = "") -> AudioStreamPlayer:
	if closing:return null
	var sound:AudioStreamWAV= _stream(sound_name)
	if not sound:
		return null
	feedback_serial+=1
	var player: AudioStreamPlayer
	for candidate:AudioStreamPlayer in effect_players:
		if not candidate.playing:
			player = candidate
			break
	if not player:
		player = effect_players[effect_cursor % effect_players.size()]
		effect_cursor += 1
	player.stream = sound
	player.bus = bus_name if not bus_name.is_empty() else "SFX_UI"
	player.volume_db = -24 if sound_name=="ui_focus" else -10 if sound_name=="ui_error" else -5
	var effects:Dictionary=catalog.sfx
	var effect:Dictionary=effects[sound_name]
	player.pitch_scale = audio_rng.randf_range(0.97, 1.03) if not effect.get("loop",false) and sound_name not in ["victory","defeat"] else 1.0
	player.play()
	return player

func play_sound(sound_name: String, bus_name: String = "") -> void:
	if sound_name in ["potion", "hit", "enemy_hurt", "enemy_death"]:
		var players:Array[Node]= get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			# AudioManager owns and recycles the spatial voice.
			@warning_ignore("return_value_discarded")
			play_at(sound_name, (players[0] as Node3D).global_position, bus_name)
			return
	# AudioManager owns the voice and records the feedback acknowledgment.
	@warning_ignore("return_value_discarded")
	play_sfx(sound_name, bus_name)

func play_at(sound_name: String, position: Vector3, bus_name: String = "") -> AudioStreamPlayer3D:
	if closing:return null
	var sound:AudioStreamWAV= _stream(sound_name)
	if not sound:
		return null
	feedback_serial+=1
	var player: AudioStreamPlayer3D
	for candidate:AudioStreamPlayer3D in spatial_players:
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
	# AudioManager owns and recycles the spatial voice.
	@warning_ignore("return_value_discarded")
	play_at("footstep_%s_%d" % [surface, footstep_index], position)

func start_ambience(kind: String, position: Vector3) -> void:
	if closing:return
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
	var index:int= AudioServer.get_bus_index(bus_name)
	if index >= 0:
		AudioServer.set_bus_mute(index, value <= 0 or (bus_name == "Master" and force_mute))
		AudioServer.set_bus_volume_linear(index, clampf(value, 0.0001, 1))

func apply_gains() -> void:
	set_bus_volume("Master", SettingsManager.master_volume)
	set_bus_volume("Music", SettingsManager.music_volume)
	set_bus_volume("SFX", SettingsManager.sfx_volume)
	set_bus_volume("UI", SettingsManager.ui_volume)

func play_finale(victorious:bool) -> void:
	if closing:return
	var cue:String="victory" if victorious else "defeat"
	if is_instance_valid(finale_player) and finale_player.playing and current_finale==cue:return
	if is_instance_valid(crossfade):crossfade.kill()
	current_music=""
	current_finale=cue
	crossfade=create_tween().set_parallel(true)
	for player:AudioStreamPlayer in music_players:
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		crossfade.tween_property(player,"volume_db",-60.0,0.7).set_trans(Tween.TRANS_SINE)
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		crossfade.tween_callback(player.stop).set_delay(0.7)
	if not is_instance_valid(finale_player):
		finale_player=AudioStreamPlayer.new()
		finale_player.bus="Music"
		add_child(finale_player)
	finale_player.stream=_stream(cue)
	finale_player.volume_db=0
	finale_player.play()

func set_scene_paused(paused:bool) -> void:
	# Menus freeze the background bed; ending stingers keep their natural release.
	for player:AudioStreamPlayer in music_players:player.stream_paused=paused

func shutdown_stream_refs()->Array[WeakRef]:
	var references:Array[WeakRef]=[]
	for key:String in streams:references.append(weakref(streams[key]))
	for voice:Node in get_children():
		if voice is AudioStreamPlayer and (voice as AudioStreamPlayer).stream!=null:references.append(weakref((voice as AudioStreamPlayer).stream))
		elif voice is AudioStreamPlayer3D and (voice as AudioStreamPlayer3D).stream!=null:references.append(weakref((voice as AudioStreamPlayer3D).stream))
	return references

func shutdown_refs_released(references:Array[WeakRef])->bool:
	for reference:WeakRef in references:
		if reference.get_ref()!=null:return false
	return true

func shutdown()->bool:
	if closing:
		while not shutdown_complete:
			await get_tree().process_frame
		return shutdown_ok
	closing=true
	var references:Array[WeakRef]=shutdown_stream_refs()
	if is_instance_valid(crossfade):crossfade.kill()
	for voice:Node in get_children():
		if voice is AudioStreamPlayer:
			(voice as AudioStreamPlayer).stop()
			(voice as AudioStreamPlayer).stream=null
		elif voice is AudioStreamPlayer3D:
			(voice as AudioStreamPlayer3D).stop()
			(voice as AudioStreamPlayer3D).stream=null
			# Godot4.7 stop() retains a just-queued3D setplayback until this player is freed.
			# Exit is terminal, so dispose its spatial voices rather than retaining that hidden reference.
			voice.queue_free()
	spatial_players.clear()
	streams.clear()
	current_music=""
	current_finale=""
	music_index=-1
	ambience=null
	# AudioServer drops playback ownership on its mixer thread, not simulated time.
	var deadline:int=Time.get_ticks_msec()+5000
	while not shutdown_refs_released(references):
		if Time.get_ticks_msec()>=deadline:
			shutdown_complete=true
			return false
		await get_tree().process_frame
		OS.delay_msec(1)
	shutdown_ok=true
	shutdown_complete=true
	return true
