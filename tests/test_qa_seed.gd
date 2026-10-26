extends SceneTree
var Driver:Variant
var failures:int=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 await process_frame
 Driver=load("res://scripts/verification/CampaignRoute.gd")
 check(Driver.get_script_method_list().any(func(method:Dictionary)->bool:return method.name=="parse_seed"),"Private driver accepts an explicit validated seed")
 if Driver.get_script_method_list().any(func(method:Dictionary)->bool:return method.name=="parse_seed"):
  check(Driver.parse_seed("")==7401,"Empty seed preserves historical route")
  check(Driver.parse_seed("101")==101,"Seed101 is retained")
  check(Driver.parse_seed("102")==102,"Different seed is retained")
  for invalid in ["abc","0","-1","1.5","9223372036854775808"]:
   check(Driver.parse_seed(invalid)==-1,"Invalid QA seed rejected: "+invalid)
 print("QA SEED RESULT: ","PASS" if failures==0 else "FAIL")
 quit(0 if failures==0 else 1)
