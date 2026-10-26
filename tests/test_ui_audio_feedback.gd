extends SceneTree
var failures:=0
var audio:Node
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:
        failures+=1
        print("FAIL: ",message)
func silence() -> void:
    for player in audio.effect_players:player.stop()
func voices(cue:String) -> Array:
    var found:Array=[]
    for player in audio.effect_players:
        if player.playing and player.stream==audio._stream(cue):found.append(player)
    return found
func run() -> void:
    await process_frame
    audio=root.get_node("AudioManager")
    var panel:=VBoxContainer.new()
    root.add_child(panel)
    var ordinary:=Button.new()
    ordinary.text="ordinary fixture"
    panel.add_child(ordinary)
    var contextual:=Button.new()
    contextual.text="context fixture"
    panel.add_child(contextual)
    contextual.pressed.connect(func():audio.play_sfx("purchase"))
    await process_frame
    await process_frame
    check(audio.catalog.sfx.has("ui_focus") and audio.catalog.sfx.has("ui_error"),"Focus and unavailable actions have dedicated contextual assets")
    ordinary.release_focus()
    await create_timer(0.12).timeout
    silence()
    ordinary.grab_focus()
    check(voices("ui_focus").size()==1,"Actual keyboard focus emits one subtle cue")
    if not voices("ui_focus").is_empty():
        check(voices("ui_focus")[0].bus=="SFX_UI" and voices("ui_focus")[0].volume_db<=-18,"Focus uses an independent quiet interface mix")
    contextual.grab_focus()
    check(voices("ui_focus").size()<=1,"Immediate focus traversal is rate limited")
    silence()
    ordinary.button_down.emit()
    ordinary.pressed.emit()
    await process_frame
    await process_frame
    check(voices("ui_click").size()==1,"An ordinary real button receives exactly one fallback click")
    silence()
    contextual.button_down.emit()
    contextual.pressed.emit()
    await process_frame
    await process_frame
    check(voices("purchase").size()==1 and voices("ui_click").is_empty(),"Contextual purchase suppresses the generic click")
    silence()
    ordinary.disabled=true
    ordinary.button_down.emit()
    ordinary.pressed.emit()
    await process_frame
    check(voices("ui_click").is_empty(),"Disabled controls remain quiet")
    ordinary.disabled=false
    ordinary.button_down.emit()
    ordinary.pressed.emit()
    ordinary.free()
    await process_frame
    await process_frame
    check(voices("ui_click").size()==1,"A departing control still acknowledges its completed action")
    var pitches:Array=[]
    seed(92815)
    var expected:=randf()
    seed(92815)
    for index in 16:
        silence()
        var voice=audio.play_sfx("purchase")
        pitches.append(voice.pitch_scale)
    check(randf()==expected,"Feedback never consumes gameplay RNG")
    check(pitches.min()>=0.97 and pitches.max()<=1.03 and not is_equal_approx(pitches.min(),pitches.max()),"Repeated contextual actions have restrained pitch variation")
    check(AudioServer.is_bus_mute(0),"QA stays inaudible through every cue")
    silence()
    panel.queue_free()
    for player in audio.effect_players+audio.music_players:
        player.stop()
        player.stream=null
    audio.streams.clear()
    await create_timer(0.25).timeout
    for index in 10:await process_frame
    print("UI AUDIO FEEDBACK RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
