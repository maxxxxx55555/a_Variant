extends Node

signal changed()
signal entry_unlocked(entry: Dictionary)

const Guard = preload("res://scripts/security/SaveGuard.gd")
const PROFILE_PATH: String = "user://codex_progress.json"
const PROFILE_PURPOSE: String = "march/codex_progress.json"

var definition: Dictionary = {}
var unlocked: Array[String] = []

func _ready() -> void:
	var source: Variant = BuildIntegrity.read_json("res://data/balance/codex.json")
	if source is Dictionary:
		# The runtime type guard above is the deserialization boundary.
		@warning_ignore("unsafe_cast")
		definition = (source as Dictionary).duplicate(true)
	load_progress()

func entries() -> Array:
	var value: Variant = definition.get("entries", [])
	if value is Array:
		@warning_ignore("unsafe_cast")
		return (value as Array).duplicate()
	return []

func categories() -> Array:
	var value: Variant = definition.get("categories", [])
	if value is Array:
		@warning_ignore("unsafe_cast")
		return (value as Array).duplicate()
	return []

func entry(id: String) -> Dictionary:
	for item:Dictionary in entries():
		if str(item.get("id", "")) == id:
			return item
	return {}

func is_unlocked(id: String) -> bool:
	return id in unlocked

func total() -> int:
	return entries().size()

func found() -> int:
	return unlocked.size()

func total_in(category_id: String) -> int:
	var count: int = 0
	for item:Dictionary in entries():
		if str(item.get("category", "")) == category_id:
			count += 1
	return count

func count_in(category_id: String) -> int:
	var count: int = 0
	for item:Dictionary in entries():
		if str(item.get("category", "")) == category_id and is_unlocked(str(item.get("id", ""))):
			count += 1
	return count

func category_title(category_id: String) -> String:
	for category:Dictionary in categories():
		if str(category.get("id", "")) == category_id:
			return LocalizationManager.get_string(str(category.get("title", "")))
	return category_id

func entry_title(item: Dictionary) -> String:
	return LocalizationManager.get_string(str(item.get("title", "")))

func entry_body(item: Dictionary) -> String:
	return LocalizationManager.get_string(str(item.get("body", "")))

func progress_text(category_id: String = "") -> String:
	var found_count: int = found() if category_id.is_empty() else count_in(category_id)
	var total_count: int = total() if category_id.is_empty() else total_in(category_id)
	return LocalizationManager.get_string("codex.progress", {"found": found_count, "total": total_count})

func unlock(id: String, announce: bool = true) -> bool:
	if id.is_empty() or is_unlocked(id):
		return false
	var item: Dictionary = entry(id)
	if item.is_empty():
		return false
	unlocked.append(id)
	changed.emit()
	entry_unlocked.emit(item)
	if announce:
		var title: String = entry_title(item)
		EventBus.notification_posted.emit(LocalizationManager.get_string("codex.unlocked", {"title": title}), false)
		if AudioManager:
			AudioManager.play_sound("ui_focus")
	# Persistence failure is reported by the codex writer; the unlock stays in memory.
	@warning_ignore("return_value_discarded")
	save_progress()
	return true

func _integer(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		# The numeric type guard above is the deserialization boundary.
		@warning_ignore("unsafe_call_argument")
		return int(value)
	return fallback

func evaluate() -> void:
	if not CampaignSystem.active:
		return
	var route: String = CampaignSystem.ending()
	if route.is_empty():
		route = CampaignSystem.announced_ending
	for item:Dictionary in entries():
		var id: String = str(item.get("id", ""))
		if is_unlocked(id):
			continue
		var rule:Dictionary = item.get("unlock", {})
		var kind: String = str(rule.get("kind", ""))
		var rule_id: String = str(rule.get("id", ""))
		var earned: bool = false
		match kind:
			"start":
				earned = true
			"ng":
				earned = CampaignSystem.ng_level > 0
			"day":
				earned = TimeSystem.current_day >= _integer(rule.get("day", 1), 1)
			"town":
				earned = rule_id in CampaignSystem.visited
			"point":
				earned = rule_id in CampaignSystem.explored
			"camp_any":
				for faction:Dictionary in CampaignSystem.definition.factions:
					if CampaignSystem.camp_cleared(str(faction.get("id", ""))):
						earned = true
						break
			"assault_any":
				earned = not CampaignSystem.assaults.is_empty()
			"bound":
				earned = CampaignSystem.bound(rule_id)
			"ending":
				earned = not route.is_empty() and (rule_id == "any" or rule_id == route)
		if earned:
			# unlock() reports duplicates as false; evaluate() already filtered those out.
			@warning_ignore("return_value_discarded")
			unlock(id)

func capture_state() -> Dictionary:
	return {"unlocked": unlocked.duplicate()}

func restore_state(data: Dictionary) -> void:
	var saved: Variant = data.get("unlocked", [])
	if not saved is Array:
		return
	for id:Variant in saved:
		if not id is String:
			continue
		var text: String = str(id)
		if text.is_empty() or is_unlocked(text) or entry(text).is_empty():
			continue
		unlocked.append(text)
	changed.emit()

func save_progress() -> bool:
	if not Guard.can_write():
		return false
	var payload: Dictionary = {"version": 1, "unlocked": unlocked.duplicate()}
	var body: String = JSON.stringify(payload, "", true, true)
	var auth: String = Guard.signature(body, PROFILE_PURPOSE)
	if auth.is_empty():
		return false
	return Guard.atomic_text(PROFILE_PATH, JSON.stringify({"version": 1, "data": body, "auth": auth}, "", true, true))

func load_progress() -> void:
	var text: String = Guard.bounded_text(PROFILE_PATH)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	# The runtime type guard above is the deserialization boundary.
	@warning_ignore("unsafe_cast")
	var envelope: Dictionary = parsed
	var body: Variant = envelope.get("data")
	if not body is String:
		return
	var body_text: String = str(body)
	if not Guard.authentic(body_text, PROFILE_PURPOSE, envelope.get("auth")):
		return
	var payload: Variant = JSON.parse_string(body_text)
	if payload is Dictionary:
		# The runtime type guard above is the deserialization boundary.
		@warning_ignore("unsafe_cast")
		var record: Dictionary = payload
		restore_state(record)
