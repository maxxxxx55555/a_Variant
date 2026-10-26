extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func actors(world:Node3D)->Array[Node]:
    var found:Array[Node]=[]
    var companion_script:Script=load("res://scripts/ai/CompanionActor.gd")
    for child:Node in world.get_children():
        if child.get_script()==companion_script and not child.is_queued_for_deletion():found.append(child)
    return found
func run()->void:
    await process_frame
    var campaign:Node=root.get_node("CampaignSystem")
    campaign.new_campaign(1,false)
    var world:Node3D=load("res://scenes/world/march.tscn").instantiate();root.add_child(world);current_scene=world
    await process_frame
    campaign.companions.append("warrior_shield")
    for scan:int in 25:world._process(0.6)
    check(world.companion_actors.size()==1,"A recruited companion retains its tracked handle through repeated scans")
    check(actors(world).size()==1,"Repeated world scans create exactly one actor for one companion, without hidden duplicates")
    var saved:Dictionary=world.get_world_state()
    check(saved.companions.size()==1,"The sole live companion is represented exactly once in the save snapshot")
    world.toggle_pause()
    var stable:Dictionary=world.get_world_state()
    var frozen:String=JSON.stringify(stable,"",true,true).sha256_text()
    await create_timer(0.15,true,false,true).timeout
    check(paused and JSON.stringify(world.get_world_state(),"",true,true).sha256_text()==frozen,"Paused companion and world state cannot advance")
    for language:String in ["en","ru"]:
        root.get_node("LocalizationManager").set_language(language)
        check(JSON.stringify(world.get_world_state(),"",true,true).sha256_text()==frozen,"Live language changes preserve companion identity and state")
    var saves:Node=root.get_node("SaveSystem")
    check(world.pause_menu._on_save(),"A real recruited-companion profile saves")
    var loaded:Dictionary=saves.load_game()
    check(JSON.stringify(saves._normalize_numbers(stable),"",true,true).sha256_text()==JSON.stringify(loaded.get("world",{}),"",true,true).sha256_text(),"Companion world state hash survives authenticated save/load exactly")
    world.toggle_pause()
    campaign.companions.clear();world._process(0.6)
    await process_frame
    check(world.companion_actors.is_empty() and actors(world).is_empty(),"Removing a companion releases its only actor and tracked handle")
    world.queue_free();paused=false;await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.current_music="";audio.current_finale="";audio.music_index=-1;audio.streams.clear()
    await create_timer(0.3).timeout
    for frame:int in 10:await process_frame
    print("COMPANION SCAN REGRESSION RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
