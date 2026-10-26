extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
    if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
    await process_frame
    var router:Script=load("res://scripts/security/QARouter.gd")
    check(not OS.has_feature("qa_verifier"),"This source process has no exported private feature")
    check(OS.get_environment("GAME_QA")=="1","The negative fixture deliberately supplies QA env")
    check(not router.authorized(),"Environment alone cannot enable the verifier")
    var host:=Node.new()
    root.add_child(host)
    var before:int=root.get_child_count()
    check(not router.request(host),"An ordinary launch never creates a QA route")
    await process_frame
    check(before==root.get_child_count() and host.get_child_count()==0,"Ordinary startup allocates no verifier")
    host.queue_free()
    print("QA ROUTER RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
