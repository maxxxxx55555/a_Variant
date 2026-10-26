extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var exact:GDScript=load("res://scripts/security/ExactFloats.gd")
    var value:float="80bc5779d9b9f43f".hex_decode().decode_double(0)
    var source:Dictionary={"number":value,"nested":{"items":[value,"copy",7.0]}}
    var captured:Dictionary=exact.capture(source)
    var parsed:Dictionary=JSON.parse_string(JSON.stringify(source,"",true,true))
    check(exact.restore(parsed,captured.patches) and JSON.stringify(parsed,"",true,true)==JSON.stringify(source,"",true,true),"Exact finite leaves round trip through native text parsing")
    var malformed:Array=[null,{},[{"route":[],"bits":"80bc5779d9b9f43f"}],[{"route":["missing"],"bits":"80bc5779d9b9f43f"}],[{"route":["number"],"bits":"xx".repeat(8)}],[{"route":["number"],"bits":"000000000000f87f"}],[{"route":["nested","items",-1],"bits":"80bc5779d9b9f43f"}],[{"route":["nested","items",1],"bits":"80bc5779d9b9f43f"}],[{"route":["number"],"bits":"0000000000002440"}],captured.patches+captured.patches]
    for invalid:Variant in malformed:
        var target:Dictionary=source.duplicate(true)
        var before:String=JSON.stringify(target,"",true,true)
        check(not exact.restore(target,invalid),"Malformed numeric supplement is rejected")
        check(JSON.stringify(target,"",true,true)==before,"Rejected supplement leaves caller state intact")
    var hostile:Array=[]
    for index:int in 10001:hostile.append({})
    check(not exact.restore(source.duplicate(true),hostile),"Supplement count is bounded before traversal")
    print("EXACT FLOAT LIMITS RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
