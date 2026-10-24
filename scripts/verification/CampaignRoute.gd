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

func _ready() -> void:
	call_deferred("run")

func fail(message: String) -> void:
	failed = true
	print("FAIL: ", message)

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
	await process_frame
	if OS.get_cmdline_user_args().has("--verify-build"):
		Engine.time_scale = 8
		Engine.physics_ticks_per_second = 480
		Engine.max_physics_steps_per_frame = 64
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
		if military:
			await talk(town.id)
			world.town_ui.assault_button.pressed.emit()
			await combat()
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
		if index < 7 and campaign.definition.towns[index + 1].id not in campaign.roads: fail("Regional work did not open the next campaign road")
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
	quit(1 if failed else 0)
