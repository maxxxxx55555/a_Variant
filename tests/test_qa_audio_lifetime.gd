extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func warm_audio(audio:Node)->void:
    for mood:String in ["exploration","settlement","combat","war"]:
        @warning_ignore("return_value_discarded")
        audio._stream(mood,true)
    for cue:String in ["ui_click","ui_focus","ui_error","attack","hit_metal","footstep_grass_0","ambience_forest","victory"]:
        @warning_ignore("return_value_discarded")
        audio._stream(cue)
func start_audio(audio:Node)->void:
    for mood:String in ["exploration","settlement","combat","war"]:audio.play_music(mood,0.0)
    for index:int in 32:
        @warning_ignore("return_value_discarded")
        audio.play_sfx(["ui_click","ui_focus","ui_error","attack","hit_metal"][index%5])
        @warning_ignore("return_value_discarded")
        audio.play_at(["attack","hit_metal","footstep_grass_0"][index%3],Vector3.ZERO)
    audio.start_ambience("forest",Vector3.ZERO)
    audio.play_finale(true)
func audio_refs(audio:Node)->Array[WeakRef]:
    var refs:Array[WeakRef]=[]
    for stream:Variant in audio.streams.values():refs.append(weakref(stream))
    return refs
func run()->void:
    await process_frame
    var audio:Node=root.get_node("AudioManager")
    var route:Node=load("res://tests/QAAudioRoute.gd").new()
    root.add_child(route)
    for cycle_index:int in 2:
        warm_audio(audio)
        start_audio(audio)
        await process_frame
        @warning_ignore("return_value_discarded")
        audio.play_at("potion",Vector3.ZERO)
        var refs:Array[WeakRef]=audio_refs(audio)
        check(refs.size()>=10,"Regression exercises real music, finale, interface, spatial and ambience streams")
        var started:int=Time.get_ticks_msec()
        await route.settle_audio()
        var alive:int=0
        for reference:WeakRef in refs:
            if reference.get_ref()!=null:alive+=1
        check(alive==0,"Private campaign shutdown releases actual mixer-owned resources before quit")
        check(not route.failed,"Bounded shutdown failure propagates to private verifier result")
        check(audio.streams.is_empty(),"Private shutdown clears the stream cache")
        for voice:Node in audio.get_children():
            if voice is AudioStreamPlayer:check((voice as AudioStreamPlayer).stream==null,"2D players release their stream")
            elif voice is AudioStreamPlayer3D:check((voice as AudioStreamPlayer3D).stream==null,"Spatial and ambience players release their stream")
        print("QA AUDIO SETTLE: alive=",alive," elapsed_wall_ms=",Time.get_ticks_msec()-started)
    print("QA AUDIO LIFETIME RESULT: ","PASS" if failures==0 else "FAIL")
    route.queue_free()
    await process_frame
    quit(0 if failures==0 else 1)
