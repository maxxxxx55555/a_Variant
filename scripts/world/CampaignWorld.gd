extends "res://scripts/world/TestLocation.gd"
const BossView=preload("res://scripts/ai/BossEnemy.gd")
const SoldierView=preload("res://scripts/ai/SoldierActor.gd")
const TownView=preload("res://scripts/ui/TownMenu.gd")
const EndingView=preload("res://scripts/ui/CampaignFinale.gd")
const TypeRefCinematicWeather=preload("res://scripts/world/CinematicWeather.gd")
const TypeRefCivilianActor=preload("res://scripts/ai/CivilianActor.gd")
const TypeRefSiegeGate=preload("res://scripts/world/SiegeGate.gd")
const TypeRefCompanionActor=preload("res://scripts/ai/CompanionActor.gd")

const TERRAIN_SCRIPT = preload("res://scripts/world/MarchTerrain.gd")
const MARKER_SCRIPT = preload("res://scripts/world/MarchMarker.gd")
var terrain: TERRAIN_SCRIPT
var town_ui: TownView
var scan_time: float = 0
var autosave_time: float = 0
var ending_panel: EndingView
var companion_actors: Dictionary[String,TypeRefCompanionActor] = {}
var current_ambience: String = "forest"
var siege_gates: Dictionary[String,TypeRefSiegeGate] = {}

