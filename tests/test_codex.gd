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
	var campaign: Node = root.get_node("CampaignSystem")
	var codex: Node = root.get_node("CodexSystem")
	var time: Node = root.get_node("TimeSystem")
	var event_bus: Node = root.get_node("EventBus")
	var localization: Node = root.get_node("LocalizationManager")
	var audio: Node = root.get_node("AudioManager")
	campaign.new_campaign(1, false)
	codex.unlocked.clear()
	codex.evaluate()
	check(codex.total() == 25, "The world codex ships twenty-five authored entries")
	check(codex.categories().size() == 4, "History, factions, places and bestiary structure the journal")
	check(codex.found() == 1 and codex.is_unlocked("history_founding"), "A new campaign opens only its starting entry")
	check(not codex.unlock("history_founding"), "An unlocked entry cannot be awarded twice")
	check(codex.entry("invented").is_empty() and not codex.unlock("invented"), "Unknown entries are rejected")
	var text_ok: bool = true
	for item: Dictionary in codex.entries():
		var title: String = localization.get_string(str(item.get("title", "")))
		var body: String = localization.get_string(str(item.get("body", "")))
		if title == str(item.get("title", "")) or body == str(item.get("body", "")) or body.length() < 40:
			print("FAIL: Codex entry lacks localized prose: ", item.get("id", ""))
			failures += 1
			text_ok = false
	check(text_ok, "Every codex entry has real Russian and English prose")
	time.current_day = 12
	campaign.visited.append("greenhaven")
	campaign.explored.append("woodland_freeholders_shrine")
	for id: Variant in campaign.camp_ids("woodland_freeholders"):
		campaign.fallen.append(str(id))
	campaign.assaults.append("iron_guild")
	campaign.conquests.append("iron_guild")
	campaign.announced_ending = "military"
	campaign.ng_level = 1
	codex.evaluate()
	check(codex.is_unlocked("history_long_winter"), "Reaching day twelve opens the long-winter history")
	check(codex.is_unlocked("history_second_oath"), "A second oath opens its history entry")
	check(codex.is_unlocked("place_greenhaven"), "Visiting a town opens its place entry")
	check(codex.is_unlocked("landmark_shrine"), "Surveying a landmark opens its place entry")
	check(codex.is_unlocked("faction_iron_guild"), "Binding a faction opens its profile")
	check(codex.is_unlocked("bestiary_raider"), "Clearing a raider camp opens its bestiary entry")
	check(codex.is_unlocked("bestiary_guard"), "Assaulting a town opens the garrison bestiary entry")
	check(codex.is_unlocked("history_finale") and codex.is_unlocked("bestiary_warlord"), "The announced military ending opens ending-specific lore")
	check(not codex.is_unlocked("bestiary_oathbreaker"), "A mixed-only entry stays locked on a military route")
	check(not codex.is_unlocked("place_high_pass") and not codex.is_unlocked("faction_borderland_watch"), "Unvisited places and unbound factions stay locked")
	var before: int = codex.found()
	codex.evaluate()
	codex.evaluate()
	check(codex.found() == before, "Repeated evaluation never duplicates unlocks")
	var panel: Control = load("res://scripts/ui/CodexUI.gd").new()
	root.add_child(panel)
	await process_frame
	check(panel.tabs.get_tab_count() == 4, "The codex panel exposes one tab per category")
	check(panel.progress_label.text == codex.progress_text(), "The codex panel shows the real found/total progress")
	var places_index: int = panel.category_ids.find("places")
	check(places_index >= 0, "The places category is present in the journal")
	var place_entries: Array = panel.entries_for(places_index)
	var high_pass_index: int = -1
	var greenhaven_index: int = -1
	for index: int in place_entries.size():
		if str(place_entries[index].get("id", "")) == "place_high_pass":
			high_pass_index = index
		elif str(place_entries[index].get("id", "")) == "place_greenhaven":
			greenhaven_index = index
	check(high_pass_index >= 0 and greenhaven_index >= 0, "Place entries keep their authored order and ids")
	var place_list: ItemList = panel.lists[places_index]
	check(place_list.item_count == place_entries.size(), "The journal lists every entry in the category")
	check(place_list.is_item_disabled(high_pass_index) and place_list.get_item_text(high_pass_index) == "???", "Locked entries show a locked row instead of spoilers")
	check(not place_list.is_item_disabled(greenhaven_index), "Unlocked entries are selectable")
	panel.show_entry(places_index, high_pass_index)
	check(panel.bodies[places_index].text.contains(localization.get_string("codex.locked_body")), "A locked entry explains how to unlock it")
	panel.show_entry(places_index, greenhaven_index)
	var greenhaven: Dictionary = codex.entry("place_greenhaven")
	check(panel.bodies[places_index].text.contains(codex.entry_title(greenhaven)) and panel.bodies[places_index].text.contains(codex.entry_body(greenhaven)), "An unlocked entry shows its localized title and prose")
	var closes: Array = [0]
	var close_button: Button = panel.find_child("CloseCodex", true, false) as Button
	check(close_button != null, "The codex has a focusable close control")
	panel.closed.connect(func() -> void: closes[0] += 1)
	close_button.pressed.emit()
	check(closes[0] == 1, "Closing the codex emits its owned signal")
	var escape_closes: Array = [0]
	panel.closed.connect(func() -> void: escape_closes[0] += 1)
	var escape: InputEventAction = InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	panel._unhandled_key_input(escape)
	check(escape_closes[0] == 1, "Escape closes the codex")
	panel.queue_free()
	await process_frame
	var world: Node3D = load("res://scenes/world/test_location.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	world.toggle_codex()
	check(paused and world.codex_ui.visible, "The HUD codex button opens the journal and pauses the world")
	world.toggle_codex()
	check(not paused and not world.codex_ui.visible, "Closing the journal resumes play")
	world.queue_free()
	await process_frame
	var toasts: Array = []
	var listener: Callable = func(text: Variant, warning: Variant) -> void: toasts.append([str(text), warning == true])
	event_bus.notification_posted.connect(listener)
	check(codex.unlock("bestiary_oathbreaker"), "A newly found entry unlocks through the public API")
	event_bus.notification_posted.disconnect(listener)
	var oathbreaker: Dictionary = codex.entry("bestiary_oathbreaker")
	var expected: String = localization.get_string("codex.unlocked", {"title": codex.entry_title(oathbreaker)})
	check(toasts.any(func(entry: Array) -> bool: return entry[0] == expected and not bool(entry[1])), "A codex unlock announces its localized title")
	var focused: bool = false
	var stream: Variant = audio._stream("ui_focus")
	for player: Variant in audio.effect_players + audio.spatial_players:
		if player.playing and player.stream == stream:
			focused = true
	check(focused, "A codex unlock uses the shared focus cue")
	var saved_count: int = codex.found()
	check(codex.save_progress(), "Codex progress writes to the protected profile")
	var saved_text: String = ""
	var file: FileAccess = FileAccess.open("user://codex_progress.json", FileAccess.READ)
	if file:
		saved_text = file.get_as_text()
		file = null
	check(not saved_text.is_empty() and saved_text.contains("auth"), "Codex progress is stored with an authenticated envelope")
	codex.unlocked.clear()
	check(codex.found() == 0, "The in-memory journal can be cleared for the reload check")
	codex.load_progress()
	check(codex.found() == saved_count and codex.is_unlocked("bestiary_oathbreaker"), "Saved codex progress reloads every collected entry")
	file = FileAccess.open("user://codex_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version": 1, "data": "{}", "auth": "00"}))
		file = null
	codex.unlocked.clear()
	codex.load_progress()
	check(codex.found() == 0, "Tampered codex progress is rejected instead of trusted")
	file = FileAccess.open("user://codex_progress.json", FileAccess.WRITE)
	if file:
		file.store_string(saved_text)
		file = null
	codex.load_progress()
	check(codex.found() == saved_count, "The authentic codex profile still loads after rejecting a forgery")
	campaign.new_campaign(1, false)
	print("CODEX RESULT: ", "PASS" if failures == 0 else "FAIL")
	finish_test(0 if failures == 0 else 1)
