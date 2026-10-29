extends Node

signal changed()

const Guard = preload("res://scripts/security/SaveGuard.gd")
const PROFILE_PATH: String = "user://profile_stats.json"
const PROFILE_PURPOSE: String = "march/profile_stats.json"
const DIFFICULTY_IDS: Array[String] = ["story", "normal", "hard", "expert"]

var data: Dictionary = {}

func _ready() -> void:
	data = _defaults()
	load_profile()

func _defaults() -> Dictionary:
	var rows: Array = []
	for _index:int in DIFFICULTY_IDS.size():
		rows.append({"runs": 0, "wins": 0, "losses": 0, "best_day": 0, "best_wealth": 0.0})
	return {"runs": 0, "wins": 0, "losses": 0, "regions": 0, "max_wealth": 0.0, "seconds": 0.0, "last_result": "", "by_difficulty": rows}

func by_difficulty() -> Array:
	var rows: Variant = data.get("by_difficulty", [])
	if rows is Array:
		@warning_ignore("unsafe_cast")
		return rows as Array
	return []

func row(difficulty: int) -> Dictionary:
	var rows: Array = by_difficulty()
	var index: int = clampi(difficulty, 0, DIFFICULTY_IDS.size() - 1)
	if index < rows.size():
		return rows[index]
	return {"runs": 0, "wins": 0, "losses": 0, "best_day": 0, "best_wealth": 0.0}

func begin_run(difficulty: int) -> void:
	data.runs = _whole(data.get("runs", 0), 0, 10000000) + 1
	var rows: Array = by_difficulty()
	var index: int = clampi(difficulty, 0, DIFFICULTY_IDS.size() - 1)
	if index < rows.size():
		var entry: Dictionary = rows[index]
		entry.runs = _whole(entry.get("runs", 0), 0, 10000000) + 1
	# Persistence failure is reported by the profile writer; run tracking stays available.
	@warning_ignore("return_value_discarded")
	save_profile()
	changed.emit()

func finish_victory(difficulty: int, day: int, wealth: float, regions: int, seconds: float) -> void:
	_finish(difficulty, day, wealth, regions, seconds, true)
	data.last_result = "win"
	# Persistence failure is reported by the profile writer; run tracking stays available.
	@warning_ignore("return_value_discarded")
	save_profile()
	changed.emit()

func finish_defeat(difficulty: int, day: int, wealth: float, regions: int, seconds: float) -> void:
	_finish(difficulty, day, wealth, regions, seconds, false)
	data.last_result = "loss"
	# Persistence failure is reported by the profile writer; run tracking stays available.
	@warning_ignore("return_value_discarded")
	save_profile()
	changed.emit()

func _finish(difficulty: int, day: int, wealth: float, regions: int, seconds: float, victory: bool) -> void:
	data.wins = _whole(data.get("wins", 0), 0, 10000000) + (1 if victory else 0)
	data.losses = _whole(data.get("losses", 0), 0, 10000000) + (0 if victory else 1)
	data.regions = maxi(_whole(data.get("regions", 0), 0, 100), clampi(regions, 0, 100))
	data.max_wealth = maxf(_decimal(data.get("max_wealth", 0.0), 0.0, 1.0e12), clampf(wealth, 0.0, 1.0e12))
	data.seconds = clampf(_decimal(data.get("seconds", 0.0), 0.0, 1.0e9) + maxf(0.0, seconds), 0.0, 1.0e9)
	var rows: Array = by_difficulty()
	var index: int = clampi(difficulty, 0, DIFFICULTY_IDS.size() - 1)
	if index < rows.size():
		var entry: Dictionary = rows[index]
		entry.wins = _whole(entry.get("wins", 0), 0, 10000000) + (1 if victory else 0)
		entry.losses = _whole(entry.get("losses", 0), 0, 10000000) + (0 if victory else 1)
		var best_day: int = _whole(entry.get("best_day", 0), 0, 1000000)
		if victory and (best_day <= 0 or day < best_day):
			entry.best_day = clampi(day, 1, 1000000)
		entry.best_wealth = maxf(_decimal(entry.get("best_wealth", 0.0), 0.0, 1.0e12), clampf(wealth, 0.0, 1.0e12))