func _ready() -> void:
	if not CampaignSystem.active:
		CampaignSystem.new_campaign(1, false)
	super._ready()
	$NavigationRegion3D.queue_free()
	($MicroPOI_BrokenCart as Node3D).hide()
	terrain = TERRAIN_SCRIPT.new()
	add_child(terrain)
	terrain.generate()
	preload("res://scripts/world/MarchRoads.gd").build(self, terrain)
	var environment: Environment = ($WorldEnvironment as WorldEnvironment).environment
	environment.volumetric_fog_enabled = false
	environment.fog_enabled = true
	environment.fog_sky_affect = 0.18
	environment.fog_light_color = Color("829095")
	environment.fog_density = 0.0018
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 0.84
	var sunlight:DirectionalLight3D=$DirectionalLight3D as DirectionalLight3D
	sunlight.light_color = Color("ffd0a1")
	sunlight.light_energy = 0.72
	sunlight.rotation_degrees = Vector3(-19,-32,0)
	sunlight.directional_shadow_max_distance = 100
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	var sky_material:PanoramaSkyMaterial= PanoramaSkyMaterial.new()
	sky_material.panorama = load("res://assets/art/realistic/sky/dusk.hdr") as Texture2D
	sky_material.energy_multiplier = 0.38
	# Keep the scene-owned Sky alive: replacing a newly dirtied Sky can orphan
	# its queued GLES radiance allocation before the first renderer update.
	var sky: Sky = environment.sky
	if sky == null:
		sky = Sky.new()
		environment.sky = sky
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	preload("res://scripts/world/Meadow.gd").build(self, terrain, Vector2(0, 12))
	# The generated building is attached to its parent; ownership stays with the world.
	@warning_ignore("return_value_discarded")
	MarchArt.house(self, Vector3(-9, terrain.ground_at(-9, 12), 12), Color("a49878"))
	# The generated building is attached to its parent; ownership stays with the world.
	@warning_ignore("return_value_discarded")
	MarchArt.house(self, Vector3(9, terrain.ground_at(9, 12), 12), Color("8b8d76"))
	# The label is parent-owned and updates through the locale signal.
	@warning_ignore("return_value_discarded")
	MarchArt.localized_label(self, "ui.home", Vector3(0, 5, 16))
	for data:Dictionary in CampaignSystem.definition.towns:
		build_town(data)
	for point:Dictionary in CampaignSystem.definition.points:
		build_point(point)
	town_ui = preload("res://scripts/ui/TownMenu.gd").new()
	$CanvasLayer.add_child(town_ui)
	town_ui.theme = strategy_ui.theme
	town_ui.hide()
	var weather:TypeRefCinematicWeather= preload("res://scripts/world/CinematicWeather.gd").new()
	weather.environment = environment
	weather.sunlight = sunlight
	weather.player = player
	weather.terrain = terrain
	add_child(weather)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.campaign_finished.connect(show_ending)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	SiegeSystem.changed.connect(sync_siege_gates)
	sync_siege_gates()
	if not CampaignSystem.pending_load.is_empty():
		var pending: Dictionary = CampaignSystem.pending_load
		CampaignSystem.pending_load = {}
		apply_snapshot(pending)
	if not CampaignSystem.announced_ending.is_empty():
		show_ending(CampaignSystem.announced_ending)
	# SaveSystem reports persistence failure through the shared localized notification channel.
	@warning_ignore("return_value_discarded")
	pause_menu._on_save(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(pause_menu):
		pause_menu._on_exit()

func build_town(data: Dictionary) -> void:
	var town_x:float=data.x
	var town_z:float=data.z
	var origin:Vector3= Vector3(town_x, terrain.ground_at(town_x, town_z), town_z)
	preload("res://scripts/world/Meadow.gd").build(self, terrain, Vector2(town_x, town_z))
	var factions:Array=CampaignSystem.definition.factions
	var faction:Dictionary=factions.filter(func(f:Dictionary)->bool:return f.id==data.faction)[0]
	var faction_color:String=faction.color
	for index:int in 4:
		# Two houses per row; integer division deliberately selects the row.
		@warning_ignore("integer_division")
		var offset:Vector3= Vector3(-12 if index % 2 == 0 else 12, 0, int(index / 2) * 14 - 10)
		var pos:Vector3= origin + offset
		pos.y = terrain.ground_at(pos.x, pos.z)
		# The generated building is attached to its parent; ownership stays with the world.
		@warning_ignore("return_value_discarded")
		MarchArt.house(self, pos, Color("9d9276").lerp(Color(faction_color), 0.25), "tavern" if index == 2 else ("blacksmith" if index == 3 else ""))
	var marker:MARKER_SCRIPT= MARKER_SCRIPT.new()
	marker.data = data
	marker.is_town = true
	add_child(marker)
	marker.position = origin + Vector3(0, 0, 5)
	RealWorldArt.banner(self,origin+Vector3(4,0,4),Color(faction_color))
	preload("res://scripts/world/MarchScenery.gd").dress_town(self, terrain, data)
	MarchArt.market(self, origin + Vector3(-6, 0, -6), Color(faction_color).darkened(0.15))
	MarchArt.well(self, origin + Vector3(6, 0, -4))
	# The scene owner retains this placed asset.
	@warning_ignore("return_value_discarded")
	MarchAssets.place(self,"realistic/models/rock_moss_set_01/rock_moss_set_01.gltf",origin+Vector3(24,0,14),Vector3(5,2.1,5))
	for index:int in 3:
		var civilian:TypeRefCivilianActor= preload("res://scripts/ai/CivilianActor.gd").new()
		civilian.town_id = data.id
		civilian.occupation = index
		var side:int= -1 if index < 2 else 1
		civilian.home = origin + Vector3(side * 8, 0, -13 + index)
		civilian.workplace = origin + Vector3(side * 8, 0, -6 + index * 2)
		civilian.plaza = origin + Vector3(side * 6, 0, 1 + index)
		civilian.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(civilian)

func build_point(data: Dictionary) -> void:
	var town_x:float=data.x
	var town_z:float=data.z
	var origin:Vector3= Vector3(town_x, terrain.ground_at(town_x, town_z), town_z)
	if data.kind == "camp":
		for index:int in 3:
			# The scene owner retains this placed asset.
			@warning_ignore("return_value_discarded")
			MarchAssets.place(self, "medieval/decoration/props/tent.gltf", origin + Vector3(index * 5 - 5, 0, 4), Vector3(3.5,2.8,4.5))
		spawn_camp(data)
	else:
		var marker:MARKER_SCRIPT= MARKER_SCRIPT.new()
		marker.data = data
		add_child(marker)
		marker.position = origin
		if data.kind == "shrine" or data.kind == "ruins":
			for side:int in [-1, 1]:
				# The generated mesh is attached to its parent; no separate handle is needed here.
				@warning_ignore("return_value_discarded")
				MarchArt.box(self, origin + Vector3(side * 2, 2, 0), Vector3(0.8, 4, 0.9), Color("898b7c"), true)
			# The generated mesh is attached to its parent; no separate handle is needed here.
			@warning_ignore("return_value_discarded")
			MarchArt.box(self, origin + Vector3(0, 4, 0), Vector3(5, 0.7, 1), Color("969585"), true)
		elif data.kind == "mine":
			for index:int in 4:
				var mesh:SphereMesh= SphereMesh.new()
				mesh.radius = 1.5 + index * 0.4
				mesh.height = mesh.radius * 1.4
				mesh.radial_segments = 6
				mesh.rings = 3
				# The figure owner retains this attached mesh part.
				@warning_ignore("return_value_discarded")
				MarchArt.shape(self, mesh, origin + Vector3(index * 2 - 3, 0.8, 3), Color("777d7b"))
		else:
			# The generated mesh is attached to its parent; no separate handle is needed here.
			@warning_ignore("return_value_discarded")
			MarchArt.box(self, origin + Vector3(1, 0.45, 0), Vector3(2, 0.9, 1.1), Color("756044"))

func spawn_camp(data: Dictionary) -> void:
	var faction:String=data.faction
	var town_x:float=data.x
	var town_z:float=data.z
	var danger:int=data.danger
	var boss:bool=data.boss
	for index:int in 3:
		var id: String = CampaignSystem.camp_ids(faction)[index]
		if id in CampaignSystem.fallen: continue
		var pos:Vector3= Vector3(town_x + index * 2 - 2, 0, town_z - 2)
		# The world owns this encounter actor and discovers it through its group.
		@warning_ignore("return_value_discarded")
		spawn_enemy(id, faction, pos, danger, boss and index == 2)

func spawn_enemy(id: String, faction: String, position_hint: Vector3, danger: int, boss: bool = false) -> EnemyView:
	var actor:EnemyView= ENEMY_SCENE.instantiate() as EnemyView
	if boss:
		actor.set_script(preload("res://scripts/ai/BossEnemy.gd"))
		(actor as BossView).boss_name_key = {"borderland_watch": "boss.bandit_leader.name", "marsh_keepers": "boss.army_commander.name", "pass_clans": "boss.pass_master.name"}.get(faction, "boss.bandit_leader.name")
	var level: Dictionary = CampaignSystem.definition.difficulties[CampaignSystem.difficulty]
	actor.max_hp = (240.0 + danger * 30 if boss else 55.0 + danger * 15) * level.enemy_health
	actor.damage = (16.0 + danger * 2 if boss else 7.0 + danger * 1.5) * level.enemy_damage
	actor.detection_range = 18
	actor.set_meta("campaign_id", id)
	actor.set_meta("faction_id", faction)
	actor.set_meta("boss", boss)
	actor.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actor)
	actor.position = Vector3(position_hint.x, terrain.ground_at(position_hint.x, position_hint.z) + 0.15, position_hint.z)
	return actor

