extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var save:Node=root.get_node("SaveSystem")
    var exact:float="80bc5779d9b9f43f".hex_decode().decode_double(0)
    var payload:Dictionary={"hp":75.0,"simulation":{"seconds":exact,"stockpiles":{"food":exact,"wood":80.0,"ore":40.0,"stone":50.0,"gold":200.0}}}
    check(save.save_game(payload),"Authenticated precise simulation saves")
    var loaded:Dictionary=save.load_game()
    check(JSON.stringify(loaded,"",true,true)==JSON.stringify(payload,"",true,true),"JSON simulation state hash survives native parser rounding exactly")
    var before:String=FileAccess.get_file_as_string(save.slot_path(0))
    check(save.save_game(loaded),"Unchanged precise simulation saves again")
    check(FileAccess.get_file_as_string(save.slot_path(0))==before,"Exact supplemental metadata preserves byte-stable unchanged saves")
    print("SAVE FLOAT PRECISION RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
