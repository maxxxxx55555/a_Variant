extends Node

var root: Window:
	get: return get_tree().root
var current_scene: Node:
	get: return get_tree().current_scene
	set(value): get_tree().current_scene = value
var physics_frame: Signal:
	get: return get_tree().physics_frame
var process_frame: Signal:
	get: return get_tree().process_frame

func get_nodes_in_group(group: StringName) -> Array[Node]:
	return get_tree().get_nodes_in_group(group)

func quit(code: int) -> void:
	get_tree().quit(code)


var world: Node3D
var player: Node3D
var state: Node
var campaign: Node
var failed: bool = false
var military: bool = false
var qa_trace:Array=[]
var qa_seed:int=7401
var started_ms:int=0

func _ready() -> void:
	call_deferred("run")

func fail(message: String) -> void:
	failed = true
	print("FAIL: ", message)

func capture(suffix: String) -> void:
	if OS.get_environment("GAME_CAPTURE_GALLERY") != "1" or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png", "-" + suffix + ".png"))

func frame() -> void:
	await physics_frame
	if state.player_hp <= 0 and not failed:
		fail("The campaign route died at " + str(player.position))

func nearest_enemy(radius: float) -> Node3D:
	var result: Node3D
	for enemy in get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_dead: continue
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if distance < radius:
			radius = distance
			result = enemy
	return result

func combat() -> void:
	Input.action_release("move_forward")
	Input.action_release("sprint")
	var frames := 0
	while is_instance_valid(nearest_enemy(22)) and frames < 5000 and not failed:
		frames += 1
		var enemy: Node3D = nearest_enemy(22)
		player.look_at(Vector3(enemy.global_position.x, player.global_position.y, enemy.global_position.z))
		player.camera.look_at(enemy.global_position + Vector3(0, 0.95, 0))
		Input.action_press("block")
		if enemy.global_position.distance_to(player.global_position) > 1.7:
			Input.action_press("move_forward")
		else:
			Input.action_release("move_forward")
		if frames % 2 == 0: Input.action_press("attack")
		else: Input.action_release("attack")
		if state.player_hp < 65:
			player.use_quick_potion()
			var alchemy: Node = root.get_node("AlchemySystem")
			if alchemy.can_brew(alchemy.known_recipes[0]): alchemy.brew_potion(alchemy.known_recipes[0])
		await frame()
	Input.action_release("attack")
	Input.action_release("block")
	Input.action_release("move_forward")
	if frames >= 5000: fail("A reachable combat encounter did not resolve")

func walk_to(destination: Vector3, stop: float = 1.7) -> void:
	var frames := 0
	while Vector2(player.position.x - destination.x, player.position.z - destination.z).length() > stop and frames < 12000 and not failed:
		frames += 1
		if nearest_enemy(16): await combat()
		player.look_at(Vector3(destination.x, player.position.y, destination.z))
		player.camera.rotation = Vector3.ZERO
		Input.action_press("move_forward")
		Input.action_press("sprint")
		await frame()
	Input.action_release("move_forward")
	Input.action_release("sprint")
	if frames >= 12000: fail("Route blocked walking to " + str(destination) + " from " + str(player.position))

func talk(id: String) -> void:
	var data: Dictionary = campaign.town(id)
	await walk_to(Vector3(data.x, 0, data.z + 6.8), 0.25)
	if failed: return
	player.camera.look_at(Vector3(data.x, world.terrain.ground_at(data.x, data.z) + 1.1, data.z + 5))
	await frame()
	player.interact()
	await process_frame
	if not world.town_ui.visible: fail("The reeve could not be reached through E interaction: " + id)
	if id == campaign.definition.towns[0].id:
		await capture("journey")
		world.town_ui.tabs.current_tab=1
		await capture("trade")
		world.town_ui.tabs.current_tab=0

func equip_best() -> void:
	world.toggle_inventory()
	for slot in ["weapon", "torso", "head", "legs"]:
		var best := -1
		var current: Dictionary = state.equipment.get(slot) if state.equipment.get(slot) else {}
		var value: float = 0
		if not current.is_empty():
			var resource: Resource = load(current.resource_path)
			value = resource.damage if slot == "weapon" else resource.defense
		for index in state.inventory.size():
			var resource: Resource = load(state.inventory[index].resource_path)
			if slot == "weapon" and resource is WeaponData and resource.damage > value:
				value = resource.damage
				best = index
			elif resource is ArmorData and resource.slot == slot and resource.defense > value:
				value = resource.defense
				best = index
		if best >= 0:
			world.inventory_ui._on_item_selected(best)
			world.inventory_ui.equip_button.pressed.emit()
	world.toggle_inventory()

func button(key: String) -> Button:
	for control in world.strategy_ui.find_children("*", "Button", true, false):
		if control.get_meta("text_key", "") == key: return control
	return null

