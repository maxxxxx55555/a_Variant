extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func stock_hash(economy:Node)->String:return JSON.stringify(economy.stockpiles,"",true,true).sha256_text()
func run()->void:
    await process_frame
    var campaign:Node=root.get_node("CampaignSystem")
    var economy:Node=root.get_node("EconomySystem")
    campaign.new_campaign(1,false)
    for forged:Dictionary in [{"id":"made_up", "kind":"shrine", "faction":"iron_guild"},{"id":"", "kind":"ruin", "faction":"iron_guild"},{"id":false, "kind":"ruin", "faction":"iron_guild"}]:
        var before:String=stock_hash(economy)
        var progress:Array=campaign.explored.duplicate()
        check(not campaign.explore(forged),"Reject forged exploration catalog entry")
        check(stock_hash(economy)==before and campaign.explored==progress,"Forged exploration cannot mint supplies or progression")
    var camp:Dictionary={}
    var ordinary:Dictionary={}
    for point:Dictionary in campaign.definition.points:
        if point.kind=="camp":camp=point
        elif ordinary.is_empty():ordinary=point
    var changed:Dictionary=camp.duplicate(true);changed.kind="shrine"
    check(not campaign.explore(changed),"Changing a real camp kind cannot bypass its combat requirement")
    check(campaign.explore(ordinary),"A real catalog landmark grants ordinary exploration rewards")
    var earned:String=stock_hash(economy)
    for click:int in 20:check(not campaign.explore(ordinary),"Repeated landmark activation is idempotent")
    check(stock_hash(economy)==earned,"Rapid repeat exploration cannot duplicate rewards")
    campaign.new_campaign(1,false)
    economy.stockpiles.food=1.0e12
    var capped:String=stock_hash(economy)
    check(not campaign.explore(ordinary) and stock_hash(economy)==capped and campaign.explored.is_empty(),"Reward overflow is rejected before marking a landmark or changing any resource")
    var audio:Node=root.get_node("AudioManager")
    if audio.crossfade!=null:audio.crossfade.kill()
    for voice:Node in audio.get_children():
        if voice is AudioStreamPlayer:voice.stop();voice.stream=null
        elif voice is AudioStreamPlayer3D:voice.stop();voice.stream=null
    audio.streams.clear()
    await create_timer(0.3).timeout
    print("UNTRUSTED EXPLORATION RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
