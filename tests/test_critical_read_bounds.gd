extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
    await process_frame
    var boundary:Node=root.get_node("BuildIntegrity")
    if not boundary.has_method("critical_digest") or not boundary.has_method("manifest_text"):
        check(false,"Critical-data reads need an allocation bound before hashing");quit(1);return
    var large:="user://oversized-critical.json"
    var file:=FileAccess.open(large,FileAccess.WRITE)
    file.seek(8*1024*1024);file.store_8(32);file.close()
    check(boundary.critical_digest(large)=="","Over8MiB data rejected without allocating its contents")
    var manifest:="user://oversized-manifest.json"
    file=FileAccess.open(manifest,FileAccess.WRITE)
    file.seek(65536);file.store_8(32);file.close()
    check(boundary.manifest_text(manifest)=="","Over64KiB manifest rejected before decoding")
    file=FileAccess.open(manifest,FileAccess.WRITE);file.store_buffer(PackedByteArray([255,128,255]));file.close()
    check(boundary.manifest_text(manifest)=="","Invalid UTF8 manifest rejected before text decoding")
    check(not boundary.manifest_text().is_empty(),"The original exact manifest remains readable")
    file=FileAccess.open(large,FileAccess.WRITE);file.store_string("authentic-data");file.close()
    check(boundary.critical_digest(large)=="authentic-data".sha256_text(),"Bounded streaming preserves the exact SHA256")
    check(boundary.failures.is_empty() and not boundary.read_only,"Real shipping data remains accepted")
    print("CRITICAL READ BOUNDS: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
