extends "res://tests/AudioCleanTree.gd"

var failures := 0
var audio: Node
var event_bus: Node
var localization: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func voices(cue: String) -> Array:
	var found: Array = []
	var stream: Variant = audio._stream(cue)
	for player: Variant in audio.effect_players + audio.spatial_players:
		if player.playing and player.stream == stream:
			found.append(player)
	return found

func run() -> void:
	await process_frame
	audio = root.get_node("AudioManager")
	event_bus = root.get_node("EventBus")
	localization = root.get_node("LocalizationManager")
	var campaign: Node = root.get_node("CampaignSystem")
	var army: Node = root.get_node("ArmySystem")
	var game: Node = root.get_node("GameState")
	var economy: Node = root.get_node("EconomySystem")
	var save: Node = root.get_node("SaveSystem")
	campaign.new_campaign(2, false)
	check(army.recruit("militia_spear", 2), "NG+ fixture recruits a real roster through the economy")
	var sword: Resource = load("res://data/weapons/iron_sword.tres")
	check(game.add_item(sword), "NG+ fixture adds a carried weapon")
	check(not game.inventory.is_empty() and game.equip_item(0), "NG+ fixture equips the carried weapon")
	var carried_weapon: String = str(game.equipment.weapon.get("resource_path", ""))
	var carried_squad: String = str(army.squads[0].unit_res_path)
	campaign.titles.clear()
	campaign.titles.append("oath.title.hard")
	campaign.announced_ending = "diplomatic"
	check(campaign.second_oath_available(), "A finished campaign offers the second oath")
	var toasts: Array = []
	var listener: Callable = func(text: Variant, warning: Variant) -> void: toasts.append([str(text), warning == true])
	event_bus.notification_posted.connect(listener)
	check(campaign.begin_second_oath(["iron", "wanderer"]), "Second oath starts a fresh campaign level")
	event_bus.notification_posted.disconnect(listener)
	check(campaign.ng_level == 1 and campaign.difficulty == 2, "Second oath increments the cycle without losing difficulty")
	check(campaign.oaths == ["iron", "wanderer"], "Chosen oath ids are stored for the whole cycle")
	check(campaign.titles == ["oath.title.hard"], "Victory titles carry into the next cycle")
	check(campaign.ng_banner == "oath.banner.iron", "The first chosen oath supplies the carried banner")
	check(campaign.iron_mode and not campaign.iron_dead, "The iron oath keeps a single life for the new cycle")
	check(campaign.sieges_allowed, "The iron and wanderer oaths leave sieges available")
	check(is_equal_approx(campaign.loot_multiplier, 2.0), "The wanderer oath doubles campaign loot")
	check(is_equal_approx(campaign.production_multiplier, 0.5), "The wanderer oath weakens settlement output")
	check(is_equal_approx(campaign.enemy_scale(), 1.3), "NG+ scales enemies by the oath level")
	check(campaign.visited.is_empty() and campaign.completed.is_empty() and campaign.brewed == 0, "The new cycle clears map and quest progress")
	check(game.inventory.is_empty(), "The new cycle starts without loose inventory")
	check(game.equipment.weapon != null and str(game.equipment.weapon.get("resource_path", "")) == carried_weapon, "Equipped gear carries into the new cycle")
	check(army.squads.size() == 1 and army.squads[0].count == 2 and str(army.squads[0].unit_res_path) == carried_squad, "The army roster carries with its real unit path")
	check(army.next_squad_id == 2, "The carried roster keeps unique squad ids")
	check(is_equal_approx(economy.stockpiles.gold, 200.0), "A normal second oath keeps the authored starting supplies")
	check(not voices("upgrade").is_empty(), "Starting the second oath has an upgrade cue")
	var expected_start: String = localization.get_string("oath.second.started", {"level": campaign.ng_level})
	var announced: bool = toasts.any(func(entry: Array) -> bool: return entry[0] == expected_start and not bool(entry[1]))
	check(announced, "The second oath announces its start without a warning tone")
	campaign.announced_ending = "diplomatic"
	check(campaign.begin_second_oath(["peace"]), "A third cycle can add the peace oath")
	check(campaign.ng_level == 2 and not campaign.sieges_allowed, "The peace oath forbids new sieges")
	var warnings: Array = []
	var warning_listener: Callable = func(text: Variant, warning: Variant) -> void:
		if warning == true:
			warnings.append(str(text))
	event_bus.notification_posted.connect(warning_listener)
	check(not campaign.start_assault("iron_guild"), "A forbidden siege never reaches the siege system")
	event_bus.notification_posted.disconnect(warning_listener)
	check(not warnings.is_empty() and warnings[0] == localization.get_string("siege.peace_forbidden"), "The forbidden siege explains itself in the active language")
	campaign.announced_ending = "diplomatic"
	check(campaign.begin_second_oath(["poverty"]), "A fourth cycle can add the poverty oath")
	check(economy.stockpiles.food == 0.0 and economy.stockpiles.gold == 0.0, "The poverty oath starts every stockpile empty")
	check(is_equal_approx(campaign.enemy_scale(), 1.9), "Each second-oath level keeps scaling enemies")
	campaign.new_campaign(0, false, {"level": 2, "oaths": ["wanderer"], "titles": ["oath.title.story"], "banner": "oath.banner.wanderer"})
	check(campaign.ng_level == 2 and campaign.oaths == ["wanderer"], "Authored NG data can be restored directly")
	check(campaign.ng_banner == "oath.banner.wanderer" and campaign.titles == ["oath.title.story"], "Authored NG banners and titles survive campaign creation")
	check(is_equal_approx(campaign.enemy_scale(), 1.6), "Direct NG data uses the same enemy curve")
	var snapshot: Dictionary = campaign.capture_state()
	campaign.ng_level = 9
	campaign.oaths.clear()
	campaign.oaths.append("iron")
	campaign.titles.clear()
	campaign.ng_banner = "tampered"
	campaign.restore_state(snapshot)
	check(campaign.ng_level == 2 and campaign.oaths == ["wanderer"] and campaign.ng_banner == "oath.banner.wanderer", "Restoring a campaign snapshot restores NG+ identity")
	check(not campaign.iron_mode and campaign.sieges_allowed and is_equal_approx(campaign.loot_multiplier, 2.0), "Restoring a snapshot reapplies oath effects instead of trusting stale flags")
	save.selected_slot = 4
	check(save.save_game({"simulation": {"campaign": snapshot}}), "NG+ state fits the protected save envelope")
	var loaded: Dictionary = save.load_slot(4)
	var loaded_campaign: Dictionary = loaded.get("simulation", {}).get("campaign", {})
	check(not loaded_campaign.is_empty(), "The saved campaign snapshot loads back")
	campaign.new_campaign(1, false)
	campaign.restore_state(loaded_campaign)
	check(campaign.ng_level == 2 and campaign.oaths == ["wanderer"] and campaign.titles == ["oath.title.story"], "A saved NG+ cycle restores level, oaths and titles")
	check(is_equal_approx(campaign.loot_multiplier, 2.0) and is_equal_approx(campaign.production_multiplier, 0.5), "A loaded NG+ cycle restores derived oath multipliers")
	var panel: Control = load("res://scripts/ui/OathPanel.gd").new()
	root.add_child(panel)
	await process_frame
	check(panel.checks.size() == 4, "The second-oath panel offers all four authored oaths")
	check(panel.checks["iron"] is CheckButton and panel.checks["iron"].has_focus(), "The oath panel opens on a real keyboard focus")
	check(panel.carry_label.text.contains(localization.get_string("oath.title.story")), "The oath panel previews the titles that will carry")
	var chosen: Array = []
	panel.started.connect(func(selected: Array) -> void: chosen.append_array(selected))
	panel.checks["peace"].button_pressed = true
	check(panel.selected() == ["peace"], "Toggling an oath updates the selection")
	check(panel.banner_preview.tooltip_text == localization.get_string("oath.banner.peace"), "The banner preview names the chosen oath")
	panel.start_button.pressed.emit()
	await process_frame
	check(chosen == ["peace"] and not is_instance_valid(panel), "Starting the oath reports the choice and closes the panel")
	campaign.new_campaign(1, false, {"level": 5, "oaths": ["invented", 7, "iron"], "titles": ["", 9, "x".repeat(200), "oath.title.expert"]})
	check(campaign.ng_level == 5 and campaign.oaths == ["iron"], "Unknown or malformed oath ids never reach runtime state")
	check(campaign.titles == ["oath.title.expert"] and campaign.iron_mode, "Malformed titles are dropped while valid titles and oath effects survive")
	campaign.new_campaign(1, false)
	check(campaign.ng_level == 0 and campaign.oaths.is_empty() and not campaign.iron_mode and army.squads.is_empty(), "A plain campaign reset clears every NG+ effect")
	print("SECOND OATH RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
