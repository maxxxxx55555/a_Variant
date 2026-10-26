extends SceneTree
const Guard=preload("res://scripts/security/SaveGuard.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func put(path:String,text:String) -> void:
    var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(text);f.close()
func run() -> void:
    await process_frame
    var save:Node=root.get_node("SaveSystem")
    var boundary:Node=root.get_node("BuildIntegrity")
    var state:Dictionary={"hp":75,"inventory":[],"equipment":{}}
    check(save._store(save.SAVE_PATH,state),"Save legitimate state")
    var before:=Guard.bounded_text(save.SAVE_PATH)
    var loaded:Dictionary=save.load_slot(0)
    check(save._store(save.SAVE_PATH,loaded),"Save loaded state again")
    check(before==Guard.bounded_text(save.SAVE_PATH),"Save-load-save hash remains byte stable")
    state.hp=70
    check(save._store(save.SAVE_PATH,state),"Next state preserves known-good backup")
    put(save.SAVE_PATH,Guard.bounded_text(save.SAVE_PATH).replace("auth", "bad_auth"))
    check(save.load_slot(0).get("hp")==75,"Tamper falls back to known-good save")
    check("integrity.save_recovered" in boundary.pending_notices,"Backup recovery has localized feedback")
    check("integrity.save_recovered" in Guard.bounded_text(boundary.LOG_PATH),"Backup recovery logged without signature material")
    before=Guard.bounded_text(save.SAVE_PATH)
    var backup:=Guard.bounded_text(save.BACKUP_PATH)
    boundary.read_only=true
    check(save.load_slot(0).get("hp")==75,"Safe mode can read authentic progress")
    check(not save._store(save.SAVE_PATH,{"hp":50}),"Safe mode rejects progress writes")
    check(before==Guard.bounded_text(save.SAVE_PATH) and backup==Guard.bounded_text(save.BACKUP_PATH),"Safe mode does not mutate primary or backup")
    boundary.read_only=false
    print("SAVE RECOVERY RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
