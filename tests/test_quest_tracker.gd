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
	var localization: Node = root.get_node("LocalizationManager")
	var event_bus: Node = root.get_node("EventBus")
	var audio: Node = root.get_node("AudioManager")
	campaign.new_campaign(1, false)
	var world: Node3D = load("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame
	var hud: Control = world.hud
	var quest: Dictionary = campaign.tracked_objective()
	check(not quest.is_empty() and quest.id == "arc_01_01", "A new campaign tracks the first authored objective")
	hud.refresh_quest_tracker()
	check(hud.quest_panel.visible, "The objective tracker is visible in the HUD")
	check(hud.quest_label.text == campaign.tracked_objective_text(), "The tracker title comes from the campaign objective")
	check(hud.quest_label.text.contains(localization.get_string("quest.arc_01_01.title")), "The tracker shows the localized quest title")
	var players: Array = get_nodes_in_group("player")
	check(not players.is_empty(), "The world publishes a real player actor for distance tracking")
	var target: Vector3 = Vector3(0, 0, -150)
	if not players.is_empty():
		var distance: float = (players[0] as Node3D).global_position.distance_to(target)
		check(hud.quest_distance.text == localization.get_string("objective.distance", {"meters": int(distance)}), "The tracker shows the measured distance to the objective")
	check(hud.compass.active and hud.compass.target == target, "The compass points at the tracked settlement")
	var toasts: Array = []
	var listener: Callable = func(text: Variant, warning: Variant) -> void: toasts.append([str(text), warning == true])
	event_bus.notification_posted.connect(listener)
	var accepted: String = localization.get_string("objective.accepted", {"title": localization.get_string("quest.arc_01_02.title")})
	event_bus.notification_posted.emit(accepted, false)
	check(hud.notification_label.text == accepted and hud.notification_timer > 2.5, "Objective toasts use the HUD notification channel")
	var warning: String = localization.get_string("msg.inventory_full")
	event_bus.notification_posted.emit(warning, true)
	var warning_color: Color = hud.notification_label.get_theme_color("font_color")
	check(hud.notification_label.text == warning and warning_color.r > 0.9 and warning_color.g < 0.5, "Warning toasts use the warning color instead of ordinary text")
	campaign.visited.append("greenhaven")
	campaign.refresh()
	check(campaign.completed.has("arc_01_01"), "Reaching the tracked town completes the objective")
	hud.refresh_quest_tracker()
	check(hud.quest_label.text == campaign.tracked_objective_text(), "The tracker advances to the next objective after completion")
	var completed_toast: bool = toasts.any(func(entry: Array) -> bool: return entry[0].contains(localization.get_string("quest.arc_01_01.title")))
	check(completed_toast, "Completing an objective announces it through the toast channel")
	check(voices(audio, "coin") > 0, "A completed objective pays its reward with a coin cue")
	event_bus.notification_posted.disconnect(listener)
	for index: int in 25:
		hud.refresh_quest_tracker()
	check(hud.quest_label.text == campaign.tracked_objective_text(), "Rapid tracker refreshes stay stable and idempotent")
	world.toggle_pause()
	await process_frame
	check(hud.quest_panel.visible and hud.quest_label.text == campaign.tracked_objective_text(), "The tracker keeps its state while the pause menu is open")
	world.toggle_pause()
	await process_frame
	var map: Control = load("res://scripts/ui/MarchMap.gd").new()
	root.add_child(map)
	map.size = Vector2(720, 520)
	await process_frame
	check(map.legend.get_child_count() == 5, "The campaign map explains all five marker types")
	var objective_legend: String = localization.get_string("map.objective")
	check(map.legend_label(4).text == objective_legend, "The legend names the objective marker in the active language")
	check(map.legend_icon(4).texture != null and map.legend_icon(4).texture.resource_path.ends_with("objective.svg"), "The legend draws the authored objective icon")
	var icons_ready: bool = true
	for index: int in 5:
		icons_ready = icons_ready and map.legend_icon(index).texture != null and not map.legend_label(index).text.is_empty()
	check(icons_ready, "Every legend row pairs an authored icon with a localized label")
	var marker: Dictionary = map.objective_marker()
	check(not marker.is_empty(), "The map exposes an objective marker while a quest is tracked")
	check(marker.get("position") == map.map_position(0.0, -150.0), "The map marker sits on the tracked settlement")
	check(Rect2(Vector2.ZERO, map.size).has_point(marker.get("position")), "The objective marker stays inside the map surface")
	check(is_equal_approx(marker.get("radius"), 14.0), "The objective marker keeps its authored radius")
	campaign.active = false
	check(map.objective_marker().is_empty(), "The map hides the marker when no campaign objective exists")
	campaign.active = true
	var tracked: Dictionary = campaign.tracked_objective()
	var launch_language: String = str(localization.current_language)
	var other_language: String = "en" if launch_language == "ru" else "ru"
	var before_switch: String = hud.quest_label.text
	localization.set_language(other_language)
	await process_frame
	hud.localize()
	check(not tracked.is_empty() and hud.quest_label.text != before_switch
		and hud.quest_label.text.contains(localization.get_string(str(tracked.get("title", "")))),
		"The tracker relocalizes into " + other_language + " without losing the objective")
	check(map.legend_label(4).text.contains(localization.get_string("map.objective")), "The map legend relocalizes with the interface")
	localization.set_language(launch_language)
	await process_frame
	check(hud.quest_label.text == campaign.tracked_objective_text(), "The tracker returns to " + launch_language + " with the same objective")
	map.queue_free()
	world.queue_free()
	await process_frame
	campaign.new_campaign(1, false)
	print("QUEST TRACKER RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