func spawn_garrison(faction: String) -> void:
	for data:Dictionary in CampaignSystem.definition.towns:
		if data.faction != faction: continue
		var town_x:float=data.x
		var town_z:float=data.z
		var danger:int=data.danger
		for index:int in 3:
			var id: String = CampaignSystem.camp_ids(faction, true)[index]
			var exists:bool= false
			for actor:EnemyView in get_tree().get_nodes_in_group("enemies"):
				if not actor.is_queued_for_deletion() and actor.get_meta("campaign_id", "") == id: exists = true
			if id not in CampaignSystem.fallen and not exists:
				# The world owns this encounter actor and discovers it through its group.
				@warning_ignore("return_value_discarded")
				spawn_enemy(id, faction, Vector3(town_x + index * 2 - 2, 0, town_z + 12), danger + 1)
		break

func in_combat() -> bool:
	for actor:EnemyView in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(actor) and not actor.is_dead and actor.global_position.distance_to(player.global_position) < 23:
			return true
	return false

func sync_siege_gates() -> void:
	if not is_instance_valid(terrain): return
	for id:String in siege_gates.keys():
		if not is_instance_valid(siege_gates[id]) or siege_gates[id].is_queued_for_deletion():
			# Idempotent cleanup of a scene-owned handle; no transaction depends on prior presence.
			@warning_ignore("return_value_discarded")
			siege_gates.erase(id)
	for id:String in SiegeSystem.states:
		var state: Dictionary = SiegeSystem.states[id]
		if state.phase != "assault" or state.wall_hp <= 0 or siege_gates.has(id): continue
		for data:Dictionary in CampaignSystem.definition.towns:
			if data.faction != id: continue
			var town_x:float=data.x
			var town_z:float=data.z
			var gate:TypeRefSiegeGate= preload("res://scripts/world/SiegeGate.gd").new()
			gate.faction_id = id
			add_child(gate)
			gate.position = Vector3(town_x, terrain.ground_at(town_x, town_z + 19), town_z + 19)
			siege_gates[id] = gate
			break

