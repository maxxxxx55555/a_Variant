extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func run() -> void:
	await process_frame
	root.get_node("CampaignSystem").active=true
	var actor:Node3D=load("res://scripts/ai/CivilianActor.gd").new()
	root.add_child(actor);actor.set_physics_process(false)
	actor.scan_timer=100;actor.visible=true;actor.destination=Vector3(100,0,0)
	actor._physics_process(0.1)
	var animator:AnimationPlayer=actor.visual.get_meta("animation_player")
	check(animator.current_animation=="Walking_A","Ordinary resident uses the walk cycle")
	actor.fleeing=true;actor._physics_process(0.1)
	check(animator.current_animation=="Jogging_A","Fleeing resident uses a gait matched to its actual faster motion")
	actor.destination=actor.position;actor._physics_process(0.1)
	check(animator.current_animation=="Idle" and is_equal_approx(animator.speed_scale,1.0),"Stopping restores a normally paced idle")
	print("LOCOMOTION GAIT RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
