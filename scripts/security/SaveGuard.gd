class_name SaveGuard
extends RefCounted
const IntegrityView=preload("res://scripts/security/BuildIntegrity.gd")
## Local tamper evidence and corruption recovery, not an unbreakable DRM claim.
const MAX_BYTES:int= 8 * 1024 * 1024
const KEY_PATH:String= "user://save_integrity.key"
const FOOTER:String= "\n[save_guard]\n"
static var cached_key:PackedByteArray= PackedByteArray()
static var last_repair_failed:bool= false
static var transaction_depth:int=0

static func bounded_text(path: String) -> String:
	var file:FileAccess= FileAccess.open(path, FileAccess.READ)
	if not file: return ""
	if file.get_length() > MAX_BYTES:
		file.close()
		return ""
	var text:String= file.get_as_text()
	file.close()
	return text

static func begin_transaction() -> bool:
	if transaction_depth!=0:return false
	transaction_depth=1
	return true

static func end_transaction() -> void:transaction_depth=0

static func can_write() -> bool:
	if transaction_depth!=0:return false
	var tree:SceneTree=Engine.get_main_loop() as SceneTree
	if tree==null:return false
	var integrity:IntegrityView=tree.root.get_node_or_null("BuildIntegrity")
	return integrity!=null and not integrity.read_only

static func atomic_text(path: String, text: String) -> bool:
	if not can_write(): return false
	if not path.begins_with("user://") or text.to_utf8_buffer().size() > MAX_BYTES: return false
	var file:FileAccess= FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if not file: return false
	if not file.store_string(text):file.close();return false
	file.flush()
	var status:Error= file.get_error()
	file.close()
	if status != OK: return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

static func key() -> PackedByteArray:
	if cached_key.size() == 32: return cached_key
	if FileAccess.file_exists(KEY_PATH):
		var file:FileAccess= FileAccess.open(KEY_PATH, FileAccess.READ)
		if not file or file.get_length() != 32: return PackedByteArray()
		cached_key = file.get_buffer(32)
		file.close()
	else:
		if not can_write(): return PackedByteArray()
		var generated:PackedByteArray= Crypto.new().generate_random_bytes(32)
		var file:FileAccess= FileAccess.open(KEY_PATH + ".tmp", FileAccess.WRITE)
		if not file or generated.size() != 32: return PackedByteArray()
		if not file.store_buffer(generated):file.close();return PackedByteArray()
		file.flush()
		var write_error:Error=file.get_error()
		file.close()
		if write_error!=OK:return PackedByteArray()
		if DirAccess.rename_absolute(KEY_PATH + ".tmp", KEY_PATH) != OK: return PackedByteArray()
		cached_key = generated
	return cached_key

static func signature(body: String, purpose: String) -> String:
	var secret:PackedByteArray= key()
	if secret.size() != 32: return ""
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, secret, ("GameSaveGuard/v1\n" + purpose + "\n" + body).to_utf8_buffer()).hex_encode()

static func authentic(body: String, purpose: String, received: Variant) -> bool:
	if not received is String:return false
	var supplied:String=received
	if supplied.length()!=64 or not supplied.is_valid_hex_number(false):return false
	var expected:String= signature(body, purpose)
	return not expected.is_empty() and Crypto.new().constant_time_compare(expected.hex_decode(), supplied.hex_decode())

static func lock_path(purpose: String) -> String:
	return "user://guard_" + purpose.sha256_text().substr(0, 24) + ".lock"

static func locked(purpose: String) -> bool:
	return FileAccess.file_exists(lock_path(purpose))

static func lock(purpose: String) -> bool:
	return locked(purpose) or atomic_text(lock_path(purpose), "GameSaveGuard v1\n")

static func safe_text(text: String) -> bool:
	var quoted:bool= false
	var escaped:bool= false
	var depth:int= 0
	var word:String= ""
	for ch:String in text:
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

static func pure(value: Variant, depth: int = 0, counter: Array[int] = [0]) -> bool:
	if depth == 0: counter = [0]
	counter[0] += 1
	if depth > 24 or counter[0] > 50000: return false
	if value == null or value is bool or value is int: return true
	if value is float:
		var number:float=value
		return is_finite(number) and absf(number)<=1.0e20
	if value is String:
		var text_value:String=value
		return text_value.length()<=16384
	if value is Array:
		var entries:Array=value
		if entries.size()>10000:return false
		for entry:Variant in entries:
			if not pure(entry, depth + 1, counter): return false
		return true
	if value is Dictionary:
		var fields:Dictionary=value
		if fields.size()>10000:return false
		for k:Variant in fields:
			if not k is String:return false
			var field_name:String=k
			if field_name.length()>256 or not pure(fields[k],depth+1,counter):return false
		return true
	return false

static func numeric(value: Variant, low: float, high: float, integral: bool = false) -> bool:
	if not (value is int or value is float): return false
	var number:float=value
	return is_finite(number) and number>=low and number<=high and (not integral or number==floorf(number))

static func config_candidate(path: String, purpose: String) -> ConfigFile:
	var text:String= bounded_text(path)
	if text.is_empty() or not safe_text(text): return null
	var split:int= text.rfind(FOOTER)
	var body:String= text
	if split >= 0:
		body = text.substr(0, split)
		var footer:ConfigFile= ConfigFile.new()
		if footer.parse(text.substr(split)) != OK or footer.get_value("save_guard", "version", 0) != 1: return null
		if not authentic(body, purpose, footer.get_value("save_guard", "mac", "")): return null
	elif locked(purpose): return null
	var cfg:ConfigFile= ConfigFile.new()
	if cfg.parse(body) != OK: return null
	for section:String in cfg.get_sections():
		for field:String in cfg.get_section_keys(section):
			if not pure(cfg.get_value(section, field), 0, [0]): return null
	return cfg

static func config_text(cfg: ConfigFile, purpose: String) -> String:
	var body:String= cfg.encode_to_text()
	var mac:String= signature(body, purpose)
	if mac.is_empty(): return ""
	return body + FOOTER + 'version=1\nmac="' + mac + '"\n'

static func write_config(path: String, cfg: ConfigFile, purpose: String, validate: Callable) -> bool:
	if not can_write(): return false
	if not validate.call(cfg): return false
	var signed:String= config_text(cfg, purpose)
	if signed.is_empty(): return false
	var previous:ConfigFile= config_candidate(path, purpose)
	if previous == null or not validate.call(previous): previous = config_candidate(path + ".bak", purpose)
	if previous != null and validate.call(previous):
		if not atomic_text(path + ".bak", config_text(previous, purpose)): return false
	elif FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".rejected") != OK: return false
	if not atomic_text(path, signed): return false
	return lock(purpose)

static func report_recovery(key_name:String,path:String) -> void:
	var tree:SceneTree=Engine.get_main_loop() as SceneTree
	if tree==null:return
	var integrity:IntegrityView=tree.root.get_node_or_null("BuildIntegrity")
	if integrity!=null:integrity.report_save(key_name,path)
