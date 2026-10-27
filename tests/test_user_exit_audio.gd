extends SceneTree
var failures:int=0
var refs:Array[WeakRef]=[]
var mode:String="title-exit"
var saved_notices:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func warm_audio(audio:Node)->void:
    for mood:String in ["exploration","settlement","combat","war"]:audio.play_music(mood,0.0)
    for index:int in 24:
        @warning_ignore("return_value_discarded")
        audio.play_sfx(["ui_click","ui_focus","ui_error","attack","hit_metal"][index%5])
        @warning_ignore("return_value_discarded")
        audio.play_at(["attack","hit_metal","footstep_grass_0"][index%3],Vector3.ZERO)
    audio.start_ambience("forest",Vector3.ZERO)
    audio.play_finale(true)
func remember_audio(audio:Node)->void:
    for key:String in audio.streams:refs.append(weakref(audio.streams[key]))
func saved_notice(text:String,_important:bool)->void:
    if text==root.get_node("LocalizationManager").get_string("msg.game_saved"):saved_notices+=1
func before_tree_exit()->void:
    var alive:int=0
    for reference:WeakRef in refs:
        if reference.get_ref()!=null:alive+=1
    check(alive==0,"Normal user shutdown releases actual audio resources before root tree exit")
    print("USER EXIT AUDIO: mode=",mode," alive_before_tree_exit=",alive)
    print("USER EXIT AUDIO RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
func run()->void:
    await process_frame
    for argument:String in OS.get_cmdline_user_args():
        if argument.begins_with("--case="):mode=argument.trim_prefix("--case=")
    var audio:Node=root.get_node("AudioManager")
    var scene:Node
    if mode.begins_with("pause-"):
        root.get_node("CampaignSystem").new_campaign(1,false)
        scene=load("res://scenes/world/march.tscn").instantiate()
    else:scene=load("res://scenes/ui/main_menu.tscn").instantiate()
    root.add_child(scene);current_scene=scene
    await process_frame
    warm_audio(audio)
    await process_frame
    # A real last-moment spatial cue may still be pending when Exit pauses play.
    @warning_ignore("return_value_discarded")
    audio.play_at("potion",Vector3.ZERO)
    remember_audio(audio)
    check(refs.size()>=10,"Normal shutdown exercises real music, UI, spatial, ambience and finale streams")
    @warning_ignore("return_value_discarded")
    root.tree_exiting.connect(before_tree_exit)
    if mode=="title-exit":
        var exit_button:Button
        for control:Node in scene.find_children("*","Button",true,false):
            if control.get_meta("locale_key","")=="ui.exit":exit_button=control as Button
        check(exit_button!=null,"Actual localized title Exit action exists")
        if exit_button:
            for repeat:int in 5:exit_button.pressed.emit()
        else:quit(1)
    elif mode=="title-wm-close":root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
    else:
        scene.toggle_pause()
        var save:Node=root.get_node("SaveSystem")
        var blocked_temp:String=save.slot_path(5)+".tmp"
        check(not FileAccess.file_exists(blocked_temp) and not DirAccess.dir_exists_absolute(blocked_temp),"Failure probe owns a fresh temporary slot target")
        check(DirAccess.make_dir_absolute(blocked_temp)==OK,"A directory blocks the actual selected-slot temporary file write")
        scene.pause_menu._on_exit()
        var transition:Node=root.get_node("MarchTransition")
        var dialog:ConfirmationDialog=transition.unsaved_dialog
        check(is_instance_valid(dialog) and dialog.visible and current_scene==scene,"Failed save keeps the world and offers Retry/Stay/Discard")
        check(not audio.streams.is_empty(),"Failed save does not start terminal audio shutdown")
        dialog.canceled.emit()
        await process_frame
        check(current_scene==scene,"Stay after a failed save keeps the playable scene")
        scene.pause_menu._on_exit()
        dialog=transition.unsaved_dialog
        check(DirAccess.remove_absolute(blocked_temp)==OK,"Repair the actual temporary-file obstruction before retry/discard")
        check(is_instance_valid(dialog) and dialog.visible,"A later exit can retry the failed save")
        @warning_ignore("return_value_discarded")
        root.get_node("EventBus").notification_posted.connect(saved_notice)
        var retained:ConfirmationDialog=dialog
        if mode=="pause-retry":
            retained.confirmed.emit()
            retained.confirmed.emit()
            retained.custom_action.emit("discard")
            check(saved_notices==1,"Accepted Retry ignores repeated confirmed callbacks and late Discard after exit begins")
        else:
            retained.custom_action.emit("discard")
            retained.confirmed.emit()
            check(saved_notices==0,"Accepted Discard ignores a queued Retry without saving")
