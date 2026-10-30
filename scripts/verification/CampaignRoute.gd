extends Node
const EnemyView=preload("res://scripts/ai/Enemy.gd")
const AlchemySystemView=preload("res://scripts/autoload/AlchemySystem.gd")
const ArmySystemView=preload("res://scripts/systems/ArmyRuntime.gd")
const WorkshopSystemView=preload("res://scripts/systems/WorkshopSystem.gd")
const PopulationSystemView=preload("res://scripts/systems/PopulationSystem.gd")
const WeatherSystemView=preload("res://scripts/systems/WeatherSystem.gd")
const EconomySystemView=preload("res://scripts/systems/EconomySystem.gd")
const SiegeSystemView=preload("res://scripts/systems/SiegeSystem.gd")
const FactionSystemView=preload("res://scripts/systems/FactionSystem.gd")
const DiplomacySystemView=preload("res://scripts/systems/DiplomacyRuntime.gd")
const TimeSystemView=preload("res://scripts/autoload/TimeSystem.gd")
const AudioManagerView=preload("res://scripts/audio/AudioDirector.gd")
const WorldView=preload("res://scripts/world/CampaignWorld.gd")
const PlayerView=preload("res://scripts/characters/Player.gd")
const StateModel=preload("res://scripts/autoload/GameState.gd")
const CampaignModel=preload("res://scripts/systems/CampaignSystem.gd")

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


var world: WorldView
var player: PlayerView
var state: StateModel
var campaign: CampaignModel
var failed: bool = false
var military: bool = false
var qa_trace:Array=[]
var qa_seed:int=7401
var started_ms:int=0

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--defeat"):
		if root.has_meta("qa_iron_defeat_active"):
			queue_free()
			return
		root.set_meta("qa_iron_defeat_active",true)
		var ending_script:GDScript=load("res://scripts/verification/NativeIronDeath.gd")
		if ending_script==null:quit(65);return
		var ending:Node=ending_script.new()
		ending.process_mode=Node.PROCESS_MODE_ALWAYS
		root.add_child.call_deferred(ending)
		queue_free()
		return
	call_deferred("run")

func fail(message: String) -> void:
	failed = true
	print("FAIL: ", message)

# A death releases the world, so every later diagnostic must survive a freed player.
func scene_alive() -> bool:
	return is_instance_valid(world) and is_instance_valid(player)

func position_text() -> String:
	return str(player.position) if is_instance_valid(player) else "an unloaded player"

func scene_gone(where: String) -> bool:
	if scene_alive():
		return false
	if not failed:
		fail("The world was released " + where)
	return true

func capture(suffix: String) -> void:
	if OS.get_environment("GAME_CAPTURE_GALLERY") != "1" or DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT").replace(".png","-"+suffix+".png"))!=OK:fail("QA screenshot write failed")

func frame() -> void:
	await physics_frame
	if state.player_hp <= 0 and not failed:
		fail("The campaign route died at " + position_text())

func nearest_enemy(radius:float)->EnemyView:
	var result:EnemyView
	for enemy:EnemyView in get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_dead: continue
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if distance < radius:
			radius = distance
			result = enemy
	return result

func combat() -> void:
	Input.action_release("move_forward")
	Input.action_release("sprint")
	var frames:int= 0
	while is_instance_valid(nearest_enemy(22)) and frames < 5000 and not failed:
		if scene_gone("during combat"): return
		frames += 1
		var enemy:EnemyView=nearest_enemy(22)
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
			var alchemy:AlchemySystemView=qa_alchemy_system
			if alchemy.can_brew(alchemy.known_recipes[0]) and not alchemy.brew_potion(alchemy.known_recipes[0]):fail("Affordable combat potion failed to brew")
		await frame()
	Input.action_release("attack")
	Input.action_release("block")
	Input.action_release("move_forward")
	if frames >= 5000: fail("A reachable combat encounter did not resolve")

func walk_to(destination: Vector3, stop: float = 1.7) -> void:
	if scene_gone("before walking to " + str(destination)): return
	var frames:int= 0
	while Vector2(player.position.x - destination.x, player.position.z - destination.z).length() > stop and frames < 12000 and not failed:
		frames += 1
		if nearest_enemy(16): await combat()
		if scene_gone("while walking to " + str(destination)): return
		player.look_at(Vector3(destination.x, player.position.y, destination.z))
		player.camera.rotation = Vector3.ZERO
		Input.action_press("move_forward")
		Input.action_press("sprint")
		await frame()
	Input.action_release("move_forward")
	Input.action_release("sprint")
	if frames >= 12000: fail("Route blocked walking to " + str(destination) + " from " + position_text())

