extends "res://tests/AudioCleanTree.gd"
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",message)
func run() -> void:
	await process_frame
	var audio:Node=root.get_node("AudioManager")
	check(audio.has_method("play_finale"),"Musical finales have dedicated playback")
	if not audio.has_method("play_finale"):
		finish_test(1)
		return
	var moods:Array=audio.catalog.music.keys()
	audio.play_music(moods[0],0)
	await process_frame
	audio.play_music(moods[1],0.1)
	await create_timer(0.15).timeout
	check(audio.current_music==moods[1],"Crossfade reaches the requested distinct mood")
	check(audio.music_players.filter(func(p):return p.playing).size()==1,"Completed crossfade stops the outgoing voice")
	audio.play_music(moods[2],0.1)
	audio.play_music(moods[3],0.1)
	await create_timer(0.15).timeout
	check(audio.current_music==moods[3],"Rapid mood changes retain the latest request")
	audio.play_finale(true)
	await create_timer(0.8).timeout
	check(audio.finale_player.playing and audio.finale_player.bus=="Music","Victory cue plays on the real music bus")
	check(audio.finale_player.stream.loop_mode==AudioStreamWAV.LOOP_DISABLED,"Finale cue never loops")
	check(audio.music_players.filter(func(p):return p.playing).is_empty(),"Background fades out below the finale")
	audio.play_music(moods[0],0)
	check(not audio.finale_player.playing,"Returning to gameplay stops the musical finale")
	audio.play_finale(false)
	check(audio.current_finale=="defeat","Defeat has a different musical cue")
	audio.set_bus_volume("Music",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Music mute also silences the finale")
	if OS.get_environment("GAME_AUDIO_MUTED")=="1":check(AudioServer.is_bus_mute(0),"QA remains inaudible through all transitions")
	print("MUSIC TRANSITIONS RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