func _process(delta: float) -> void:
	super._process(delta)
	if get_tree().paused or not is_instance_valid(terrain): return
	scan_time -= delta
	autosave_time += delta
	if autosave_time >= 180 and not in_combat():
		autosave_time = 0
		# SaveSystem reports persistence failure through the shared localized notification channel.
		@warning_ignore("return_value_discarded")
		pause_menu._on_save(true)
	if scan_time > 0: return
	scan_time = 0.5
	if is_instance_valid(AudioManager.ambience):
		AudioManager.ambience.global_position = player.global_position + Vector3(0, 4, 0)
	for data:Dictionary in CampaignSystem.definition.towns:
		var town_x:float=data.x
		var town_z:float=data.z
		if Vector2(player.position.x - town_x, player.position.z - town_z).length() < 30 and data.id not in CampaignSystem.roads:
			CampaignSystem.roads.append(str(data.id))
			CampaignSystem.changed.emit()
	for id:String in CampaignSystem.companions:
		if not companion_actors.has(id) or not is_instance_valid(companion_actors[id]):
			var actor:TypeRefCompanionActor= preload("res://scripts/ai/CompanionActor.gd").new()
			actor.companion_id = id
			actor.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(actor)
			actor.global_position = player.global_position + Vector3(4, 0.5, 4)
			companion_actors[id] = actor
	for id:String in companion_actors.keys():
		if id not in CampaignSystem.companions:
			if is_instance_valid(companion_actors[id]): companion_actors[id].queue_free()
			# Removing an obsolete scene handle is intentionally idempotent.
			@warning_ignore("return_value_discarded")
			companion_actors.erase(id)
	if absf(player.position.x) > 1980 or absf(player.position.z) > 1980:
		player.position.x = clampf(player.position.x, -1970, 1970)
		player.position.z = clampf(player.position.z, -1970, 1970)
		player.position.y = terrain.ground_at(player.position.x, player.position.z) + 1

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(ending_panel):
		return
	if event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_M:
		toggle_strategy(3)
	else:
		super._unhandled_input(event)

func travel_to(id: String) -> void:
	var data:Dictionary= CampaignSystem.town(id)
	var pos:Vector3=Vector3(0,1,8)
	if id!="home":
		var town_x:float=data.x
		var town_z:float=data.z
		pos=Vector3(town_x,1,town_z+9)
	pos.y = terrain.ground_at(pos.x, pos.z) + 1
	player.position = pos
	player.velocity = Vector3.ZERO
	player.rotation.y = 0
	player.camera.rotation = Vector3.ZERO
	for actor:SoldierView in ArmySystem.visual_actors:
		if is_instance_valid(actor): actor.global_position = pos + Vector3(3, 0, 4)
	strategy_ui.hide()
	town_ui.hide()
	_sync_menu_state()

func open_town(id: String) -> void:
	inventory_ui.hide()
	settlement_ui.hide()
	alchemy_ui.hide()
	strategy_ui.hide()
	town_ui.open(id)
	_sync_menu_state()

func _sync_menu_state() -> void:
	super._sync_menu_state()
	if (is_instance_valid(town_ui) and town_ui.visible) or is_instance_valid(ending_panel):
		get_tree().paused = true
		hud.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.set_scene_paused(get_tree().paused)