func talk(id: String) -> void:
	var data:Dictionary=campaign.town(id)
	var town_x:float=data.x
	var town_z:float=data.z
	await walk_to(Vector3(town_x, 0, town_z + 6.8), 0.25)
	if failed: return
	if scene_gone("before talking to " + id): return
	player.camera.look_at(Vector3(town_x, world.terrain.ground_at(town_x, town_z) + 1.1, town_z + 5))
	await frame()
	if scene_gone("while walking up to " + id): return
	player.interact()
	await process_frame
	if scene_gone("after talking to " + id): return
	if not world.town_ui.visible: fail("The reeve could not be reached through E interaction: " + id)
	if id == campaign.definition.towns[0].id:
		await capture("journey")
		world.town_ui.tabs.current_tab=1
		await capture("trade")
		world.town_ui.tabs.current_tab=0

func equip_best() -> void:
	world.toggle_inventory()
	for slot:String in ["weapon", "torso", "head", "legs"]:
		var best:int= -1
		var current: Dictionary = state.equipment.get(slot) if state.equipment.get(slot) else {}
		var value: float = 0
		if not current.is_empty():
			var path:String=current.resource_path
			var resource:Resource=load(path)
			value=(resource as WeaponData).damage if slot=="weapon" else (resource as ArmorData).defense
		for index:int in state.inventory.size():
			var path:String=state.inventory[index].resource_path
			var resource:Resource=load(path)
			if slot == "weapon" and resource is WeaponData and (resource as WeaponData).damage > value:
				value = (resource as WeaponData).damage
				best = index
			elif resource is ArmorData and (resource as ArmorData).slot == slot and (resource as ArmorData).defense > value:
				value = (resource as ArmorData).defense
				best = index
		if best >= 0:
			world.inventory_ui._on_item_selected(best)
			world.inventory_ui.equip_button.pressed.emit()
	world.toggle_inventory()

func button(key: String) -> Button:
	for control:Button in world.strategy_ui.find_children("*", "Button", true, false):
		if control.get_meta("text_key", "") == key: return control
	return null

