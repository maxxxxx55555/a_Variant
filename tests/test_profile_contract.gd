extends SceneTree
var failures:int=0
var world:Node3D
var save:Node
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func digest(value:Variant)->String:return JSON.stringify(save._normalize_numbers(value),"",true,true).sha256_text()
func profile()->Dictionary:
    var state:Node=root.get_node("GameState")
    return {"hp":state.player_hp,"stamina":state.player_stamina,"inventory":state.inventory.duplicate(true),"equipment":state.equipment.duplicate(true),"simulation":world.pause_menu.capture_simulation(),"world":world.get_world_state()}
func run()->void:
    await process_frame
    root.get_node("CampaignSystem").new_campaign(1,false)
    save=root.get_node("SaveSystem")
    world=load("res://scenes/world/march.tscn").instantiate();root.add_child(world);current_scene=world
    await process_frame;await physics_frame
    world.toggle_pause()
    check(root.get_node("WorkshopSystem").build("farm"),"Profile includes a real paid workshop building")
    check(root.get_node("ArmySystem").recruit("militia_spear",3),"Profile includes a real recruited army")
    root.get_node("ArmySystem").visual_timer=0
    root.get_node("ArmySystem")._process(0.5)
    root.get_node("SettlementSystem").set_law("rations","half")
    root.get_node("WeatherSystem").set_weather(1)
    var before:Dictionary=profile()
    var fingerprint:String=digest(before)
    Input.action_press("move_forward");Input.action_press("attack")
    await create_timer(0.15,true,false,true).timeout
    Input.action_release("move_forward");Input.action_release("attack")
    check(paused and digest(profile())==fingerprint,"Pause blocks player combat, movement, effects, calendar and every simulation system")
    for language:String in ["en","ru"]:
        root.get_node("LocalizationManager").set_language(language)
        check(digest(profile())==fingerprint,"Live localization preserves the complete campaign state: "+language)
    check(world.pause_menu._on_save(),"Actual pause menu saves the complete campaign")
    var loaded:Dictionary=save.load_game()
    check(digest(loaded)==fingerprint,"Authenticated full campaign payload hash round trip")
    root.get_node("EconomySystem").stockpiles.gold=0
    root.get_node("WorkshopSystem").levels.clear()
    root.get_node("GameState").inventory.clear()
    world.apply_snapshot(loaded)
    var after:Dictionary=profile()
    for field:String in before:
        check(digest(before[field])==digest(after[field]),"Live campaign state hash round trip: "+field)
    var prior_simulation:Dictionary=before.simulation
    var restored_simulation:Dictionary=after.simulation
    for field:String in prior_simulation:check(digest(prior_simulation[field])==digest(restored_simulation[field]),"Simulation state hash round trip: "+field)
    world.queue_free();paused=false;await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.current_music="";audio.current_finale="";audio.music_index=-1;audio.streams.clear()
    await create_timer(0.3).timeout
    for frame:int in 10:await process_frame
    print("PROFILE CONTRACT RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
