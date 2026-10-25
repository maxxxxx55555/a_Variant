class_name SaveGuard
extends RefCounted
## Local tamper evidence and corruption recovery, not an unbreakable DRM claim.
const MAX_BYTES := 8 * 1024 * 1024
const KEY_PATH := "user://save_integrity.key"
const FOOTER := "\n[save_guard]\n"
static var cached_key := PackedByteArray()
static var last_repair_failed := false

static func bounded_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file: return ""
	if file.get_length() > MAX_BYTES:
		file.close()
		return ""
	var text := file.get_as_text()
	file.close()
	return text

static func atomic_text(path: String, text: String) -> bool:
	if not path.begins_with("user://") or text.to_utf8_buffer().size() > MAX_BYTES: return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not file: return false
	file.store_string(text)
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK: return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func key() -> PackedByteArray:
	if cached_key.size() == 32: return cached_key
	if FileAccess.file_exists(KEY_PATH):
		var file := FileAccess.open(KEY_PATH, FileAccess.READ)
		if not file or file.get_length() != 32: return PackedByteArray()
		cached_key = file.get_buffer(32)
		file.close()
	else:
		var generated := Crypto.new().generate_random_bytes(32)
		var file := FileAccess.open(KEY_PATH + ".tmp", FileAccess.WRITE)
		if not file or generated.size() != 32: return PackedByteArray()
		file.store_buffer(generated)
		file.flush()
		file.close()
		if DirAccess.rename_absolute(KEY_PATH + ".tmp", KEY_PATH) != OK: return PackedByteArray()
		cached_key = generated
	return cached_key

static func signature(body: String, purpose: String) -> String:
	var secret := key()
	if secret.size() != 32: return ""
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, secret, ("GameSaveGuard/v1\n" + purpose + "\n" + body).to_utf8_buffer()).hex_encode()

static func authentic(body: String, purpose: String, received: Variant) -> bool:
	if not received is String or received.length() != 64 or not received.is_valid_hex_number(false): return false
	var expected := signature(body, purpose)
	return not expected.is_empty() and Crypto.new().constant_time_compare(expected.hex_decode(), received.hex_decode())

static func lock_path(purpose: String) -> String:
	return "user://guard_" + purpose.sha256_text().substr(0, 24) + ".lock"

static func locked(purpose: String) -> bool:
	return FileAccess.file_exists(lock_path(purpose))

static func lock(purpose: String) -> bool:
	return locked(purpose) or atomic_text(lock_path(purpose), "GameSaveGuard v1\n")

static func safe_text(text: String) -> bool:
	var quoted := false
	var escaped := false
	var depth := 0
	var word := ""
	for ch in text:
		if quoted:
			if escaped: escaped = false
			elif ch == "\\": escaped = true
			elif ch == "\"": quoted = false
			continue
		if ch == "\"": quoted = true
		if ch in ["{", "[", "("]: depth += 1
		if ch in ["}", "]", ")"]: depth -= 1
		if depth > 32 or depth < 0: return false
		if ch.to_lower() != ch.to_upper() or ch == "_":
			word += ch
		else:
			if word in ["Object", "Resource", "Callable", "Signal", "ExtResource", "SubResource"]: return false
			word = ""
	return not quoted and depth == 0

static func pure(value: Variant, depth: int = 0, counter: Array = [0]) -> bool:
	if depth == 0: counter = [0]
	counter[0] += 1
	if depth > 24 or counter[0] > 50000: return false
	if value == null or value is bool or value is int: return true
	if value is float: return is_finite(value) and absf(value) <= 1.0e20
	if value is String: return value.length() <= 16384
	if value is Array:
		if value.size() > 10000: return false
		for entry in value:
			if not pure(entry, depth + 1, counter): return false
		return true
	if value is Dictionary:
		if value.size() > 10000: return false
		for k in value:
			if not k is String or k.length() > 256 or not pure(value[k], depth + 1, counter): return false
		return true
	return false

static func numeric(value: Variant, low: float, high: float, integral: bool = false) -> bool:
	if not (value is int or value is float): return false
	return is_finite(float(value)) and value >= low and value <= high and (not integral or float(value) == floorf(float(value)))

static func config_candidate(path: String, purpose: String) -> ConfigFile:
	var text := bounded_text(path)
	if text.is_empty() or not safe_text(text): return null
	var split := text.rfind(FOOTER)
	var body := text
	if split >= 0:
		body = text.substr(0, split)
		var footer := ConfigFile.new()
		if footer.parse(text.substr(split)) != OK or footer.get_value("save_guard", "version", 0) != 1: return null
		if not authentic(body, purpose, footer.get_value("save_guard", "mac", "")): return null
	elif locked(purpose): return null
	var cfg := ConfigFile.new()
	if cfg.parse(body) != OK: return null
	for section in cfg.get_sections():
		for field in cfg.get_section_keys(section):
			if not pure(cfg.get_value(section, field), 0, [0]): return null
	return cfg

static func config_text(cfg: ConfigFile, purpose: String) -> String:
	var body := cfg.encode_to_text()
	var mac := signature(body, purpose)
	if mac.is_empty(): return ""
	return body + FOOTER + 'version=1\nmac="' + mac + '"\n'

static func write_config(path: String, cfg: ConfigFile, purpose: String, validate: Callable) -> bool:
	if not validate.call(cfg): return false
	var signed := config_text(cfg, purpose)
	if signed.is_empty(): return false
	var previous := config_candidate(path, purpose)
	if previous == null or not validate.call(previous): previous = config_candidate(path + ".bak", purpose)
	if previous != null and validate.call(previous):
		if not atomic_text(path + ".bak", config_text(previous, purpose)): return false
	elif FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".rejected") != OK: return false
	if not atomic_text(path, signed): return false
	return lock(purpose)

static func read_config(path: String, purpose: String, validate: Callable) -> ConfigFile:
	last_repair_failed = false
	var cfg := config_candidate(path, purpose)
	var recovered := false
	if cfg == null or not validate.call(cfg):
		cfg = config_candidate(path + ".bak", purpose)
		recovered = true
	if cfg == null or not validate.call(cfg): return null
	if recovered or not locked(purpose): last_repair_failed = not write_config(path, cfg, purpose, validate)
	return cfg
