extends SceneTree
const Guard=preload("res://scripts/security/SaveGuard.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
    await process_frame
    var boundary=root.get_node_or_null("BuildIntegrity")
    if boundary==null:
        check(false,"Missing startup integrity boundary");quit(1);return
    check(not boundary.read_only,"Authentic sources allow progress writes")
    check(boundary.failures.is_empty(),"All critical files verify at boot")
    var trusted:Dictionary=boundary.trusted_files()
    var path:String=trusted.keys()[0]
    var raw:=FileAccess.get_file_as_string(path)
    var manifest:=FileAccess.get_file_as_string(boundary.MANIFEST_PATH)
    check(boundary.verify_sources(manifest,{path:raw+" "}).has(path),"Modified data is rejected")
    check(not boundary.verify_sources(manifest+" ",{}).is_empty(),"Manifest byte changes are rejected")
    var decoded:Dictionary=JSON.parse_string(manifest)
    decoded.files[path]=(raw+" ").sha256_text()
    check(not boundary.verify_sources(JSON.stringify(decoded),{path:raw+" "}).is_empty(),"Replacement manifest cannot bless edited data")
    var live=boundary.read_json(path)
    boundary.read_only=true
    check(not Guard.can_write(),"Safe mode closes save boundary")
    var file:="user://must-not-exist-safe-mode.cfg"
    check(not Guard.atomic_text(file,"unsafe") and not FileAccess.file_exists(file),"No atomic save writes in safe mode")
    var cfg:=ConfigFile.new();cfg.set_value("fixture","value",1)
    check(not Guard.write_config(file,cfg,"safe-mode-test",func(_cfg):return true),"No signed config writes or backups in safe mode")
    check(JSON.stringify(boundary.read_json(path))==JSON.stringify(live),"Trusted data remains usable in safe mode")
    var detached=boundary.read_json(path)
    if detached is Dictionary:detached.clear()
    elif detached is Array:detached.clear()
    check(JSON.stringify(boundary.read_json(path))==JSON.stringify(live),"Callers cannot mutate compiled fallback")
    boundary.read_only=false
    print("BUILD INTEGRITY RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