func run() -> void:
	started_ms=Time.get_ticks_msec()
	qa_seed=parse_seed(OS.get_environment("GAME_QA_SEED"))
	if qa_seed<0:quit(64);return
	seed(qa_seed)
	await process_frame
	if OS.get_cmdline_user_args().has("--verify-build"):
		Engine.max_fps=0
		Engine.time_scale = 8
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 256
	elif OS.get_environment("GAME_QA_FAST")=="1":Engine.max_fps=0
	if is_instance_valid(current_scene): current_scene.queue_free()
	state = root.get_node("GameState")
	campaign = root.get_node("CampaignSystem")
	military = OS.get_cmdline_user_args().has("--military")
	campaign.new_campaign(1, false)
	var scene:PackedScene=load("res://scenes/world/march.tscn") as PackedScene
	world=scene.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.player
	await process_frame
	await physics_frame
	equip_best()
	if not qa_workshop_system.build("farm"):fail("Initial farm construction failed")
	if not qa_army_system.recruit("militia_spear", 3):fail("Initial enlistment failed")
	await walk_to(Vector3(2, 0, 4), 0.7)
	player.camera.look_at(world.armor_pickup.global_position)
	await frame()
	player.interact()
	equip_best()
	await combat()
	for index:int in 8:
		if failed: break
		if failed: break
		var population:PopulationSystemView=qa_population_system
		population.update_worker_assignments({"farmers": 10, "woodcutters": 2, "miners": 1, "guards": 0, "blacksmiths": 0})
		var army:ArmySystemView=qa_army_system
		var needed: int = maxi(0, 5 - army.get_total_soldiers())
		if needed > 0 and not army.recruit("militia_spear", needed):fail("Available regional enlistment failed")
		var town:Dictionary=campaign.definition.towns[index]
		var town_x:float=town.x
		var town_z:float=town.z
		var town_id:String=town.id
		var fid: String = town.faction
		qa_trace.append({"region":index,"weather":qa_weather_system.current_weather,"hp":state.player_hp,"gold":qa_economy_system.stockpiles.gold})
		print("CAMPAIGN ROUTE: ", "military" if military else "diplomatic", " region ", index + 1, " hp=", state.player_hp, " gold=", qa_economy_system.stockpiles.gold, " army=", qa_army_system.get_total_soldiers())
		if index > 0:
			if not campaign.travel(town_id):
				fail("The next road was not opened or affordable: " + town_id)
				break
		else:
			await walk_to(Vector3(0, 0, -125))
		await talk(town_id)
		if failed: break
		world.town_ui.delivery_button.pressed.emit()
		if fid not in campaign.deliveries: fail("A region's supply delivery was not affordable")
		world.toggle_pause()
		await walk_to(Vector3(town_x, 0, town_z + 28))
		await walk_to(Vector3(town_x + 85, 0, town_z + 28))
		await combat()
		if not campaign.camp_cleared(fid):
			await walk_to(Vector3(town_x + 85, 0, town_z + 15))
			await combat()
		if not campaign.camp_cleared(fid): fail("A camp remained uncleared after actual attacks")
		equip_best()
		if campaign.brewed < 3:
			world.toggle_alchemy()
			while campaign.brewed < 3 and not world.alchemy_ui.brew_button.disabled:
				world.alchemy_ui.brew_button.pressed.emit()
			world.toggle_alchemy()
		await walk_to(Vector3(town_x + 85, 0, town_z + 30))
		await walk_to(Vector3(town_x - 70, 0, town_z + 30))
		await walk_to(Vector3(town_x - 70, 0, town_z - 18.3), 0.25)
		player.camera.look_at(Vector3(town_x - 70, world.terrain.ground_at(town_x - 70, town_z - 20) + 0.8, town_z - 20))
		await frame()
		player.interact()
		await walk_to(Vector3(town_x - 70, 0, town_z + 30))
		await walk_to(Vector3(town_x, 0, town_z + 30))
		# Both routes can lose soldiers to a boss. Replace real casualties
		# through the ordinary recruitment UI, including the five-soldier oath.
		var replacements: int = maxi(0, 5 - qa_army_system.get_total_soldiers())
		if replacements > 0:
			world.toggle_strategy(0)
			world.strategy_ui.unit_choice.selected = 0
			world.strategy_ui.recruit_count.value = replacements
			button("ui.recruit").pressed.emit()
			world.toggle_pause()
		if military:
			await talk(town_id)
			world.town_ui.tabs.current_tab=1
			for resource:String in ["wood", "food"]:
				var target_stock:int= 18 if resource == "wood" else 60
				while qa_economy_system.stockpiles[resource] < target_stock and not failed:
					var before: float = qa_economy_system.stockpiles[resource]
					for control:Button in world.town_ui.find_children("*", "Button", true, false):
						if control.get_meta("trade_resource", "") == resource and control.get_meta("text_key", "") == "ui.buy": control.pressed.emit()
					if qa_economy_system.stockpiles[resource] <= before: fail("Unable to buy siege provisions: " + resource)
			world.town_ui.tabs.current_tab=2
			await process_frame
			world.town_ui.blockade_button.pressed.emit()
			if not qa_siege_system.states.has(fid):
				fail("Blockade setup refused: resources=" + str(qa_economy_system.stockpiles) + " troops=" + str(qa_army_system.get_total_soldiers()) + " states=" + str(qa_siege_system.states) + " bound=" + str(campaign.bound(fid)))
				break
			if index==0: await capture("siege-active")
			world.town_ui.wait_button.pressed.emit()
			world.town_ui.assault_button.pressed.emit()
			if get_tree().paused:
				fail("Prepared assault could not be launched")
				break
			await combat()
			await walk_to(Vector3(town_x, 0, town_z + 17.8), 0.2)
			player.camera.look_at(Vector3(town_x, world.terrain.ground_at(town_x, town_z + 19) + 1.5, town_z + 19))
			var breach_frames:int= 0
			while qa_siege_system.states[fid].wall_hp > 0 and breach_frames < 2500 and not failed:
				if breach_frames % 2 == 0: Input.action_press("attack")
				else: Input.action_release("attack")
				await frame()
				breach_frames += 1
			Input.action_release("attack")
			if breach_frames >= 2500: fail("Ordinary weapon attacks did not breach the siege gate: position=" + str(player.position) + " weapon=" + str(state.equipment.weapon) + " wall=" + str(qa_siege_system.states[fid].wall_hp))
			if fid not in campaign.conquests: fail("Defeating the garrison did not secure its faction")
		else:
			world.toggle_strategy(1)
			world.strategy_ui.selected_faction = fid
			world.strategy_ui.gift_amount.value = 50
			while qa_faction_system.factions[fid].relationship < 60 and not failed:
				var old: float = qa_faction_system.factions[fid].relationship
				button("ui.gift").pressed.emit()
				if qa_faction_system.factions[fid].relationship == old: fail("Trust gift was not affordable")
			world.strategy_ui.treaty_choice.selected = qa_diplomacy_system.terms.keys().find("alliance")
			button("ui.sign_treaty").pressed.emit()
			world.toggle_pause()
			if not campaign.bound(fid): fail("Earned trust did not produce a paid alliance")
		await talk(town_id)
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
	var expected:String= "military" if military else "diplomatic"
	if scene_gone("before the finale checks"):
		quit(1)
		return
	if campaign.ending() != expected: fail("The full route did not reach its expected campaign ending")
	if campaign.completed.size() != 60:
		for quest:Variant in campaign.definition.quests:
			if quest.id not in campaign.completed: print("OPTIONAL QUEST REMAINING: ", quest.id)
		fail("The sixty available objectives were not all reachable on this route")
	print("CAMPAIGN ROUTE RESULT: ", "FAIL" if failed else "PASS", " route=", expected, " quests=", campaign.completed.size(), " days=", qa_time_system.current_day)
	if DisplayServer.get_name() != "headless" and not OS.get_environment("GAME_SCREENSHOT").is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(OS.get_environment("GAME_SCREENSHOT"))!=OK:fail("QA screenshot write failed")
	var snapshot:Dictionary={"campaign":campaign.capture_state(),"simulation":world.pause_menu.capture_simulation(),"world":world.get_world_state(),"inventory":state.inventory,"equipment":state.equipment,"hp":state.player_hp}
	write_qa_result({"seed":qa_seed,"result":"FAIL" if failed else "PASS","route":expected,"quests":campaign.completed.size(),"days":qa_time_system.current_day,"trace":qa_trace,"state_sha256":JSON.stringify(snapshot,"",true,true).sha256_text(),"elapsed_ms":Time.get_ticks_msec()-started_ms})
	get_tree().paused=false
	world.queue_free()
	await process_frame
	var audio_settled:bool=await settle_audio()
	quit(1 if failed or not audio_settled else 0)

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
		if file:
			if not file.store_string(JSON.stringify(record,"",true,true)+"\n"):quit(74)

