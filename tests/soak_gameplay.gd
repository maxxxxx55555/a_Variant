extends SceneTree
var started:int=0
var cycles:int=0
var checkpoints:int=0
var failures:int=0
var aborts:int=0
var object_samples:Array[Dictionary]=[]
func _initialize()->void:call_deferred("run")
func write_record(record:Dictionary)->void:
	var path:String=OS.get_environment("GAME_SOAK_RESULT_PATH")
	var result_file:FileAccess=FileAccess.open(path,FileAccess.WRITE) if not path.is_empty() else null
	if not result_file or not result_file.store_string(JSON.stringify(record)):
		push_error("Unable to write measured soak result")
		quit(74)
		return
	print("SOAK RESULT: ",JSON.stringify(record))
	quit(0 if record["result"]=="PASS" else 1)
func run()->void:
	await process_frame
	started=Time.get_ticks_msec()
	var duration:int=OS.get_environment("GAME_SOAK_SECONDS").to_int()
	if duration<1:duration=1800
	while Time.get_ticks_msec()-started<duration*1000:
		OS.set_environment("GAME_QA_SEED",str(7001+cycles))
		var route:Node=load("res://tests/SoakRoute.gd").new()
		var completed:Array=[false]
		route.cycle_finished.connect(func(code:int)->void:
			if code!=0:failures+=1
			completed[0]=true)
		root.add_child(route)
		# A death or a stuck route must fail the soak with a written record instead of
		# leaving the driver waiting on a signal that can never arrive.
		var deadline:int=Time.get_ticks_msec()+1500000
		var startup_deadline:int=Time.get_ticks_msec()+120000
		var saw_world:bool=false
		while not completed[0]:
			await process_frame
			if not is_instance_valid(route):
				aborts+=1
				print("SOAK CYCLE ABORTED: the route node itself was released")
				break
			if not saw_world:
				if is_instance_valid(route.world): saw_world=true
				elif Time.get_ticks_msec()>startup_deadline:
					aborts+=1
					print("SOAK CYCLE TIMEOUT: the route never created its world")
					break
				else: continue
			if not is_instance_valid(route.world):
				aborts+=1
				print("SOAK CYCLE ABORTED: the route lost its world before finishing")
				break
			if Time.get_ticks_msec()>deadline:
				aborts+=1
				print("SOAK CYCLE TIMEOUT: a campaign loop exceeded twenty-five minutes")
				break
		if is_instance_valid(route): checkpoints+=route.checkpoints
		if is_instance_valid(route): route.queue_free()
		cycles+=1
		for cleanup_frame:int in 10:await process_frame
		object_samples.append({"cycle":cycles,"elapsed_ms":Time.get_ticks_msec()-started,"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))})
		print("SOAK PROGRESS: cycles=",cycles," checkpoints=",checkpoints," elapsed_ms=",Time.get_ticks_msec()-started," aborts=",aborts)
		if failures>0 or aborts>0:break
	var record:Dictionary={"result":"PASS" if failures==0 and aborts==0 else "FAIL","elapsed_ms":Time.get_ticks_msec()-started,"cycles":cycles,"checkpoints":checkpoints,"failures":failures,"aborts":aborts,"object_samples":object_samples}
	write_record(record)
