extends SceneTree
## Tests finish their assertions first, then drop coroutine locals before mixer teardown.
var terminal_cleanup_pending:bool=false
func finish_test(code:int=0)->void:
    if terminal_cleanup_pending:return
    terminal_cleanup_pending=true
    _finish_test.call_deferred(code)
func _finish_test(code:int)->void:
    paused=true
    var audio:Node=root.get_node_or_null("AudioManager")
    if audio!=null:
        var released:bool=await audio.call("shutdown")
        if not released:
            push_error("Test terminal audio cleanup failed its bounded resource-release check")
            code=1
    quit(code)
