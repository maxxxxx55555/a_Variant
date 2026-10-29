extends "res://tests/AudioCleanTree.gd"

var failures := 0

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	await process_frame
	var campaign: Node = root.get_node("CampaignSystem")
	var siege: Node = root.get_node_or_null("SiegeSystem")
	check(siege != null, "Sieges have a persistent simulation")
	if not siege:
		finish_test(1)
		return
	campaign.new_campaign(1, false)
	var army: Node = root.get_node("ArmySystem")
	var economy: Node = root.get_node("EconomySystem")
	var fid: String = campaign.definition.factions[0].id
	check(not siege.begin("missing"), "Unknown faction cannot consume supplies")
	check(not siege.begin(fid), "A blockade requires three actual recruited soldiers")
	check(army.recruit("militia_spear", 3), "Siege troops are recruited through the ordinary economy")
	var food: float = economy.stockpiles.food
	check(siege.begin(fid), "A supplied army can establish a blockade")
	check(economy.stockpiles.food == food - 12, "Blockade setup consumes actual provisions")
	var gold: float = economy.stockpiles.gold
	check(not siege.begin(fid) and economy.stockpiles.gold == gold, "Duplicate blockade is transactional")
	check(not siege.offer_surrender(fid), "Fresh garrison does not surrender immediately")
	check(not campaign.capture_faction(fid), "A blockade alone cannot capture a faction")
	siege._on_day_passed(2)
	check(siege.states[fid].supplies < 100 and siege.states[fid].days == 1, "A maintained blockade depletes defender supplies each day")
	var saved: Dictionary = campaign.capture_state()
	siege.states.clear()
	campaign.restore_state(saved)
	check(siege.states.has(fid) and siege.states[fid].days == 1, "Campaign save restores siege progress")
	check(not siege.damage_gate(fid, -100), "Negative damage cannot repair walls or mint progress")
	check(siege.launch_assault(fid), "Prepared blockade can become an assault")
	for guard_id in campaign.camp_ids(fid, true): campaign.fallen.append(guard_id)
	check(not campaign.capture_faction(fid), "Killing three guards cannot bypass an intact gate")
	check(siege.damage_gate(fid, 500), "An assault gate accepts real weapon damage")
	check(fid in campaign.conquests, "Breached defenses and defeated garrison secure the faction")
	gold = economy.stockpiles.gold
	check(not campaign.capture_faction(fid) and economy.stockpiles.gold == gold, "Victory reward cannot be claimed twice")
	campaign.new_campaign(1, false)
	army.recruit("militia_spear", 3)
	siege.begin(fid)
	for day in 4: siege._on_day_passed(day + 2)
	check(siege.offer_surrender(fid), "Starved garrison accepts a maintained blockade's surrender terms")
	check(fid in campaign.conquests and campaign.camp_cleared(fid, true), "Surrender completes military objectives without phantom guards")
	campaign.new_campaign(1, false)
	army.recruit("militia_spear", 3)
	siege.begin(fid)
	economy.stockpiles.food = 0
	siege._on_day_passed(2)
	check(not siege.states.has(fid), "An unsupplied besieging army must lift its blockade")
	print("SIEGE RESULT: ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	finish_test(0 if failures == 0 else 1)
