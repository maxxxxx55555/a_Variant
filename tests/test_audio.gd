extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	await process_frame
	var audio: Node = root.get_node("AudioManager")
	check(audio.has_method("play_at"), "World sounds use spatial playback")
	check(audio.has_method("play_music"), "Music responds to exploration and combat")
	if audio.has_method("play_at"):
		var voice = audio.play_at("swing", Vector3(3, 1, -4))
		check(voice is AudioStreamPlayer3D, "A weapon sound is positioned in the 3D world")
		check(voice.global_position == Vector3(3, 1, -4), "Sound is emitted at the source instead of the listener")
		check(voice.bus == "SFX_Combat", "Combat effects use their own mix bus")
		check(voice.stream is AudioStreamWAV, "Sword swings have a designed sound instead of a sine tone")
		audio.play_music("exploration", 0.0)
		await process_frame
		check(audio.current_music == "exploration", "Exploration selects its music theme")
		audio.play_music("combat", 0.05)
		await create_timer(0.1).timeout
		check(audio.current_music == "combat", "Combat transitions to the combat theme")
		check(audio.music_players.filter(func(player): return player.playing).size() == 1, "Finished crossfade stops the previous music voice")
		var settings: Node = root.get_node("SettingsManager")
		settings.sfx_volume = 0.3
		settings.apply_settings()
		if OS.get_environment("GAME_AUDIO_MUTED") == "1":
			check(AudioServer.is_bus_mute(0), "Silent QA stays muted when settings reapply master volume")
		check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX")), 0.3), "The saved effects slider controls the spatial effect group")
	print("AUDIO RESULT: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
