extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func quiet(audio:Node) -> void:
    for p in audio.effect_players:p.stop()
func has_error(audio:Node) -> bool:
    for p in audio.effect_players:
        if p.playing and p.stream==audio._stream("ui_error"):return true
    return false
func run() -> void:
    await process_frame
    var audio:Node=root.get_node("AudioManager")
    var state:Node=root.get_node("GameState")
    state.inventory.clear()
    var screen:Control=load("res://scenes/ui/alchemy_ui.tscn").instantiate()
    root.add_child(screen)
    quiet(audio)
    screen._on_brew_pressed()
    check(has_error(audio),"A stale brew activation reports the actual unavailable result")
    check(state.inventory.is_empty(),"Failed feedback never manufactures ingredients")
    screen.queue_free()
    var economy:Node=root.get_node("EconomySystem")
    economy.stockpiles.gold=0
    var council:Control=load("res://scripts/ui/StrategyUI.gd").new()
    root.add_child(council)
    for key in ["ui.recruit","ui.sign_treaty","ui.gift"]:
        quiet(audio)
        for control in council.find_children("*","Button",true,false):
            if control.get_meta("text_key","")==key:control.pressed.emit();break
        check(has_error(audio),"Rejected council action has error feedback: "+key)
    quiet(audio)
    council.campaign_panels.building_buttons.forge.pressed.emit()
    check(has_error(audio),"Rejected construction has error feedback")
    quiet(audio)
    council.campaign_panels.craft_list.select(0)
    council.campaign_panels.craft_button.pressed.emit()
    check(has_error(audio),"Rejected equipment craft has error feedback")
    var town:Control=load("res://scripts/ui/TownMenu.gd").new()
    root.add_child(town)
    quiet(audio)
    for control in town.find_children("*","Button",true,false):
        if control.get_meta("trade_resource","")=="food" and control.get_meta("text_key","")=="ui.buy":control.pressed.emit();break
    check(has_error(audio),"Rejected town purchase has error feedback")
    council.queue_free()
    town.queue_free()
    for player in audio.effect_players+audio.music_players:
        player.stop()
        player.stream=null
    audio.streams.clear()
    await create_timer(0.25).timeout
    for index in 10:await process_frame
    print("CONTEXT AUDIO RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