func toggle_pause() -> void:
	if is_instance_valid(ending_panel):
		return
	if is_instance_valid(town_ui) and town_ui.visible:
		town_ui.hide()
		_sync_menu_state()
		return
	super.toggle_pause()

func toggle_strategy(index: int) -> void:
	if is_instance_valid(town_ui): town_ui.hide()
	super.toggle_strategy(index)

func get_world_state() -> Dictionary:
	var data:Dictionary= super.get_world_state()
	var actors:Array= []
	for actor:EnemyView in get_tree().get_nodes_in_group("enemies"):
		if actor.has_meta("campaign_id") and not actor.is_dead and not actor.is_queued_for_deletion():
			actors.append({"id": actor.get_meta("campaign_id"), "hp": actor.current_hp, "max_hp": actor.max_hp, "damage": actor.damage, "speed": actor.move_speed, "cooldown": actor.attack_cooldown, "enraged": (actor as BossView).is_enraged if actor.get_meta("boss", false) else false, "pos": [actor.position.x, actor.position.y, actor.position.z]})
	data["campaign_actors"] = actors
	var allies:Array= []
	for id:String in companion_actors:
		var actor: TypeRefCompanionActor = companion_actors[id]
		if is_instance_valid(actor):
			allies.append({"id": id, "health": actor.health, "downed": actor.downed_time, "pos": [actor.position.x, actor.position.y, actor.position.z]})
	data["companions"] = allies
	var army:Array= []
	for actor:SoldierView in ArmySystem.visual_actors:
		if is_instance_valid(actor) and not actor.is_queued_for_deletion():
			army.append({"id": actor.squad_id, "index": actor.formation_index, "health": actor.health, "pos": [actor.position.x, actor.position.y, actor.position.z]})
	data["army_actors"] = army
	return data

func load_world_state(data: Dictionary) -> void:
	super.load_world_state(data)
	var expected: Dictionary[String,Dictionary] = {}
	for state:Dictionary in data.get("campaign_actors", []): expected[state.id] = state
	var present: Dictionary[String,bool] = {}
	for actor:EnemyView in get_tree().get_nodes_in_group("enemies"):
		if not actor.has_meta("campaign_id"): continue
		var id: String = actor.get_meta("campaign_id")
		if id in CampaignSystem.fallen or actor.is_queued_for_deletion() or present.has(id) or (data.has("campaign_actors") and not expected.has(id)):
			actor.queue_free()
			continue
		present[id] = true
		if expected.has(id): restore_enemy(actor, expected[id])
	for id:String in expected:
		if present.has(id) or id in CampaignSystem.fallen: continue
		var state: Dictionary = expected[id]
		for faction:Dictionary in CampaignSystem.definition.factions:
			var faction_id:String=faction.id
			if not id.begins_with(faction_id+"_"):continue
			var saved_position:Array=state.pos
			var pos:Vector3=saved_vector(saved_position)
			var actor:EnemyView= spawn_enemy(id, faction_id, pos, 1, id.ends_with("_raider_2") and faction_id in ["borderland_watch", "marsh_keepers", "pass_clans"])
			restore_enemy(actor, state)
			break
	for id:String in CampaignSystem.assaults:
		if not CampaignSystem.camp_cleared(id, true): spawn_garrison(id)
	sync_siege_gates()
	for id:String in companion_actors.keys():
		if is_instance_valid(companion_actors[id]): companion_actors[id].queue_free()
	companion_actors.clear()
	for state:Dictionary in data.get("companions", []):
		if state.id not in CampaignSystem.companions: continue
		var actor:TypeRefCompanionActor= preload("res://scripts/ai/CompanionActor.gd").new()
		actor.companion_id = state.id
		actor.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(actor)
		var saved_position:Array=state.pos
		actor.position=saved_vector(saved_position)
		actor.health = state.health
		actor.downed_time = state.downed
		if actor.downed_time > 0:
			actor.remove_from_group("allies")
			actor.visual.rotation.z = PI * 0.5
		companion_actors[state.id] = actor
	ArmySystem.visual_timer = 0
	ArmySystem._process(0.5)
	for actor:SoldierView in ArmySystem.visual_actors:
		if not is_instance_valid(actor) or actor.is_queued_for_deletion(): continue
		for state:Dictionary in data.get("army_actors", []):
			var squad_id:int=state.id
			var formation_index:int=state.index
			if actor.squad_id==squad_id and actor.formation_index==formation_index:
				actor.health = state.health
				var saved_position:Array=state.pos
				actor.position=saved_vector(saved_position)

