extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
    await process_frame
    var screen:=Control.new();root.add_child(screen);current_scene=screen
    var boundary:Node=root.get_node("BuildIntegrity")
    var locale:Node=root.get_node("LocalizationManager")
    boundary.pending_notices.append("integrity.files_changed")
    await process_frame
    await process_frame
    check(is_instance_valid(boundary.notice) and boundary.notice.visible,"Warning actually appears")
    check(boundary.notice.theme!=null,"Integrity warning uses the game's UI theme")
    for language in ["en","ru"]:
        locale.set_language(language)
        await process_frame
        check(boundary.notice.dialog_text==locale.get_string("integrity.files_changed"),"Visible warning follows language change")
    boundary.notice.hide()
    screen.queue_free()
    await process_frame
    print("INTEGRITY NOTICE RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
