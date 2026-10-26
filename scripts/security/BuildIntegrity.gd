extends Node
## Verified data is immutable to callers. Safe mode never writes progress or settings.
const Trusted=preload("res://scripts/security/TrustedData.gd")
const MANIFEST_PATH:="res://data/critical-manifest.json"
const MAX_MANIFEST_BYTES:int=65536
const MAX_DATA_BYTES:int=8*1024*1024
const LOG_PATH:="user://integrity.log"
var read_only:=false
var failures:Array[String]=[]
var snapshot:Dictionary={}
var pending_notices:Array[String]=[]
var notice:AcceptDialog
var notice_layer:CanvasLayer
var seen_notices:Dictionary={}
var active_notice_key:=""
var notice_language:=""

func _enter_tree() -> void:
    process_mode=Node.PROCESS_MODE_ALWAYS
    snapshot=JSON.parse_string(Trusted.JSON_TEXT)
    failures=verify_sources(manifest_text(),{})
    read_only=not failures.is_empty()
    if read_only:
        record("integrity.files_changed",failures)
        pending_notices.append("integrity.files_changed")

func trusted_files() -> Dictionary:
    return snapshot.duplicate(true)

func verify_sources(manifest_text:String,overrides:Dictionary={}) -> Array[String]:
    var invalid:Array[String]=[]
    if manifest_text.sha256_text()!=Trusted.MANIFEST_SHA256:
        invalid.append(MANIFEST_PATH)
        return invalid
    var manifest:Dictionary=JSON.parse_string(manifest_text)
    for path in manifest.files:
        var digest:String=""
        if overrides.has(path):
            var bytes:PackedByteArray=str(overrides[path]).to_utf8_buffer()
            if bytes.size()<=MAX_DATA_BYTES:
                var hash:=HashingContext.new()
                hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
                digest=hash.finish().hex_encode()
        else:digest=critical_digest(path)
        if digest.is_empty() or digest!=manifest.files[path]:invalid.append(path)
    return invalid

func manifest_text(path:String=MANIFEST_PATH) -> String:
    var file:=FileAccess.open(path,FileAccess.READ)
    if file==null:return ""
    var length:int=file.get_length()
    if length>MAX_MANIFEST_BYTES:file.close();return ""
    var bytes:PackedByteArray=file.get_buffer(length)
    var complete:bool=bytes.size()==length and file.get_length()==length
    file.close()
    if not complete:return ""
    var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
    if hash.finish().hex_encode()!=Trusted.MANIFEST_SHA256:return ""
    # Only known-valid original bytes reach UTF8 decoding.
    return bytes.get_string_from_utf8()

func critical_digest(path:String) -> String:
    var file:=FileAccess.open(path,FileAccess.READ)
    if file==null:return ""
    var length:int=file.get_length()
    if length>MAX_DATA_BYTES:file.close();return ""
    var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256)
    while file.get_position()<length:
        var chunk:PackedByteArray=file.get_buffer(mini(65536,length-file.get_position()))
        if chunk.is_empty():file.close();return ""
        hash.update(chunk)
    var complete:bool=file.get_position()==length and file.get_length()==length
    file.close()
    return hash.finish().hex_encode() if complete else ""

func read_json(path:String) -> Variant:
    # Always use the compiled verified snapshot: no later check/use race on loose files.
    var value:Variant=snapshot.get(path)
    if value is Dictionary or value is Array:return value.duplicate(true)
    return value

func record(key:String,paths:Array) -> void:
    var file:=FileAccess.open(LOG_PATH,FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
    if file:
        if file.get_length()>1048576:file.close();file=FileAccess.open(LOG_PATH,FileAccess.WRITE)
        if file:
            file.seek_end()
            file.store_line("%s %s %s"%[Time.get_datetime_string_from_system(true),key,JSON.stringify(paths)])
            file.close()

func report_save(key:String,path:String) -> void:
    record(key,[path])
    if not seen_notices.has(key) and not pending_notices.has(key):pending_notices.append(key)

func refresh_notice(locale:Node) -> void:
    notice.title=locale.get_string("integrity.title")
    notice.dialog_text=locale.get_string(active_notice_key)
    notice.get_ok_button().text=locale.get_string("integrity.continue")
    notice_language=locale.current_language

func _process(_delta:float) -> void:
    if get_tree().current_scene==null:return
    var locale:=get_tree().root.get_node_or_null("LocalizationManager")
    if locale==null:return
    if is_instance_valid(notice) and notice.visible:
        if notice_language!=locale.current_language:refresh_notice(locale)
        return
    if pending_notices.is_empty():return
    var key:String=pending_notices.pop_front()
    seen_notices[key]=true
    if not is_instance_valid(notice):
        notice_layer=CanvasLayer.new();notice_layer.layer=120;add_child(notice_layer)
        notice=AcceptDialog.new();notice.theme=preload("res://scripts/ui/MarchTheme.gd").create()
        notice.min_size=Vector2i(440,180);notice_layer.add_child(notice)
        notice.exclusive=true
        notice.get_label().autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        notice.get_label().custom_minimum_size=Vector2(400,0)
        notice.add_theme_font_size_override("font_size",22)
    active_notice_key=key
    refresh_notice(locale)
    notice.popup_centered()
