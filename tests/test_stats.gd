extends "res://tests/AudioCleanTree.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func run() -> void:
	await process_frame
	var stats: Node = root.get_node("ProfileStats")
	var localization: Node = root.get_node("LocalizationManager")
	var campaign: Node = root.get_node("CampaignSystem")
	var guard_script: GDScript = load("res://scripts/security/SaveGuard.gd")
	stats.restore_state({})
	check(int(stats.data.runs) == 0 and int(stats.data.wins) == 0 and int(stats.data.losses) == 0, "A fresh profile starts with empty totals")
	check(stats.by_difficulty().size() == 4 and int(stats.row(0).best_day) == 0 and str(stats.data.last_result) == "", "The profile tracks all four difficulties separately")
	check(stats.summary() == localization.get_string("menu.stats_summary", {"runs": 0, "wins": 0}), "The profile summary is localized and honest when empty")
	stats.begin_run(1)
	check(int(stats.data.runs) == 1 and int(stats.row(1).runs) == 1, "Beginning a run counts it on both the total and its difficulty")
	stats.finish_victory(1, 12, 500.0, 3, 600.0)
	check(int(stats.data.wins) == 1 and int(stats.data.losses) == 0 and str(stats.data.last_result) == "win", "A victory is recorded in the totals")
	check(is_equal_approx(float(stats.data.max_wealth), 500.0) and int(stats.data.regions) == 3 and is_equal_approx(float(stats.data.seconds), 600.0), "A victory records wealth, regions and playtime")
	check(int(stats.row(1).best_day) == 12 and is_equal_approx(float(stats.row(1).best_wealth), 500.0), "The difficulty row remembers the winning day and wealth")
	stats.finish_victory(1, 8, 750.0, 4, 300.0)
	check(int(stats.data.wins) == 2 and int(stats.row(1).best_day) == 8 and is_equal_approx(float(stats.row(1).best_wealth), 750.0), "A faster, richer victory replaces the best day and wealth")
	stats.finish_defeat(1, 30, 100.0, 0, 100.0)
	check(int(stats.data.losses) == 1 and str(stats.data.last_result) == "loss" and int(stats.row(1).best_day) == 8, "A defeat never overwrites the best winning day")
	stats.finish_victory(0, 20, 900.0, 5, 50.0)
	check(int(stats.row(0).wins) == 1 and int(stats.row(0).best_day) == 20 and int(stats.data.regions) == 5, "Difficulty rows stay independent while regions keep the record")
	stats.begin_run(99)
	check(int(stats.data.runs) == 2 and int(stats.row(3).runs) == 1, "Out-of-range difficulties clamp to the last tracked row")
	stats.finish_victory(2, -5, -100.0, 1000, -50.0)
	check(int(stats.row(2).best_day) == 1 and is_equal_approx(float(stats.row(2).best_wealth), 0.0), "Negative days clamp to day one and wealth never goes negative")
	check(int(stats.data.regions) == 100, "Region counts are capped at the authored maximum")
	check(is_equal_approx(float(stats.data.seconds), 1050.0) and is_equal_approx(float(stats.data.max_wealth), 900.0), "Negative durations and wealth cannot reduce the recorded totals")
	stats.restore_state({"runs": "many", "wins": -4, "losses": 2.9, "regions": 500, "max_wealth": NAN, "seconds": "soon", "last_result": "bogus", "by_difficulty": [{"runs": -2, "wins": -1, "losses": 1.7, "best_day": -9, "best_wealth": -5}]})
	check(int(stats.data.runs) == 0 and int(stats.data.wins) == 0 and int(stats.data.losses) == 2 and int(stats.data.regions) == 100, "Restored totals are sanitized to bounded integers")
	check(is_equal_approx(float(stats.data.max_wealth), 0.0) and is_equal_approx(float(stats.data.seconds), 0.0) and str(stats.data.last_result) == "", "Restored decimals and results are sanitized")
	check(int(stats.row(0).runs) == 0 and int(stats.row(0).losses) == 1 and int(stats.row(0).best_day) == 0 and is_equal_approx(float(stats.row(0).best_wealth), 0.0), "Difficulty rows are sanitized independently")
	var copy: Dictionary = stats.capture_state()
	copy.runs = 99
	(copy.by_difficulty[0] as Dictionary).wins = 77
	check(int(stats.data.runs) == 0 and int(stats.row(0).wins) == 0, "Captured statistics are a deep copy")
	stats.restore_state({"runs": 9, "wins": 5, "losses": 4, "regions": 7, "max_wealth": 2222.0, "seconds": 90.0, "last_result": "loss", "by_difficulty": [{"runs": 9, "wins": 5, "losses": 4, "best_day": 11, "best_wealth": 2222.0}]})
	check(stats.summary() == localization.get_string("menu.stats_summary", {"runs": 9, "wins": 5}), "The summary reports the accumulated run totals")
	check(stats.save_profile(), "The profile writes an authenticated local envelope")
	var raw: String = FileAccess.get_file_as_string("user://profile_stats.json")
	var envelope: Variant = JSON.parse_string(raw)
	check(envelope is Dictionary and int((envelope as Dictionary).get("version", 0)) == 1, "The profile persists a versioned envelope")
	var body: String = str((envelope as Dictionary).get("data", ""))
	var auth: String = str((envelope as Dictionary).get("auth", ""))
	check(body.begins_with("{") and auth.length() == 64 and guard_script.authentic(body, "march/profile_stats.json", auth), "The stored profile carries a valid local signature")
	stats.restore_state({})
	stats.load_profile()
	check(int(stats.data.runs) == 9 and int(stats.data.wins) == 5 and int(stats.row(0).best_day) == 11 and is_equal_approx(float(stats.data.max_wealth), 2222.0), "The authentic profile reloads every recorded value")
	var tampered_envelope: Dictionary = (JSON.parse_string(raw) as Dictionary).duplicate(true)
	var tampered_body: Dictionary = JSON.parse_string(str(tampered_envelope.get("data", "")))
	tampered_body["runs"] = 123456
	tampered_envelope["data"] = JSON.stringify(tampered_body, "", true, true)
	var tampered_file: FileAccess = FileAccess.open("user://profile_stats.json", FileAccess.WRITE)
	check(tampered_file != null, "The tamper fixture can write the profile path")
	if tampered_file:
		tampered_file.store_string(JSON.stringify(tampered_envelope, "", true, true))
		tampered_file.close()
	stats.restore_state({})
	stats.load_profile()
	check(int(stats.data.runs) == 0, "A tampered profile body is rejected instead of trusted")
	check(stats.save_profile(), "The profile can rewrite an authentic envelope after tampering")
	stats.restore_state({})
	stats.load_profile()
	check(int(stats.data.runs) == 0, "The rewritten profile reloads cleanly")
	stats.restore_state({"runs": 7, "wins": 4, "losses": 3, "regions": 6, "max_wealth": 12345.0, "seconds": 3720.0, "last_result": "win", "by_difficulty": [{"runs": 2, "wins": 1, "losses": 1, "best_day": 9, "best_wealth": 900.0}, {"runs": 3, "wins": 2, "losses": 1, "best_day": 14, "best_wealth": 3000.0}, {"runs": 2, "wins": 1, "losses": 1, "best_day": 0, "best_wealth": 100.0}, {"runs": 0, "wins": 0, "losses": 0, "best_day": 0, "best_wealth": 0.0}]})
	var panel: Control = load("res://scripts/ui/StatsPanel.gd").new()
	root.add_child(panel)
	await process_frame
	check(panel.title_label.text == localization.get_string("ui.stats"), "The statistics page opens with a localized title")
	check(panel.body.text.contains(localization.get_string("stats.runs")) and panel.body.text.contains("7"), "The page reports campaign totals")
	check(panel.body.text.contains(localization.get_string("stats.wins")) and panel.body.text.contains("4") and panel.body.text.contains(localization.get_string("stats.losses")), "The page reports victories and defeats")
	check(panel.body.text.contains(localization.get_string("stats.hours_minutes", {"hours": 1, "minutes": 2})), "The page formats playtime as one hour and two minutes")
	for difficulty: String in ["story", "normal", "hard", "expert"]:
		check(panel.body.text.contains(localization.get_string("difficulty." + difficulty)), "The page lists the %s difficulty row" % difficulty)
	check(panel.body.text.contains("14") and panel.body.text.contains(localization.get_string("stats.none")), "Best days appear per difficulty with a placeholder when unset")
	check(panel.body.text.contains(localization.get_string("stats.local_note")), "The page states that statistics stay local")
	check(panel.close_button.has_focus(), "Statistics open with focus on the close action")
	check(root.get_visible_rect().encloses(panel.close_button.get_global_rect()), "The close action stays inside the window")
	var closed_hits: Array = []
	panel.closed.connect(func() -> void: closed_hits.append(true))
	var escape: InputEventAction = InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	panel._unhandled_key_input(escape)
	check(closed_hits.size() == 1, "Escape closes the statistics page")
	await process_frame
	check(not is_instance_valid(panel), "Closing statistics frees the page")
	var english_panel: Control = load("res://scripts/ui/StatsPanel.gd").new()
	root.add_child(english_panel)
	await process_frame
	localization.set_language("en")
	await process_frame
	check(english_panel.title_label.text == "Statistics", "The statistics page relocalizes its title")
	check(english_panel.body.text.contains("Campaigns") and english_panel.body.text.contains("By difficulty") and english_panel.body.text.contains("Statistics are stored on this device only."), "The statistics page relocalizes its body and privacy note")
	localization.set_language("ru")
	await process_frame
	check(english_panel.title_label.text == localization.get_string("ui.stats"), "The statistics page returns to Russian with the active locale")
	english_panel.close_button.pressed.emit()
	await process_frame
	check(not is_instance_valid(english_panel), "The close button frees the statistics page")
	var menu: Control = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	var stats_button: Button = menu.find_child("StatsButton", true, false) as Button
	check(stats_button != null and stats_button.text == localization.get_string("ui.stats"), "The main menu exposes a localized statistics button")
	if stats_button:
		check(root.get_visible_rect().encloses(stats_button.get_global_rect()), "The statistics button stays inside the window")
		stats_button.grab_focus()
		stats_button.pressed.emit()
		await process_frame
		var menu_panel: Control = menu.find_child("StatsPanel", true, false) as Control
		check(menu_panel != null and menu_panel.visible, "The menu button opens the local statistics page")
		if menu_panel:
			var close: Button = menu_panel.find_child("CloseStats", true, false) as Button
			check(close != null, "The opened page keeps its close action")
			if close:
				close.pressed.emit()
			await process_frame
			check(stats_button.has_focus(), "Closing statistics returns focus to the menu button")
	var saved_active: bool = campaign.active
	var saved_level: int = campaign.ng_level
	menu.cached_save = {}
	campaign.active = true
	campaign.ng_level = 2
	campaign.ng_banner = "oath.banner.iron"
	campaign.titles.clear()
	campaign.titles.append("oath.title.story")
	menu.refresh_progression()
	check(menu.progression_label.visible, "The menu shows the Second Oath progression line")
	check(menu.progression_label.text == localization.get_string("menu.ng_status", {"level": 2, "banner": localization.get_string("oath.banner.iron"), "titles": localization.get_string("oath.title.story")}), "The progression line names the oath level, banner and carried title")
	campaign.ng_level = 0
	menu.refresh_progression()
	check(not menu.progression_label.visible, "An ordinary campaign hides the Second Oath line")
	campaign.titles.clear()
	campaign.ng_banner = ""
	campaign.active = saved_active
	campaign.ng_level = saved_level
	menu.queue_free()
	await process_frame
	stats.restore_state({})
	@warning_ignore("return_value_discarded")
	stats.save_profile()
	print("STATS RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
