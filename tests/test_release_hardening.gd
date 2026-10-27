extends "res://tests/AudioCleanTree.gd"
const Policy = preload("res://scripts/security/MarchSavePolicy.gd")
const Guard = preload("res://scripts/security/SaveGuard.gd")
var failures := 0
var mutation_count := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ",label)
func mutation_paths(value: Variant, path: Array, result: Array) -> void:
	if value is Dictionary:
		for key in value: mutation_paths(value[key],path+[key],result)
	elif value is Array:
		for index in value.size(): mutation_paths(value[index],path+[index],result)
	elif value!=null: result.append(path)
func check_mutations(original: Dictionary) -> void:
	var paths: Array = []
	mutation_paths(original,[],paths)
	for path in paths:
		var changed := original.duplicate(true)
		var cursor: Variant = changed
		for index in path.size()-1: cursor = cursor[path[index]]
		cursor[path.back()] = {}
		mutation_count += 1
		check(not Policy.valid(changed),"Reject wrong type at "+str(path))
func run() -> void:
	await process_frame
	var save: Node = root.get_node("SaveSystem")
	var campaign: Node = root.get_node("CampaignSystem")
	var army: Node = root.get_node("ArmySystem")
	var state: Node = root.get_node("GameState")
	var economy: Node = root.get_node("EconomySystem")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy-MarchlandOaths.json"))
	var original: Dictionary = JSON.parse_string(fixture.data)
	check(Policy.valid(original),"Real shipped profile remains valid")
	print("HARDENING PHASE: original-field mutations")
	check_mutations(original)
	print("HARDENING PHASE: original mutations complete")
	var military_fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/legacy-MarchlandOaths-military.json"))
	print("HARDENING PHASE: military-field mutations")
	check_mutations(JSON.parse_string(military_fixture.data))
	print("HARDENING PHASE: military mutations complete")
	var cases := [
		["timed_effects",{"damage":{"seconds":"bad","value":{}}}],
		["buildings",{"forge":{}}], ["buildings",{"forge":4}],
		["treaties",{"woodland_freeholders":4}],
		["treaty_expiry",{"woodland_freeholders:peace":{}}],
		["factions",{"woodland_freeholders":{"res_path":"res://data/factions/woodland_freeholders.tres","relationship":0,"threat":0,"escalation_level":0,"desired_escalation":{}}}],
		["army",[{"unit_res_path":"res://data/units/militia_spear.tres","count":1,"squad_id":1,"morale":80,"order":"follow","formation":"line","target":[0,0,0],"low_morale_days":{}}]]
	]
	for entry in cases:
		var changed := original.duplicate(true)
		changed.simulation[entry[0]] = entry[1]
		check(not Policy.valid(changed),"Reject nested " + entry[0] + ": " + str(entry[1]))
	for field in ["brewed","sieges"]:
		var changed := original.duplicate(true)
		changed.simulation.campaign[field] = {} if field=="brewed" else {"woodland_freeholders":{"supplies":{},"phase":"invalid"}}
		check(not Policy.valid(changed),"Reject malformed campaign " + field)
	for field in ["campaign_actors","companions","army_actors"]:
		var changed := original.duplicate(true)
		changed.world[field] = [{"id":"woodland_freeholders_raider_0"}]
		check(not Policy.valid(changed),"Require complete actor state for " + field)
	# A public old checksum must not turn malformed data into a loadable migration.
	var malicious := original.duplicate(true)
	malicious.simulation.timed_effects = {"damage":{"seconds":"bad","value":{}}}
	var body := JSON.stringify(malicious)
	var path := "user://malformed-hardening.json"
	DirAccess.remove_absolute(Guard.lock_path(save.purpose(path)))
	check(Guard.atomic_text(path,JSON.stringify({"version":3,"data":body,"checksum":save.calculate_checksum(body)})),"Write bounded legacy regression fixture")
	check(save._read_valid_save(path).is_empty(),"Malformed legacy save is rejected before migration")
	var iron_path: String = save.slot_path(6)
	check(Guard.atomic_text(save.backup_path(iron_path),save._encoded(original,save.purpose(iron_path))),"Prepare obsolete iron-mode backup")
	check(Guard.atomic_text(iron_path,"{interrupted"),"Prepare interrupted iron save")
	check(save.newest_slot()!=6,"Title never selects an iron backup that cannot legally be loaded")
	# Selection survives the title screen and cannot overwrite another manual slot.
	save.selected_slot = 0
	var menu: Node = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	var choices: Array = menu.find_children("*","OptionButton",true,false).filter(func(c): return c.item_count==7)
	check(choices.size()==1,"Find actual title save selector")
	if choices.size()==1:
		choices[0].select(3)
		choices[0].item_selected.emit(3)
		check(save.selected_slot==3,"Title manual slot determines subsequent save target")
	menu.queue_free()
	await process_frame
	campaign.new_campaign(1,false)
	check(army.recruit("militia_spear",1),"Recruit first squad")
	# A previous campaign selected its third squad; only one squad exists now.
	army.selected_squad_index = 2
	campaign.new_campaign(1,false)
	check(army.selected_squad_index==0,"New campaign resets squad selection")
	check(army.recruit("militia_spear",1),"Recruit after restart")
	army.selected_squad_index = 2
	army.set_formation_for_selected("loose")
	check(army.squads[0].formation=="loose","Formation remains safe after loading a smaller roster")
	var before: Dictionary = economy.stockpiles.duplicate()
	check(not campaign.pay({"gold":NAN}) and economy.stockpiles==before,"NaN transaction never poisons the economy")
	economy.stockpiles = before.duplicate()
	check(not campaign.pay({"gold":1,"unknown":0}) and economy.stockpiles==before,"Unknown-resource transaction is atomic")
	var count: int = army.get_total_soldiers()
	army.register_casualty(army.squads[0].squad_id,-2)
	check(army.get_total_soldiers()==count,"Negative casualties cannot create soldiers")
	state.inventory.clear()
	var herb: Resource = load("res://data/potions/healing_herb.tres")
	print("HARDENING PHASE: stack-cap input")
	for index in 1001: state.add_item(herb)
	check(Policy.valid({"inventory":state.inventory}),"Legitimate repeated loot remains saveable")
	state.strength_buff_timer = 0.01
	state._process(0.02)
	check(Policy.valid({"simulation":{"strength_buff":state.strength_buff_timer}}),"Expired strength buff does not make every later save invalid")
	state.equipment = {}
	state.recalculate_stats()
	check(state.equipment.size()==4,"Omitted legacy equipment slots normalize safely")
	check(state.has_method("restore_items"),"Legacy items normalize from shipped catalog before use")
	if state.has_method("restore_items"):
		state.restore_items([{"resource_path":"res://data/potions/health_potion.tres"}],{})
		state.player_hp = 50
		check(state.use_potion(0) and state.inventory.is_empty(),"A minimal legacy potion can be consumed without missing-field errors")
	var sword: Resource = load("res://data/weapons/iron_sword.tres")
	state.inventory.clear()
	print("HARDENING PHASE: equipment-cap input")
	for index in 1000: state.add_item(sword)
	state.equipment.weapon = state.inventory[0].duplicate()
	var gold: float = economy.stockpiles.gold
	root.get_node("WorkshopSystem").levels.forge = 1
	check(not state.add_item(sword) and state.inventory.size()==1000,"Full inventory cannot become an unloadable save")
	check(not state.unequip_item("weapon") and state.equipment.weapon!=null,"Failed unequip preserves equipped item")
	check(not root.get_node("WorkshopSystem").craft("iron_sword_hardened") and economy.stockpiles.gold==gold,"Full-inventory crafting does not consume materials")
	var notices: Array = []
	root.get_node("EventBus").notification_posted.connect(func(text,important):
		if important: notices.append(text))
	var blocked := "user://write-failure.json"
	DirAccess.remove_absolute(blocked+".tmp")
	DirAccess.make_dir_absolute(blocked+".tmp")
	check(not save._store(blocked,{"hp":75}),"Blocked save writes return failure")
	DirAccess.remove_absolute(blocked+".tmp")
	check(not save.save_game({"hp":"bad"}) and not notices.is_empty(),"Failed player save reports a visible error")
	check(not Guard.safe_text("(".repeat(40)+")".repeat(40)),"Constructor nesting is bounded before parsing")
	print("MUTATED SAVE FIELDS: ",mutation_count)
	print("RELEASE HARDENING RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
