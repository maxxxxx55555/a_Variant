extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func posed(skeleton:Skeleton3D,bone:String) -> bool:
	var id:=skeleton.find_bone(bone)
	return id>=0 and skeleton.get_bone_pose_rotation(id).angle_to(skeleton.get_bone_rest(id).basis.get_rotation_quaternion())>0.15
func run() -> void:
	await process_frame
	var observer:=Node3D.new();observer.add_to_group("player");root.add_child(observer)
	for armed in [false,true]:
		var stage:=Node3D.new();root.add_child(stage);stage.position=Vector3(500,0,500)
		var figure:=MarchArt.humanoid(stage,Color("a6976b"),armed,armed)
		var skeleton:Skeleton3D=figure.find_child("Skeleton3D",true,false)
		check(posed(skeleton,"upperarm_l") and posed(skeleton,"upperarm_r"),"New character has its actual idle pose before the first frame; armed="+str(armed))
		figure._process(0.0)
		check(not figure.animator.active,"Distant animation culling is exercised")
		check(posed(skeleton,"upperarm_l") and posed(skeleton,"upperarm_r"),"Culling cannot freeze an uninitialized T-pose")
	print("INITIAL IDLE POSE RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
