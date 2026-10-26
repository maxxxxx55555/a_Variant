extends "res://scripts/verification/CampaignRoute.gd"
func profile()->Dictionary:
    return {"hp":state.player_hp,"stamina":state.player_stamina,"inventory":state.inventory.duplicate(true),"equipment":state.equipment.duplicate(true),"simulation":world.pause_menu.capture_simulation(),"world":world.get_world_state()}
func digest(value:Variant)->String:
    var saves:Node=root.get_node("SaveSystem")
    return JSON.stringify(saves._normalize_numbers(value),"",true,true).sha256_text()
func write_qa_result(record:Dictionary)->void:
    var before:Dictionary=profile()
    var fingerprint:String=digest(before)
    if campaign.companions.size()!=4:fail("Full route unlocks exactly four real companions")
    for click:int in 20:
        campaign.refresh()
        for town_id:String in campaign.visited.duplicate():campaign.talk(town_id)
    if digest(profile())!=fingerprint:fail("Repeated completed quest, companion, town report and ending callbacks must not duplicate rewards or state")
    for language:String in ["en","ru"]:
        root.get_node("LocalizationManager").set_language(language)
        if digest(profile())!=fingerprint:fail("Terminal campaign mechanics remain invariant under live locale changes")
    var saves:Node=root.get_node("SaveSystem")
    if not world.pause_menu._on_save():fail("Complete sixty-objective profile saves through its actual pause menu")
    var loaded:Dictionary=saves.load_game()
    if digest(loaded)!=fingerprint:fail("Full completed campaign profile must round trip with identical hash")
    record["mechanics_contract"]="FAIL" if failed else "PASS"
    record["result"]="FAIL" if failed else "PASS"
    super.write_qa_result(record)