func restore_enemy(actor: EnemyView, state: Dictionary) -> void:
	var saved_position:Array=state.pos
	actor.position=saved_vector(saved_position)
	actor.home_position = actor.position
	actor.max_hp = state.get("max_hp", actor.max_hp)
	var health:float=state.hp
	actor.current_hp = clampf(health, 0, actor.max_hp)
	actor.damage = state.get("damage", actor.damage)
	actor.move_speed = state.get("speed", actor.move_speed)
	actor.attack_cooldown = state.get("cooldown", 0.0)
	actor.target_player = null
	if actor.get_meta("boss", false): (actor as BossView).is_enraged = state.get("enraged", false)

func apply_snapshot(data: Dictionary) -> void:
	var inventory:Array=data.get("inventory",[])
	var equipment:Dictionary=data.get("equipment",{})
	GameState.restore_items(inventory,equipment)
	GameState.player_hp = data.get("hp", 100)
	GameState.player_stamina = data.get("stamina", 100)
	GameState.recalculate_stats()
	var simulation:Dictionary=data.get("simulation",{})
	pause_menu.restore_simulation(simulation)
	var world_state:Dictionary=data.get("world",{})
	load_world_state(world_state)
	EventBus.inventory_updated.emit()
	EventBus.equipment_updated.emit()
	hud.update_bars()
	_sync_menu_state()

func show_ending(route: String) -> void:
	if is_instance_valid(ending_panel): return
	# SaveSystem reports persistence failure through the shared localized notification channel.
	@warning_ignore("return_value_discarded")
	pause_menu._on_save(true)
	AudioManager.play_finale(true)
	for menu:Control in [inventory_ui, settlement_ui, alchemy_ui, strategy_ui, town_ui, pause_menu]:
		menu.hide()
	ending_panel = preload("res://scripts/ui/CampaignFinale.gd").new()
	ending_panel.name = "CampaignEnding"
	ending_panel.route = route
	ending_panel.quests = completed_count()
	ending_panel.days = TimeSystem.current_day
	$CanvasLayer.add_child(ending_panel)
	ending_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_panel.z_index = 80
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	ending_panel.continued.connect(close_ending)
	_sync_menu_state()

func close_ending() -> void:
	ending_panel.queue_free()
	ending_panel = null
	_sync_menu_state()

func completed_count() -> int:
	return CampaignSystem.completed.size()

func desired_music() -> String:
	if not is_instance_valid(player): return "exploration"
	var mood:String= super.desired_music()
	if mood == "combat":
		for id:String in CampaignSystem.assaults:
			if id not in CampaignSystem.conquests: return "war"
		return mood
	if is_instance_valid(town_ui) and town_ui.visible: return "settlement"
	for data:Dictionary in CampaignSystem.definition.towns:
		var town_x:float=data.x
		var town_z:float=data.z
		if Vector2(player.position.x - town_x, player.position.z - town_z).length() < 35:
			return "settlement"
	return mood

func _on_player_died() -> void:
	AudioManager.play_finale(false)
	if is_instance_valid(town_ui): town_ui.hide()
	super._on_player_died()
	if CampaignSystem.iron_mode:
		CampaignSystem.iron_dead = true
		pause_menu.resume_btn.text = LocalizationManager.get_string("ui.iron_dead")
		pause_menu.resume_btn.disabled = true
		pause_menu.load_btn.disabled = true
		# SaveSystem reports persistence failure through the shared localized notification channel.
		@warning_ignore("return_value_discarded")
		SaveSystem.save_game({"hp": 0, "simulation": pause_menu.capture_simulation()}, true)
