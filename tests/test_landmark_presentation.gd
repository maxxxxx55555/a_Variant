extends "res://tests/AudioCleanTree.gd"
const Landmark=preload("res://scripts/world/LandmarkArt.gd")
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    var site:Node3D=Node3D.new();root.add_child(site)
    var art:Node3D=Landmark.build(site,Vector3(10,0,20))
    check(art!=null,"Landmark creates owned visual node")
    var bodies:Array[Node]=site.find_children("*","StaticBody3D",true,false)
    check(bodies.size()==3,"Original two pillar and lintel collision bodies are retained")
    var expected:Array[Vector3]=[Vector3(0.8,4,0.9),Vector3(0.8,4,0.9),Vector3(5,0.7,1)]
    for i:int in mini(bodies.size(),expected.size()):
        var shape:CollisionShape3D=bodies[i].get_child(0) as CollisionShape3D
        check(shape!=null and shape.shape is BoxShape3D and (shape.shape as BoxShape3D).size==expected[i],"Original collision geometry preserved")
    if art!=null:
        var meshes:Array[Node]=art.find_children("*","MeshInstance3D",true,false)
        check(meshes.size()>=1 and meshes.size()<=4,"Decorative stone is batched into few rendered meshes")
        check(art.find_children("*","StaticBody3D",true,false).is_empty(),"Decorative parts add no collision")
    var pedestal:Node3D=Landmark.make_marker(site)
    check(pedestal!=null and not pedestal.find_children("*","MeshInstance3D",true,false).is_empty(),"Interactive pedestal has crafted visual geometry")
    check(pedestal.find_children("*","StaticBody3D",true,false).is_empty(),"Pedestal adds no blocking collision")
    site.queue_free();await process_frame
    print("LANDMARK PRESENTATION: ","PASS" if failures==0 else "FAIL")
    finish_test(0 if failures==0 else 1)
