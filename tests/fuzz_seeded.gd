extends "res://tests/AudioCleanTree.gd"
## Seeded input fuzz: reproducible random action streams against the real expedition,
## with state invariants checked after every step and a save/load round trip per seed.
## The second half of the seeds run inside a Second Oath so NG+ modifiers are fuzzed too.
const ACTIONS:Array[String]=["move_forward","move_backward","move_left","move_right","sprint",
	"jump","interact","quick_potion","inventory","attack","block","pause"]
# The iron oath forces permadeath re-entry, which is covered by tests/test_iron_death_reentry.gd.
const OATHS:Array[String]=["poverty","peace","wanderer"]
var world:Node3D
var state:Node
var saves:Node
var population:Node
var economy:Node
var campaign:Node
var failures:Array[String]=[]
var records:Array[Dictionary]=[]
var steps_total:int=0
var oath_seeds:int=0
var node_start:int=0
func _initialize()->void:call_deferred("run")
func note(label:String)->void:
	if label not in failures:
		failures.append(label)
		print("FAIL: ",label)
func digest(value:Variant)->String:
	return JSON.stringify(saves._normalize_numbers(value),"",true,true).sha256_text()
func divergences(before:Variant,after:Variant,trail:String,out:Array)->void:
	if out.size()>=4:
		return
	if before is Dictionary and after is Dictionary:
		@warning_ignore("unsafe_cast")
		var left:Dictionary=before
		@warning_ignore("unsafe_cast")
		var right:Dictionary=after
		for key:String in left:
			divergences(left[key],right.get(key),trail+"."+key,out)
		for key:String in right:
			if not left.has(key):
				out.append(trail+"."+key+" appears only after load")
		return
	if before is Array and after is Array:
		@warning_ignore("unsafe_cast")
		var left_list:Array=before
		@warning_ignore("unsafe_cast")
		var right_list:Array=after
		if left_list.size()!=right_list.size():
			out.append(trail+" length "+str(left_list.size())+" -> "+str(right_list.size()))
			return
		for index:int in left_list.size():
			divergences(left_list[index],right_list[index],trail+"["+str(index)+"]",out)
		return
	if digest(before)!=digest(after):
		out.append(trail+" "+str(before)+" -> "+str(after))
func profile()->Dictionary:
	return {"hp":state.player_hp,"stamina":state.player_stamina,"inventory":state.inventory.duplicate(true),
		"equipment":state.equipment.duplicate(true),"simulation":world.pause_menu.capture_simulation(),
		"world":world.get_world_state()}
func finite(value:float)->bool:
	return value==value and value!=INF and value!=-INF
func oath_selection(rng:RandomNumberGenerator)->Array:
	var chosen:Array=[]
	for id:String in OATHS:
		if rng.randf()<0.5:
			chosen.append(id)
	return chosen
func enter_second_oath(seed_value:int,rng:RandomNumberGenerator)->void:
	campaign.restore_state({})
	campaign.restore_state({"active":true,"announced_ending":"ending.peace","difficulty":seed_value%5})
	var chosen:Array=oath_selection(rng)
	if not bool(campaign.begin_second_oath(chosen)):
		note("Fuzz seed "+str(seed_value)+" cannot enter the Second Oath")
		return
	oath_seeds+=1
	if int(campaign.ng_level)!=1:
		note("Fuzz seed "+str(seed_value)+" starts a Second Oath at level "+str(campaign.ng_level))
	if campaign.oaths.size()!=chosen.size():
		note("Fuzz seed "+str(seed_value)+" keeps "+str(campaign.oaths.size())+" of "+str(chosen.size())+" selected oaths")
	for id:String in chosen:
		if id not in campaign.oaths:
			note("Fuzz seed "+str(seed_value)+" dropped the selected oath "+id)
	if chosen.is_empty():
		if not str(campaign.ng_banner).is_empty():
			note("Fuzz seed "+str(seed_value)+" invents a banner for a Second Oath without modifiers")
	elif str(campaign.ng_banner).is_empty():
		note("Fuzz seed "+str(seed_value)+" lost the oath banner")
	invariants(seed_value,-1)
func invariants(seed_value:int,step:int)->void:
	var where:String="seed "+str(seed_value)+" step "+str(step)
	if not finite(state.player_hp) or state.player_hp<0.0 or state.player_hp>state.max_hp:
		note("Health left its bounds during fuzz: "+where)
	if not finite(state.player_stamina) or state.player_stamina<0.0 or state.player_stamina>state.max_stamina:
		note("Stamina left its bounds during fuzz: "+where)
	var position:Vector3=world.player.global_position
	if not (position.x==position.x and position.y==position.y and position.z==position.z) or position.length()>1200.0:
		note("Player position became non-finite or escaped the map during fuzz: "+where)
	for entry:Variant in state.inventory:
		if not entry is Dictionary:
			note("Inventory gained a non-dictionary entry during fuzz: "+where)
			continue
		@warning_ignore("unsafe_cast")
		var item:Dictionary=entry
		var count:Variant=item.get("count",0)
		if not count is int or int(count)<0 or int(count)>9999:
			note("Inventory count escaped its range during fuzz: "+where)
		if item.has("durability") and (not finite(float(item.durability)) or float(item.durability)<0.0):
			note("Durability became negative or non-finite during fuzz: "+where)
	for key:String in economy.stockpiles:
		var amount:float=float(economy.stockpiles[key])
		if not finite(amount) or amount<-1.0:
			note("Stockpile "+key+" escaped its range during fuzz: "+where)
	if not finite(float(population.happiness)) or not finite(float(population.health)):
		note("Population mood or health became non-finite during fuzz: "+where)
	if int(campaign.ng_level)>0:
		var scale:float=campaign.enemy_scale()
		if not finite(scale) or scale<=1.0:
			note("Second Oath enemy scale left its range during fuzz: "+where)
		if not finite(campaign.loot_multiplier) or not finite(campaign.production_multiplier) \
			or campaign.loot_multiplier<1.0 or campaign.production_multiplier<=0.0:
			note("Second Oath modifiers left their range during fuzz: "+where)
