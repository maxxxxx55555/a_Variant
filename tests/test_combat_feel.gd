extends "res://tests/AudioCleanTree.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func voices(audio: Node, cue: String) -> int:
	var count: int = 0
	var stream: Variant = audio._stream(cue)
	for player: Variant in audio.effect_players + audio.spatial_players:
		if player.playing and player.stream == stream:
			count += 1
	return count

func run() -> void:
	await process_frame
	var campaign: Node = root.get_node("CampaignSystem")
	var settings: Node = root.get_node("SettingsManager")
	var game: Node = root.get_node("GameState")
	var audio: Node = root.get_node("AudioManager")
	campaign.new_campaign(1, false)
	check(settings.hit_stop_enabled, "Hit-stop is enabled by default")
	check(settings.hit_stop_ms >= 60 and settings.hit_stop_ms <= 90, "Hit-stop length stays inside the authored 60-90 ms window")
	check(settings.damage_numbers, "Damage numbers are enabled by default")
	var world: Node3D = load("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame
	var player: Node3D = world.player
	var enemy: Node3D = world.enemy
	var hud: Control = world.hud
	settings.reduced_motion = true
	player.apply_hit_stop()
	check(is_equal_approx(Engine.time_scale, 1.0), "Reduced motion disables the hit-stop freeze")
	settings.reduced_motion = false
	var sword: Resource = load("res://data/weapons/iron_sword.tres")
	check(game.add_item(sword) and game.equip_item(game.inventory.size() - 1), "The combat fixture equips a real sword")
	await process_frame
	check(player.weapon_view != null and player.weapon_view.visible and player.weapon_view.weapon_kind == "sword", "The first-person weapon view reflects the equipped sword")
	enemy.set_physics_process(false)
	enemy.detection_range = 0.0
	enemy.global_position = player.global_position + Vector3(0.0, 0.7, -1.45)
	player.camera.rotation.x = -0.18
	# The physics server adopts a teleported body transform on the following step.
	await physics_frame
	await physics_frame
	var hp_before: float = enemy.current_hp
	var stamina_before: float = game.player_stamina
	player.perform_attack()
	check(enemy.current_hp < hp_before, "A melee attack lands on the real enemy in front of the player")
	check(game.player_stamina < stamina_before, "Attacking spends real stamina")
	check(player.weapon_view.slash > 0.0, "The weapon begins its authored swing curve")
	check(player.weapon_view.recoil > 0.0, "A landed hit adds weapon recoil")
	check(is_equal_approx(Engine.time_scale, 0.05), "A landed hit freezes time for the hit-stop window")
	check(enemy.flash_time > 0.0, "A hit flashes the struck actor")
	var overlay_found: bool = false
	for mesh: Node in enemy.visual.find_children("*", "MeshInstance3D", true, false):
		if (mesh as MeshInstance3D).material_overlay != null:
			overlay_found = true
	check(overlay_found, "The hit flash is visible on the actor meshes")
	var spark: Node = null
	for child: Node in world.get_children():
		if child.get_script() == load("res://scripts/vfx/HitSpark.gd"):
			spark = child
			break
	check(spark != null and spark.get_child_count() == 7, "A hit spawns the seven-shard impact spark")
	check(voices(audio, "swing") > 0 and voices(audio, "hit_flesh") > 0, "The swing and flesh impact have distinct audio cues")
	check(hud.target_health.visible and hud.target_timer > 0.0, "The HUD reports the struck enemy health")
	var damage_popup: Label = null
	for child: Node in hud.get_children():
		if child is Label and (child as Label).text.begins_with("−"):
			damage_popup = child
	check(damage_popup != null, "A real hit spawns a floating damage number")
	if damage_popup:
		check(damage_popup.get_theme_font_size("font_size") >= 23, "Damage numbers stay legible while rising")
	await create_timer(0.16, true, false, true).timeout
	check(is_equal_approx(Engine.time_scale, 1.0), "Hit-stop releases after its bounded real-time window")
	var frozen_hp: float = enemy.current_hp
	player.perform_attack()
	check(enemy.current_hp == frozen_hp, "Attack cooldown blocks a rapid second swing")
	# The shards age on scaled game time, so they outlive the freeze by their full authored lifetime.
	await create_timer(0.5).timeout
	check(not is_instance_valid(spark), "The impact spark cleans itself up")
	await create_timer(0.35).timeout
	var blade: Node3D = player.weapon_view.blade
	player.weapon_view.slash = 0.32
	player.weapon_view._process(0.05)
	var early: Vector3 = blade.rotation
	player.weapon_view._process(0.12)
	check(blade.rotation != early, "The weapon swing follows a curved, non-linear arc")
	check(player.weapon_view.blade.position.z >= 0.0, "Weapon recoil never pushes the blade through the camera")
	if damage_popup and is_instance_valid(damage_popup):
		await create_timer(0.8).timeout
	check(not is_instance_valid(damage_popup), "Damage numbers fade and free themselves")
	var labels_before: int = hud.get_child_count()
	settings.damage_numbers = false
	hud.spawn_damage_number(10.0, player.global_position + Vector3.UP, 100.0)
	check(hud.get_child_count() == labels_before, "Disabling damage numbers suppresses the popup")
	settings.damage_numbers = true
	world.toggle_pause()
	await process_frame
	player.apply_hit_stop()
	check(is_equal_approx(Engine.time_scale, 1.0), "The pause screen never starts a hidden hit-stop")
	world.toggle_pause()
	await process_frame
	settings.hit_stop_enabled = false
	player.apply_hit_stop()
	check(is_equal_approx(Engine.time_scale, 1.0) and not player._hit_stop_active, "Disabling hit-stop in the settings releases the freeze")
	settings.hit_stop_enabled = true
	world.queue_free()
	await process_frame
	campaign.new_campaign(1, false)
	print("COMBAT FEEL RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
