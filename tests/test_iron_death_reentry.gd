extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var campaign:Node=root.get_node("CampaignSystem")
    var state:Node=root.get_node("GameState")
    var saves:Node=root.get_node("SaveSystem")
    campaign.new_campaign(1,true)
    var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
    root.add_child(world);current_scene=world
    await process_frame;await physics_frame
    check(world.pause_menu._on_save(),"Iron expedition saves before ordinary damage")
    state.take_damage(1000)
    check(campaign.iron_dead and state.player_hp==0 and paused,"Real damage reaches the terminal iron death state")
    check(world.pause_menu.resume_btn.disabled and world.pause_menu.load_btn.disabled,"Death blocks revival and manual rewind")
    var tombstone:Dictionary=saves.load_slot(6)
    check(tombstone.get("simulation",{}).get("campaign",{}).get("iron_dead",false),"Authenticated iron tombstone persists")
    var raw:PackedByteArray=FileAccess.get_file_as_bytes(saves.slot_path(6))
    var deaths:Array[int]=[0]
    var repeat_listener:Callable=func()->void:deaths[0]+=1
    root.get_node("EventBus").player_died.connect(repeat_listener)
    for hit:int in 20:state.take_damage(1)
    root.get_node("EventBus").player_died.disconnect(repeat_listener)
    check(deaths[0]==0,"Late hits cannot emit another death after the terminal transition")
    var stamina:float=state.player_stamina
    Input.action_press("block")
    for hit:int in 20:world.player.take_damage(1)
    Input.action_release("block")
    check(state.player_stamina==stamina,"A terminal character cannot spend blocking stamina on late hits")
    check(FileAccess.get_file_as_bytes(saves.slot_path(6))==raw,"Late damage cannot alter the iron tombstone")
    for click:int in 20:
        world.pause_menu._on_load()
        world.pause_menu._on_resume()
        world.restart_run()
    check(campaign.iron_dead and state.player_hp==0,"Stale load callback cannot revive an iron character")
    check(FileAccess.get_file_as_bytes(saves.slot_path(6))==raw,"Rejected rewind never rewrites the terminal save")
    for language:String in ["en","ru"]:
        root.get_node("LocalizationManager").set_language(language)
        check(world.pause_menu.resume_btn.text==root.get_node("LocalizationManager").get_string("ui.iron_end_label"),"Iron death retains its short terminal label after live locale changes")
        check(world.pause_menu.resume_btn.tooltip_text==root.get_node("LocalizationManager").get_string("ui.iron_dead"),"Disabled revival explains the final death in the active locale")
        check(world.pause_menu.save_btn.tooltip_text==root.get_node("LocalizationManager").get_string("ui.iron_dead"),"Disabled terminal save explains its reason")
        if DisplayServer.get_name()!="headless" and OS.get_environment("GAME_CAPTURE_GALLERY")=="1":
            await process_frame
            await RenderingServer.frame_post_draw
            check(root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-"+language+".png"))==OK,"Terminal gallery capture saves its real framebuffer")
    var escape:InputEventKey=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
    Input.parse_input_event(escape);await process_frame
    escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.physical_keycode=KEY_ESCAPE;escape.pressed=false
    Input.parse_input_event(escape);await process_frame
    check(paused and state.player_hp==0,"Escape cannot revive or resume a terminal iron character")
    var back:Button=world.pause_menu.find_child("ToMenuButton",true,false)
    check(back!=null and not back.disabled,"The terminal screen has an enabled return-to-title action")
    if back:back.pressed.emit()
    for frame:int in 120:
        await process_frame
        if not is_instance_valid(world):break
    check(not is_instance_valid(world) and current_scene!=null and current_scene.get_script().resource_path=="res://scripts/ui/MainMenu.gd","The actual terminal Back action reaches the title")
    if is_instance_valid(world):world.queue_free()
    elif current_scene:current_scene.queue_free()
    paused=false;await process_frame
    # Ordinary non-iron death keeps the paid recovery path.
    campaign.new_campaign(1,false)
    world=load("res://scenes/world/march.tscn").instantiate();root.add_child(world);current_scene=world
    await process_frame
    state.take_damage(1000)
    check(not world.pause_menu.resume_btn.disabled,"Ordinary death retains a recovery action")
    check(world.pause_menu.save_btn.tooltip_text==root.get_node("LocalizationManager").get_string("ui.save_after_respawn"),"Ordinary death explains why saving is unavailable")
    var gold:float=root.get_node("EconomySystem").stockpiles.gold
    world.pause_menu._on_resume()
    check(state.player_hp==state.max_hp and not paused and is_equal_approx(root.get_node("EconomySystem").stockpiles.gold,gold*0.8),"Ordinary paid recovery still restores health and charges its disclosed cost")
    world.queue_free();paused=false;await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.streams.clear()
    await create_timer(0.3).timeout
    print("IRON DEATH REENTRY RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