func hold(action:String,frames:int)->void:
	Input.action_press(action)
	for tick:int in frames:
		await process_frame
	Input.action_release(action)
func menus(rng:RandomNumberGenerator)->void:
	match rng.randi_range(0,6):
		0:
			world.toggle_inventory()
		1:
			world.toggle_settlement()
		2:
			world.toggle_alchemy()
		3:
			world.toggle_codex()
		4:
			world.toggle_strategy(rng.randi_range(0,4))
		5:
			root.get_node("LocalizationManager").set_language("ru" if rng.randf()<0.5 else "en")
		6:
			root.get_node("WeatherSystem").set_weather(rng.randi_range(0,3))
	await process_frame
func run()->void:
	await process_frame
	state=root.get_node("GameState")
	saves=root.get_node("SaveSystem")
	population=root.get_node("PopulationSystem")
	economy=root.get_node("EconomySystem")
	campaign=root.get_node("CampaignSystem")
	world=load("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await process_frame
	node_start=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var seed_count:int=OS.get_environment("GAME_FUZZ_SEEDS").to_int()
	if seed_count<1:
		seed_count=50
	var steps_per_seed:int=OS.get_environment("GAME_FUZZ_STEPS").to_int()
	if steps_per_seed<1:
		steps_per_seed=28
	for index:int in seed_count:
		var seed_value:int=9001+index
		var rng:=RandomNumberGenerator.new()
		rng.seed=seed_value
		var step_failures:int=failures.size()
		if index>=seed_count/2:
			enter_second_oath(seed_value,rng)
		for step:int in steps_per_seed:
			steps_total+=1
			if rng.randf()<0.72:
				var action:String=ACTIONS[rng.randi_range(0,ACTIONS.size()-1)]
				hold(action,rng.randi_range(1,4))
			else:
				menus(rng)
			if rng.randf()<0.06:
				if not bool(world.pause_menu._on_save()):
					note("Fuzz manual save failed on seed "+str(seed_value))
			if rng.randf()<0.04:
				world.pause_menu._on_load()
			await process_frame
			invariants(seed_value,step)
		if state.player_hp<=0.0:
			world.restart_run()
			await process_frame
		if not paused:
			world.toggle_pause()
		await process_frame
		var written:Dictionary=profile()
		var before:String=digest(written)
		var level_before:int=int(campaign.ng_level)
		var oaths_before:Array[String]=campaign.oaths.duplicate()
		var banner_before:String=str(campaign.ng_banner)
		if not bool(world.pause_menu._on_save()):
			note("Fuzz seed "+str(seed_value)+" cannot save its completed state")
		# _on_load resumes the tree, so read the restored state before any frame advances it.
		world.pause_menu._on_load()
		var restored:Dictionary=profile()
		if digest(restored)!=before:
			var spots:Array=[]
			divergences(written,restored,"profile",spots)
			note("Fuzz seed "+str(seed_value)+" does not restore its saved state identically: "+", ".join(spots))
		if int(campaign.ng_level)!=level_before or campaign.oaths!=oaths_before \
			or str(campaign.ng_banner)!=banner_before:
			note("Fuzz seed "+str(seed_value)+" loses its Second Oath through the pause menu round trip")
		if paused:
			world.toggle_pause()
		records.append({"seed":seed_value,"steps":steps_per_seed,"new_failures":failures.size()-step_failures,
			"oaths":campaign.oaths.size(),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))})
	var growth:int=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-node_start
	if growth>240:
		note("Fuzz cycles leaked "+str(growth)+" nodes over the run")
	print("FUZZ RESULT: ","PASS" if failures.is_empty() else "FAIL"," seeds=",seed_count,
		" steps=",steps_total," second_oath_seeds=",oath_seeds)
	var path:String=OS.get_environment("GAME_FUZZ_RESULT_PATH")
	if not path.is_empty():
		var file:FileAccess=FileAccess.open(path,FileAccess.WRITE)
		if file!=null:
			file.store_string(JSON.stringify({"result":"PASS" if failures.is_empty() else "FAIL",
				"seeds":seed_count,"steps_per_seed":steps_per_seed,"total_steps":steps_total,
				"second_oath_seeds":oath_seeds,
				"failures":failures,"node_growth":growth,"records":records}))
			file.close()
	finish_test(0 if failures.is_empty() else 1)