func capture_state() -> Dictionary:
	return data.duplicate(true)

func restore_state(saved: Dictionary) -> void:
	data = _sanitized(saved)
	changed.emit()

func capture_profile() -> Dictionary:
	return {"stats": capture_state(), "codex": CodexSystem.capture_state()}

func restore_profile(saved: Dictionary) -> void:
	var stats: Variant = saved.get("stats", {})
	if stats is Dictionary:
		@warning_ignore("unsafe_cast")
		var record: Dictionary = stats
		restore_state(record)
	var codex: Variant = saved.get("codex", {})
	if codex is Dictionary:
		@warning_ignore("unsafe_cast")
		var record: Dictionary = codex
		CodexSystem.restore_state(record)

func _sanitized(saved: Dictionary) -> Dictionary:
	var clean: Dictionary = _defaults()
	clean.runs = _whole(saved.get("runs"), 0, 10000000)
	clean.wins = _whole(saved.get("wins"), 0, 10000000)
	clean.losses = _whole(saved.get("losses"), 0, 10000000)
	clean.regions = _whole(saved.get("regions"), 0, 100)
	clean.max_wealth = _decimal(saved.get("max_wealth"), 0.0, 1.0e12)
	clean.seconds = _decimal(saved.get("seconds"), 0.0, 1.0e9)
	var result: Variant = saved.get("last_result", "")
	clean.last_result = str(result) if result is String and str(result) in ["", "win", "loss"] else ""
	var saved_rows: Variant = saved.get("by_difficulty", [])
	var clean_rows: Array = clean.by_difficulty
	if saved_rows is Array:
		var rows: Array = saved_rows
		for index:int in mini(rows.size(), clean_rows.size()):
			var source: Variant = rows[index]
			if not source is Dictionary:
				continue
			@warning_ignore("unsafe_cast")
			var record: Dictionary = source
			var row_data: Dictionary = clean_rows[index]
			row_data.runs = _whole(record.get("runs"), 0, 10000000)
			row_data.wins = _whole(record.get("wins"), 0, 10000000)
			row_data.losses = _whole(record.get("losses"), 0, 10000000)
			row_data.best_day = _whole(record.get("best_day"), 0, 1000000)
			row_data.best_wealth = _decimal(record.get("best_wealth"), 0.0, 1.0e12)
	return clean

func _whole(value: Variant, low: int, high: int) -> int:
	if not (value is int or value is float):
		return low
	# The numeric type guard above is the deserialization boundary.
	@warning_ignore("unsafe_call_argument")
	return clampi(int(value), low, high)

func _decimal(value: Variant, low: float, high: float) -> float:
	if not (value is int or value is float):
		return low
	# The numeric type guard above is the deserialization boundary.
	@warning_ignore("unsafe_call_argument")
	var number: float = float(value)
	return clampf(number, low, high) if is_finite(number) else low

func save_profile() -> bool:
	if not Guard.can_write():
		return false
	var body: String = JSON.stringify(_sanitized(data), "", true, true)
	var auth: String = Guard.signature(body, PROFILE_PURPOSE)
	if auth.is_empty():
		return false
	return Guard.atomic_text(PROFILE_PATH, JSON.stringify({"version": 1, "data": body, "auth": auth}, "", true, true))

func load_profile() -> void:
	var text: String = Guard.bounded_text(PROFILE_PATH)
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
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
		@warning_ignore("unsafe_cast")
		var record: Dictionary = payload
		data = _sanitized(record)

func summary() -> String:
	return LocalizationManager.get_string("menu.stats_summary", {"runs": _whole(data.get("runs", 0), 0, 10000000), "wins": _whole(data.get("wins", 0), 0, 10000000)})
