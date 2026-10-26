extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var world:Node3D=load("res://scenes/world/test_location.tscn").instantiate()
    root.add_child(world);current_scene=world
    await process_frame;await physics_frame
    var army:Node=root.get_node("ArmySystem")
    army.set_process(false)
    check(army.recruit("militia_spear",3),"Recruit three ordinary soldiers")
    army.visual_timer=0;army._process(0.5)
    check(army.visual_actors.size()==3,"All recruited soldiers have real actors")
    var lost:Node=army.visual_actors[0]
    lost.queue_free()
    await process_frame;await process_frame
    check(not is_instance_valid(lost),"A casualty has actually been destroyed before the roster refresh")
    army.visual_timer=0;army._process(0.5)
    var valid_count:int=0
    for actor in army.visual_actors:
        if is_instance_valid(actor) and not actor.is_queued_for_deletion():valid_count+=1
    check(army.visual_actors.size()==3 and valid_count==3,"Refresh removes freed references and restores the three living representatives without a typed callback error")
    army.disband_selected()
    army.visual_timer=0;army._process(0.5)
    await process_frame;await process_frame
    army.visual_timer=0;army._process(0.5)
    check(army.visual_actors.is_empty(),"Disbanded actor references are removed on the following refresh")
    world.queue_free();await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.current_music="";audio.current_finale="";audio.music_index=-1;audio.streams.clear()
    await create_timer(0.3).timeout
    for frame:int in 10:await process_frame
    print("ARMY CASUALTY LIFETIME RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