func audio_refs_released(references:Array[WeakRef])->bool:
	for reference:WeakRef in references:
		if reference.get_ref()!=null:return false
	return true

func settle_audio()->bool:
	var audio:AudioManagerView=qa_audio_manager
	var references:Array[WeakRef]=[]
	for key:String in audio.streams:references.append(weakref(audio.streams[key]))
	# Submit any same-frame3D play request before stop(); Godot retains an unsubmitted setplayback.
	await get_tree().physics_frame
	await get_tree().process_frame
	if audio.crossfade:audio.crossfade.kill()
	for voice:Node in audio.get_children():
		if voice is AudioStreamPlayer:
			(voice as AudioStreamPlayer).stop()
			(voice as AudioStreamPlayer).stream=null
		elif voice is AudioStreamPlayer3D:
			(voice as AudioStreamPlayer3D).stop()
			(voice as AudioStreamPlayer3D).stream=null
	audio.streams.clear()
	audio.current_music=""
	audio.current_finale=""
	audio.music_index=-1
	# Mixer ownership ends on its real thread, independently of accelerated QA time.
	# A simulated delay can finish before AudioServer processes a stop request.
	var deadline:int=Time.get_ticks_msec()+5000
	while not audio_refs_released(references):
		if Time.get_ticks_msec()>=deadline:
			fail("Private QA audio shutdown did not release playback references")
			return false
		await get_tree().process_frame
		OS.delay_msec(1)
	return true

func region_checkpoint()->void:
	await process_frame

var qa_alchemy_system:AlchemySystemView:
	get:return root.get_node("AlchemySystem")

var qa_army_system:ArmySystemView:
	get:return root.get_node("ArmySystem")

var qa_workshop_system:WorkshopSystemView:
	get:return root.get_node("WorkshopSystem")

var qa_population_system:PopulationSystemView:
	get:return root.get_node("PopulationSystem")

var qa_weather_system:WeatherSystemView:
	get:return root.get_node("WeatherSystem")

var qa_economy_system:EconomySystemView:
	get:return root.get_node("EconomySystem")

var qa_siege_system:SiegeSystemView:
	get:return root.get_node("SiegeSystem")

var qa_faction_system:FactionSystemView:
	get:return root.get_node("FactionSystem")

var qa_diplomacy_system:DiplomacySystemView:
	get:return root.get_node("DiplomacySystem")

var qa_time_system:TimeSystemView:
	get:return root.get_node("TimeSystem")

var qa_audio_manager:AudioManagerView:
	get:return root.get_node("AudioManager")
