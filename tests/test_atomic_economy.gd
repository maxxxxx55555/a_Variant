extends SceneTree
const Guard=preload("res://scripts/security/SaveGuard.gd")
var failures:=0
var observed_writes:Array[bool]=[]
var observed_loads:Array[Dictionary]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func checkpoint() -> void:
    var save:Node=root.get_node("SaveSystem")
    var state:Node=root.get_node("GameState")
    var economy:Node=root.get_node("EconomySystem")
    observed_writes.append(save._store(save.SAVE_PATH,{"inventory":state.inventory,"equipment":{},"simulation":{"stockpiles":economy.stockpiles}}))
    observed_loads.append(save.load_slot(0))
func run() -> void:
    await process_frame
    var economy:Node=root.get_node("EconomySystem")
    var campaign:Node=root.get_node("CampaignSystem")
    var workshop:Node=root.get_node("WorkshopSystem")
    var state:Node=root.get_node("GameState")
    var save:Node=root.get_node("SaveSystem")
    var bus:Node=root.get_node("EventBus")
    economy.stockpiles={"food":150.0,"wood":80.0,"ore":40.0,"stone":50.0,"gold":200.0}
    var before:Dictionary=economy.stockpiles.duplicate()
    for cost in [{"gold":-1},{"gold":INF},{"wood":1,"gold":100000}]:
        check(not campaign.pay(cost) and before==economy.stockpiles,"Rejected cost is atomic")
    economy.stockpiles.wood=NAN
    check(not campaign.pay({"wood":1}),"Nonfinite resource balance cannot enter a transaction")
    economy.stockpiles=before.duplicate();economy.stockpiles.wood=1.0e12
    before=economy.stockpiles.duplicate()
    check(not workshop.trade("wood",1,true) and before==economy.stockpiles,"Resource cap rejects trade before charging gold")
    economy.stockpiles.wood=80
    state.inventory=[];workshop.levels={"forge":1}
    check(save._store(save.SAVE_PATH,{"inventory":[],"equipment":{}}),"Initial checkpoint")
    bus.settlement_updated.connect(checkpoint)
    check(workshop.craft("dagger_hardened"),"Ordinary crafting works")
    check(observed_writes==[false] and observed_loads==[{}],"Save/load cannot observe a partially paid crafting transaction")
    observed_writes.clear();observed_loads.clear()
    check(workshop.trade("wood",1,true),"Ordinary trade works")
    check(not observed_writes.is_empty() and not observed_writes[0] and observed_loads[0].is_empty(),"Save/load cannot observe a partially paid trade")
    bus.settlement_updated.disconnect(checkpoint)
    var inventory: Array=state.inventory.duplicate(true)
    before=economy.stockpiles.duplicate()
    var payload:Dictionary={"hp":75,"inventory":inventory,"equipment":{},"simulation":{"stockpiles":before}}
    check(save._store(save.SAVE_PATH,payload),"Complete transaction checkpoint saves")
    var loaded:Dictionary=save.load_slot(0)
    state.restore_items(loaded.inventory,{})
    economy.stockpiles=loaded.simulation.stockpiles
    check(JSON.stringify(state.inventory)==JSON.stringify(inventory) and economy.stockpiles==before,"Crafted items and payment round trip together without duplication")
    state.inventory=[]
    var potion:Resource=load("res://data/potions/health_potion.tres")
    check(state.add_item(potion,10000),"Maximum potion stack accepted")
    check(not state.add_item(potion,10001) and not state.add_item(potion,-1),"Potion stack overflow and negative additions rejected")
    for item in state.inventory:check(item.count<=10000 and item.count>0,"Every potion stack remains within bounds")
    var audio:Node=root.get_node("AudioManager")
    for player in audio.effect_players+audio.music_players:
        player.stop();player.stream=null
    audio.streams.clear()
    await create_timer(0.3).timeout
    for frame in 10:await process_frame
    print("ATOMIC ECONOMY RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
