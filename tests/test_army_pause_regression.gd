extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func positions(army:Node)->Array:
    var points:Array=[]
    for actor:Node3D in army.visual_actors:points.append(actor.global_position)
    return points
func run()->void:
    await process_frame
    var world:Node3D=load("res://scenes/world/test_location.tscn").instantiate()
    root.add_child(world);current_scene=world
    await process_frame;await physics_frame
    var army:Node=root.get_node("ArmySystem")
    check(army.recruit("militia_spear",3),"Recruit ordinary citizens for the pause regression")
    army.visual_timer=0;army._process(0.5)
    check(army.visual_actors.size()==3,"Three real soldiers exist before pausing")
    world.toggle_pause()
    var before:Array=positions(army)
    await create_timer(0.25,true,false,true).timeout
    check(paused and positions(army)==before,"Paused council freezes every recruited soldier instead of inheriting the always-running menu owner")
    world.toggle_pause()
    await create_timer(0.25,true,false,true).timeout
    check(not paused and positions(army)!=before,"Resuming re-enables ordinary soldier movement")
    world.queue_free();await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.current_music="";audio.current_finale="";audio.music_index=-1;audio.streams.clear()
    await create_timer(0.3).timeout
    for frame:int in 10:await process_frame
    print("ARMY PAUSE REGRESSION RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
