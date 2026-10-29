extends "res://tests/AudioCleanTree.gd"

var failures := 0
const LootStyle = preload("res://scripts/ui/LootStyle.gd")

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func voices(audio: Node, cue: String) -> Array:
	var found: Array = []
	var stream: Variant = audio._stream(cue)
	for player: Variant in audio.effect_players + audio.spatial_players:
		if player.playing and player.stream == stream:
			found.append(player)
	return found

func stop_voices(audio: Node) -> void:
	for player: Variant in audio.effect_players + audio.spatial_players:
		player.stop()

func spawn_pickup(scene: PackedScene, resource: Resource, at: Vector3) -> Node3D:
	var pickup: Node3D = scene.instantiate()
	pickup.item_resource = resource
	pickup.position = at
	root.add_child(pickup)
	return pickup

func run() -> void:
	await process_frame
	var game: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	var localization: Node = root.get_node("LocalizationManager")
	var common: Resource = load("res://data/weapons/iron_sword.tres")
	var uncommon: Resource = load("res://data/weapons/dagger_hardened.tres")
	var rare: Resource = load("res://data/weapons/dagger_tempered.tres")
	var epic: Resource = load("res://data/weapons/dagger_guild.tres")
	var legendary: Resource = load("res://data/weapons/dagger_master.tres")
	check(LootStyle.rarity_of(common) == "common" and LootStyle.rarity_of(uncommon) == "uncommon", "Authored weapons expose their common and uncommon rarity")
	check(LootStyle.rarity_of(rare) == "rare" and LootStyle.rarity_of(epic) == "epic" and LootStyle.rarity_of(legendary) == "legendary", "Authored weapons cover the full rarity ladder")
	check(LootStyle.COLORS.size() == 5, "Every rarity has an authored color")
	var seen: Dictionary = {}
	for rarity: String in LootStyle.COLORS:
		seen[LootStyle.COLORS[rarity].to_html(false)] = true
	check(seen.size() == 5, "Rarity colors stay visually distinct")
	check(LootStyle.color_of("mythic") == LootStyle.color_of("common") and LootStyle.rarity_of(null) == "common", "Unknown or missing rarity falls back to common styling")
	check(LootStyle.rarity_of({"rarity": "epic"}) == "epic" and LootStyle.rarity_of({"rarity": "bogus"}) == "common", "Inventory records are classified by their validated rarity")
	check(LootStyle.color_for({"rarity": "rare"}) == LootStyle.COLORS["rare"], "Rarity colors resolve for inventory records")
	var pickup_scene: PackedScene = load("res://scenes/items/world_item.tscn")
	var common_pickup: Node3D = spawn_pickup(pickup_scene, common, Vector3(0, 1, 0))
	var legendary_pickup: Node3D = spawn_pickup(pickup_scene, legendary, Vector3(4, 1, 0))
	await process_frame
	var halo: MeshInstance3D = legendary_pickup.get_node_or_null("RarityGlow") as MeshInstance3D
	check(halo != null and halo.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Rare loot carries a non-shadowing glow halo")
	var halo_material: StandardMaterial3D = halo.material_override as StandardMaterial3D
	check(halo_material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and halo_material.blend_mode == BaseMaterial3D.BLEND_MODE_ADD, "The halo blends additively without lighting")
	check(is_equal_approx(halo_material.albedo_color.r, LootStyle.COLORS["legendary"].r) and is_equal_approx(halo_material.albedo_color.a, 0.17), "The halo is tinted with the legendary color at a calm opacity")
	var gem_material: StandardMaterial3D = legendary_pickup._mesh.material_override as StandardMaterial3D
	check(gem_material.albedo_color == LootStyle.COLORS["legendary"] and is_equal_approx(gem_material.emission_energy_multiplier, 2.4), "Legendary loot glows brightly in its rarity color")
	var common_material: StandardMaterial3D = common_pickup._mesh.material_override as StandardMaterial3D
	check(common_material.albedo_color == LootStyle.COLORS["common"] and is_equal_approx(common_material.emission_energy_multiplier, 1.2), "Common loot uses a quieter authored glow")
	check(legendary_pickup.get_interaction_prompt().contains(localization.get_string("item.dagger_master.name")), "The pickup prompt names the localized item")
	legendary_pickup._phase = 0.0
	legendary_pickup._mesh.position.y = 0.12
	legendary_pickup._halo.scale = Vector3.ONE
	legendary_pickup._process(PI / 4.0)
	check(legendary_pickup._mesh.position.y > 0.15 and legendary_pickup._mesh.rotation.y > 0.0, "Loot bobs and turns while it waits to be collected")
	check(legendary_pickup._halo.scale.x > 1.05, "The halo breathes with the bob")
	stop_voices(audio)
	common_pickup._play_rarity_cue()
	check(voices(audio, "pickup").size() > 0 and voices(audio, "loot_chime").is_empty(), "Common loot uses the ordinary pickup cue without the rarity chime")
	stop_voices(audio)
	var inventory_before: int = game.inventory.size()
	legendary_pickup.interact(null)
	check(game.inventory.size() == inventory_before + 1, "Collecting loot adds the real item to the inventory")
	var chimes: Array = voices(audio, "loot_chime")
	check(chimes.size() == 1, "Rare and better loot rings a dedicated chime")
	if chimes.size() == 1:
		check(is_equal_approx(float(chimes[0].pitch_scale), 1.16), "Legendary loot rings the highest authored pitch")
		check(chimes[0].global_position.is_equal_approx(Vector3(4, 1, 0)), "The chime is voiced at the pickup")
	check(legendary_pickup.monitorable == false, "Collected loot stops being detectable at once")
	await create_timer(0.12).timeout
	check(legendary_pickup.collision_layer == 0 and legendary_pickup.monitoring == false, "Collected loot leaves the collision layers")
	check(legendary_pickup._mesh.position.y > 0.5 and legendary_pickup._halo.transparency > 0.1, "The collect pop lifts the gem while the halo fades")
	check(game.inventory.size() == inventory_before + 1, "The pop does not collect the same loot twice")
	legendary_pickup.interact(null)
	check(game.inventory.size() == inventory_before + 1, "Repeated interaction with a collected pickup is ignored")
	await create_timer(0.4).timeout
	check(not is_instance_valid(legendary_pickup), "Collected loot frees itself after the pop")
	var rare_pickup: Node3D = spawn_pickup(pickup_scene, rare, Vector3(7, 1, 0))
	await process_frame
	stop_voices(audio)
	rare_pickup.interact(null)
	chimes = voices(audio, "loot_chime")
	check(chimes.size() == 1 and is_equal_approx(float(chimes[0].pitch_scale), 1.0), "Rare loot rings the base chime pitch")
	var epic_pickup: Node3D = spawn_pickup(pickup_scene, epic, Vector3(10, 1, 0))
	await process_frame
	stop_voices(audio)
	epic_pickup.interact(null)
	chimes = voices(audio, "loot_chime")
	check(chimes.size() == 1 and is_equal_approx(float(chimes[0].pitch_scale), 1.08), "Epic loot rings a higher chime pitch")
	var uncommon_pickup: Node3D = spawn_pickup(pickup_scene, uncommon, Vector3(13, 1, 0))
	await process_frame
	stop_voices(audio)
	uncommon_pickup.interact(null)
	check(voices(audio, "pickup").size() > 0 and voices(audio, "loot_chime").is_empty(), "Uncommon loot still uses the ordinary pickup cue")
	var ui: Control = load("res://scenes/ui/inventory_ui.tscn").instantiate()
	root.add_child(ui)
	await process_frame
	var rare_index: int = -1
	for index: int in game.inventory.size():
		if str(game.inventory[index].get("resource_path", "")).ends_with("dagger_tempered.tres"):
			rare_index = index
	check(rare_index >= 0, "The collected rare loot is present in the inventory model")
	ui.refresh_inventory()
	check(ui.item_list.item_count == game.inventory.size(), "The inventory list mirrors the collected loot")
	if rare_index >= 0 and rare_index < ui.item_list.item_count:
		check(ui.item_list.get_item_custom_fg_color(rare_index) == LootStyle.COLORS["rare"], "Inventory rows are tinted by rarity")
		ui._on_item_selected(rare_index)
		check(ui.item_card_label.text.contains("#" + LootStyle.COLORS["rare"].to_html(false)), "The item card tints the rarity line")
		check(ui.item_card_label.text.contains(localization.get_string("ui.rarity.rare")), "The item card names the rarity in the active language")
	check(game.equip_item(rare_index), "The collected rare weapon can be equipped")
	ui.refresh_equipment()
	check(ui.weapon_btn.get_theme_color("font_color") == LootStyle.COLORS["rare"], "Equipped slots inherit the item rarity color")
	var epic_index: int = -1
	for index: int in game.inventory.size():
		if str(game.inventory[index].get("resource_path", "")).ends_with("dagger_guild.tres"):
			epic_index = index
	check(epic_index >= 0, "The epic pickup remains available for another collection")
	ui.queue_free()
	await process_frame
	print("LOOT FEEL RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
