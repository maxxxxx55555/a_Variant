extends SceneTree
var failures:int=0
var deaths:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var state:Node=root.get_node("GameState")
    var weather:Node=root.get_node("WeatherSystem")
    var world:Node3D=load("res://scenes/world/test_location.tscn").instantiate()
    root.add_child(world);current_scene=world;await process_frame
    paused=true
    state.equipment.torso={"resource_path":"res://data/armors/leather_armor.tres","durability":80.0}
    state.recalculate_stats()
    Input.action_press("block")
    for amount:float in [-1.0,0.0,NAN,-INF,INF]:
        state.player_hp=100;state.player_stamina=100
        var durability:float=state.equipment.torso.durability
        world.player.take_damage(amount)
        check(state.player_hp==100 and state.player_stamina==100 and state.equipment.torso.durability==durability,"Invalid incoming damage cannot alter health, block stamina or armor: "+str(amount))
    Input.action_release("block")
    state.player_hp=100;state.player_stamina=100
    for amount:float in [-1.0,0.0,NAN,-INF,INF]:
        state.equipment.torso.durability=80
        state.wear_equipment("torso",amount)
        check(state.equipment.torso.durability==80,"Invalid wear cannot repair free or poison durability: "+str(amount))
    var enemy:Node3D=world.enemy
    for amount:float in [-1.0,0.0,NAN,-INF,INF]:
        enemy.current_hp=enemy.max_hp
        enemy.take_damage(amount)
        check(enemy.current_hp==enemy.max_hp and not enemy.is_dead,"Invalid outgoing damage cannot heal, poison or kill an enemy: "+str(amount))
    # A terminal callback can be reached twice in a frame; it must emit one death/reward.
    var bus:Node=root.get_node("EventBus")
    var listener:Callable=func(_enemy:Node)->void:deaths+=1
    bus.enemy_died.connect(listener)
    enemy.is_dead=false;enemy.die();enemy.die()
    bus.enemy_died.disconnect(listener)
    check(deaths==1,"Repeated terminal callback awards an enemy death only once")
    weather.set_weather(0)
    for invalid:int in [-1,999]:weather.set_weather(invalid);check(weather.current_weather==0,"Unknown weather cannot poison the next save")
    state.player_hp=100
    world.queue_free();paused=false;await process_frame
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.current_music="";audio.current_finale="";audio.music_index=-1;audio.streams.clear()
    await create_timer(0.3).timeout
    for frame:int in 10:await process_frame
    print("INVALID COMBAT INPUTS RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
