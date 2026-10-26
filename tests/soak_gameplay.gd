extends SceneTree
var started:int=0
var cycles:int=0
var checkpoints:int=0
var failures:int=0
var object_samples:Array[Dictionary]=[]
func _initialize()->void:call_deferred("run")
func run()->void:
	await process_frame
	started=Time.get_ticks_msec()
	var duration:int=OS.get_environment("GAME_SOAK_SECONDS").to_int()
	if duration<1:duration=1800
	while Time.get_ticks_msec()-started<duration*1000:
		OS.set_environment("GAME_QA_SEED",str(7001+cycles))
		var route:Node=load("res://tests/SoakRoute.gd").new()
		route.cycle_finished.connect(func(code:int)->void:failures+=1 if code!=0 else 0)
		root.add_child(route)
		await route.cycle_finished
		checkpoints+=route.checkpoints
		route.queue_free()
		cycles+=1
		for cleanup_frame:int in 10:await process_frame
		object_samples.append({"cycle":cycles,"elapsed_ms":Time.get_ticks_msec()-started,"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))})
		print("SOAK PROGRESS: cycles=",cycles," checkpoints=",checkpoints," elapsed_ms=",Time.get_ticks_msec()-started)
		if failures>0:break
	var record:Dictionary={"result":"PASS" if failures==0 else "FAIL","elapsed_ms":Time.get_ticks_msec()-started,"cycles":cycles,"checkpoints":checkpoints,"failures":failures,"object_samples":object_samples}
	var result_file:FileAccess=FileAccess.open(OS.get_environment("GAME_SOAK_RESULT_PATH"),FileAccess.WRITE)
	if not result_file or not result_file.store_string(JSON.stringify(record)):
		push_error("Unable to write measured soak result")
		quit(74)
		return
	print("SOAK RESULT: ",JSON.stringify(record))
	quit(0 if failures==0 else 1)