func run() -> void:
	started_ms=Time.get_ticks_msec()
	qa_seed=parse_seed(OS.get_environment("GAME_QA_SEED"))
	if qa_seed<0:quit(64);return
	seed(qa_seed)
	await process_frame
	if OS.get_environment("GAME_QA_FAST")=="1":Engine.max_fps=0
	if OS.get_cmdline_user_args().has("--verify-build"):
		Engine.time_scale = 8
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 256
	if is_instance_valid(current_scene): current_scene.queue_free()
	state = root.get_node("GameState")
	campaign = root.get_node("CampaignSystem")
	military = OS.get_cmdline_user_args().has("--military")
	campaign.new_campaign(1, false)
	world = load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	player = world.player
	await process_frame
	await physics_frame
	equip_best()
	root.get_node("WorkshopSystem").build("farm")
	root.get_node("ArmySystem").recruit("militia_spear", 3)
	await walk_to(Vector3(2, 0, 4), 0.7)
	player.camera.look_at(world.armor_pickup.global_position)
	await frame()
	player.interact()
	equip_best()
	await combat()
	for index in 8:
		if failed: break
		var population: Node = root.get_node("PopulationSystem")
		population.update_worker_assignments({"farmers": 10, "woodcutters": 2, "miners": 1, "guards": 0, "blacksmiths": 0})
		var army: Node = root.get_node("ArmySystem")
		var needed: int = maxi(0, 5 - army.get_total_soldiers())
		if needed > 0: army.recruit("militia_spear", needed)
		var town: Dictionary = campaign.definition.towns[index]
		var fid: String = town.faction
		qa_trace.append({"region":index,"weather":root.get_node("WeatherSystem").current_weather,"hp":state.player_hp,"gold":root.get_node("EconomySystem").stockpiles.gold})
		print("CAMPAIGN ROUTE: ", "military" if military else "diplomatic", " region ", index + 1, " hp=", state.player_hp, " gold=", root.get_node("EconomySystem").stockpiles.gold, " army=", root.get_node("ArmySystem").get_total_soldiers())
		if index > 0:
			if not campaign.travel(town.id):
				fail("The next road was not opened or affordable: " + town.id)
				break
		else:
			await walk_to(Vector3(0, 0, -125))
		await talk(town.id)
		if failed: break
		world.town_ui.delivery_button.pressed.emit()
		if fid not in campaign.deliveries: fail("A region's supply delivery was not affordable")
		world.toggle_pause()
		await walk_to(Vector3(town.x, 0, town.z + 28))
		await walk_to(Vector3(town.x + 85, 0, town.z + 28))
		await combat()
		if not campaign.camp_cleared(fid):
			await walk_to(Vector3(town.x + 85, 0, town.z + 15))
			await combat()
		if not campaign.camp_cleared(fid): fail("A camp remained uncleared after actual attacks")
		equip_best()
		if campaign.brewed < 3:
			world.toggle_alchemy()
			while campaign.brewed < 3 and not world.alchemy_ui.brew_button.disabled:
				world.alchemy_ui.brew_button.pressed.emit()
			world.toggle_alchemy()
		await walk_to(Vector3(town.x + 85, 0, town.z + 30))
		await walk_to(Vector3(town.x - 70, 0, town.z + 30))
		await walk_to(Vector3(town.x - 70, 0, town.z - 18.3), 0.25)
		player.camera.look_at(Vector3(town.x - 70, world.terrain.ground_at(town.x - 70, town.z - 20) + 0.8, town.z - 20))
		await frame()
		player.interact()
		await walk_to(Vector3(town.x - 70, 0, town.z + 30))
		await walk_to(Vector3(town.x, 0, town.z + 30))
		# Both routes can lose soldiers to a boss. Replace real casualties
		# through the ordinary recruitment UI, including the five-soldier oath.
		var replacements: int = maxi(0, 5 - root.get_node("ArmySystem").get_total_soldiers())
		if replacements > 0:
			world.toggle_strategy(0)
			world.strategy_ui.unit_choice.selected = 0
			world.strategy_ui.recruit_count.value = replacements
			button("ui.recruit").pressed.emit()
			world.toggle_pause()
		if military:
			await talk(town.id)
			world.town_ui.tabs.current_tab=1
			for resource in ["wood", "food"]:
				var target_stock := 18 if resource == "wood" else 60
				while root.get_node("EconomySystem").stockpiles[resource] < target_stock and not failed:
					var before: float = root.get_node("EconomySystem").stockpiles[resource]
					for control in world.town_ui.find_children("*", "Button", true, false):
						if control.get_meta("trade_resource", "") == resource and control.get_meta("text_key", "") == "ui.buy": control.pressed.emit()
					if root.get_node("EconomySystem").stockpiles[resource] <= before: fail("Unable to buy siege provisions: " + resource)
			world.town_ui.tabs.current_tab=2
			await process_frame
			world.town_ui.blockade_button.pressed.emit()
			if not root.get_node("SiegeSystem").states.has(fid):
				fail("Blockade setup refused: resources=" + str(root.get_node("EconomySystem").stockpiles) + " troops=" + str(root.get_node("ArmySystem").get_total_soldiers()) + " states=" + str(root.get_node("SiegeSystem").states) + " bound=" + str(campaign.bound(fid)))
				break
			if index==0: await capture("siege-active")
			world.town_ui.wait_button.pressed.emit()
			world.town_ui.assault_button.pressed.emit()
			if get_tree().paused:
				fail("Prepared assault could not be launched")
				break
			await combat()
			await walk_to(Vector3(town.x, 0, town.z + 17.8), 0.2)
			player.camera.look_at(Vector3(town.x, world.terrain.ground_at(town.x, town.z + 19) + 1.5, town.z + 19))
			var breach_frames := 0
			while root.get_node("SiegeSystem").states[fid].wall_hp > 0 and breach_frames < 2500 and not failed:
				if breach_frames % 2 == 0: Input.action_press("attack")
				else: Input.action_release("attack")
				await frame()
				breach_frames += 1
			Input.action_release("attack")
			if breach_frames >= 2500: fail("Ordinary weapon attacks did not breach the siege gate: position=" + str(player.position) + " weapon=" + str(state.equipment.weapon) + " wall=" + str(root.get_node("SiegeSystem").states[fid].wall_hp))
			if fid not in campaign.conquests: fail("Defeating the garrison did not secure its faction")
		else:
			world.toggle_strategy(1)
			world.strategy_ui.selected_faction = fid
			world.strategy_ui.gift_amount.value = 50
			while root.get_node("FactionSystem").factions[fid].relationship < 60 and not failed:
				var old: float = root.get_node("FactionSystem").factions[fid].relationship
				button("ui.gift").pressed.emit()
				if root.get_node("FactionSystem").factions[fid].relationship == old: fail("Trust gift was not affordable")
			world.strategy_ui.treaty_choice.selected = root.get_node("DiplomacySystem").terms.keys().find("alliance")
			button("ui.sign_treaty").pressed.emit()
			world.toggle_pause()
			if not campaign.bound(fid): fail("Earned trust did not produce a paid alliance")
		await talk(town.id)
		if failed: break
		world.town_ui.report_button.pressed.emit()
		world.toggle_pause()
		if index == 0: await capture("village")
		if index == 3 and OS.get_environment("GAME_CAPTURE_GALLERY") == "1":
			world.toggle_strategy(3)
			await capture("map")
			world.toggle_pause()
		if index < 7 and campaign.definition.towns[index + 1].id not in campaign.roads: fail("Regional work did not open the next campaign road")
		await region_checkpoint()
	var expected := "military" if military else "diplomatic"
	if campaign.ending() != expected: fail("The full route did not reach its expected campaign ending")
	if campaign.completed.size() != 60:
		for quest in campaign.definition.quests:
			if quest.id not in campaign.completed: print("OPTIONAL QUEST REMAINING: ", quest.id)
		fail("The sixty available objectives were not all reachable on this route")
	print("CAMPAIGN ROUTE RESULT: ", "FAIL" if failed else "PASS", " route=", expected, " quests=", campaign.completed.size(), " days=", root.get_node("TimeSystem").current_day)
	if DisplayServer.get_name() != "headless" and not OS.get_environment("GAME_SCREENSHOT").is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT"))
	var snapshot:Dictionary={"campaign":campaign.capture_state(),"simulation":world.pause_menu.capture_simulation(),"world":world.get_world_state(),"inventory":state.inventory,"equipment":state.equipment,"hp":state.player_hp}
	write_qa_result({"seed":qa_seed,"result":"FAIL" if failed else "PASS","route":expected,"quests":campaign.completed.size(),"days":root.get_node("TimeSystem").current_day,"trace":qa_trace,"state_sha256":JSON.stringify(snapshot,"",true,true).sha256_text(),"elapsed_ms":Time.get_ticks_msec()-started_ms})
	get_tree().paused=false
	world.queue_free()
	await process_frame
	await settle_audio()
	quit(1 if failed else 0)

# Private QA only: explicit seeds vary simulation; art/audio keep their own RNG.
static func parse_seed(raw:String)->int:
	if raw.is_empty():return 7401
	if not raw.is_valid_int():return -1
	var value:int=raw.to_int()
	return value if value>0 and value<=2147483647 else -1

func write_qa_result(record:Dictionary)->void:
	print("QA CYCLE: ",JSON.stringify(record,"",true,true))
	var path:String=OS.get_environment("GAME_QA_RESULT_PATH")
	if not path.is_empty():
		var file:FileAccess=FileAccess.open(path,FileAccess.WRITE)
		if file:file.store_string(JSON.stringify(record,"",true,true)+"\n")

func settle_audio()->void:
	var audio:Node=get_tree().root.get_node("AudioManager")
	if audio.crossfade:audio.crossfade.kill()
	for voice in audio.get_children():
		if voice is AudioStreamPlayer or voice is AudioStreamPlayer3D:
			voice.stop()
			voice.stream=null
	audio.streams.clear()
	audio.current_music=""
	audio.current_finale=""
	audio.music_index=-1
	await get_tree().create_timer(0.3,true,false,true).timeout
	for index in 10:await get_tree().process_frame

func region_checkpoint()->void:
	await process_frame
