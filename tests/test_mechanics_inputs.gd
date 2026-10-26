extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var campaign:Node=root.get_node("CampaignSystem")
    var state:Node=root.get_node("GameState")
    var economy:Node=root.get_node("EconomySystem")
    var pop:Node=root.get_node("PopulationSystem")
    var laws:Node=root.get_node("SettlementSystem")
    var shop:Node=root.get_node("WorkshopSystem")
    var alchemy:Node=root.get_node("AlchemySystem")
    var army:Node=root.get_node("ArmySystem")
    var diplomacy:Node=root.get_node("DiplomacySystem")
    var weather:Node=root.get_node("WeatherSystem")
    campaign.new_campaign(1,false)
    var original_jobs:Dictionary=pop.jobs.duplicate()
    for click:int in 20:pop.update_worker_assignments({"farmers":-1})
    check(pop.jobs==original_jobs,"Rapid invalid job assignments do not mutate the workforce")
    for click:int in 20:pop.update_worker_assignments({"farmers":1000000})
    var assigned:int=0
    for number:int in pop.jobs.values():assigned+=number
    check(assigned<=pop.total_population and pop.available_workers>=0,"Repeated maximum job input never overassigns citizens")
    for law:String in ["taxes","rations","conscription"]:
        var value:String="high" if law=="taxes" else "half" if law=="rations" else "forced"
        for click:int in 20:laws.set_law(law,value)
        check(laws.current_laws[law]==value,"Repeated law selection is idempotent: "+law)
        for click:int in 20:laws.set_law(law,"")
        check(laws.current_laws[law]==value,"Empty law values cannot corrupt a valid selection: "+law)
    campaign.new_campaign(1,false)
    economy.stockpiles.gold=1000000;economy.stockpiles.wood=1000000;economy.stockpiles.ore=1000000;economy.stockpiles.stone=1000000
    var builds:int=0
    for click:int in 20:if shop.build("farm"):builds+=1
    var cap:int=0
    for definition:Dictionary in shop.definitions:
        if definition.id=="farm":cap=definition.max_level
    check(builds==cap and shop.levels.farm==cap,"Rapid construction stops exactly at the building cap")
    var gold:float=economy.stockpiles.gold
    for click:int in 20:check(not shop.build("") and not shop.craft(""),"Empty construction and craft IDs are rejected")
    check(economy.stockpiles.gold==gold,"Rejected construction never charges money")
    economy.stockpiles.wood=0;gold=economy.stockpiles.gold
    for click:int in 20:check(shop.trade("wood",1,true),"Separate valid trade clicks are paid transactions")
    check(economy.stockpiles.wood==20 and economy.stockpiles.gold==gold-60,"Twenty purchases deliver exactly twenty units and charge once each")
    gold=economy.stockpiles.gold
    for quantity:int in [0,-1,1001,9223372036854775807]:check(not shop.trade("wood",quantity,true),"Trade quantity bounds reject overflow and nonpositive input")
    check(economy.stockpiles.gold==gold,"Invalid trade quantities never debit gold")
    state.inventory.clear()
    var recipe:Resource=alchemy.known_recipes[0]
    check(not alchemy.brew_potion(null),"Empty alchemy recipe is rejected")
    for index:int in recipe.required_ingredients.size():check(state.add_item(recipe.required_ingredients[index],recipe.required_counts[index]),"Prepare one real recipe")
    var brewed:int=0
    for click:int in 20:if alchemy.brew_potion(recipe):brewed+=1
    check(brewed==1,"Rapid brewing cannot reuse consumed ingredients")
    state.inventory.clear();state.player_hp=20
    check(state.add_item(load("res://data/potions/health_potion.tres")),"Obtain one healing potion")
    var used:int=0
    for click:int in 20:if state.use_potion(0):used+=1
    check(used==1 and state.player_hp>20 and state.player_hp<=state.max_hp,"Rapid potion input consumes one owned item without overflow")
    check(not state.equip_item(-1) and not state.equip_item(1000000) and not state.unequip_item(""),"Empty and out-of-range equipment selections are safe")
    campaign.new_campaign(1,false)
    var recruits:int=0
    for click:int in 20:if army.recruit("militia_spear",1):recruits+=1
    check(recruits==5 and army.get_total_soldiers()==5 and pop.available_workers==0,"Rapid recruitment stops when all five available citizens are enlisted")
    for order:String in army.ORDERS:
        for click:int in 20:army.issue_order_to_selected(order)
        check(army.squads[0].order==order,"Repeated valid army orders remain stable: "+order)
    for formation:String in army.FORMATIONS:
        for click:int in 20:army.set_formation_for_selected(formation)
        check(army.squads[0].formation==formation,"Repeated formations remain stable: "+formation)
    for click:int in 20:army.disband_selected()
    check(army.get_total_soldiers()==0 and pop.available_workers==5,"Repeated disband releases each citizen exactly once")
    economy.stockpiles.gold=1000
    root.get_node("FactionSystem").factions.iron_guild.relationship=70
    var treaties:int=0
    for click:int in 20:if diplomacy.propose_treaty("iron_guild","alliance"):treaties+=1
    check(treaties==1,"Rapid treaty signing cannot repeat its cost or reward")
    gold=economy.stockpiles.gold
    for amount:int in [0,-1,9223372036854775807]:check(not diplomacy.give_gift("iron_guild",amount),"Gift amount bounds reject invalid and unaffordable inputs")
    check(economy.stockpiles.gold==gold,"Rejected gift preserves the treasury")
    for kind:int in 5:
        for click:int in 20:weather.set_weather(kind)
        check(weather.current_weather==kind and is_finite(weather.movement_speed_modifier),"Repeated supported weather changes keep finite modifiers")
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.streams.clear()
    await create_timer(0.3).timeout
    print("MECHANICS INPUTS RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
