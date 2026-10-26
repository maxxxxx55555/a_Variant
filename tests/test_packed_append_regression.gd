extends SceneTree
var failures:int=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
    if not ok:failures+=1;print("FAIL: ",label)
func run()->void:
    await process_frame
    root.get_node("CampaignSystem").new_campaign(1,false)
    var terrain:Node3D=load("res://scripts/world/MarchTerrain.gd").new();root.add_child(terrain);terrain.generate()
    check(terrain.surface_heights.size()==129*129 and terrain.get_child_count()>0,"Successful packed appends preserve the entire terrain surface")
    if terrain.surface_heights.size()==129*129:
        load("res://scripts/world/MarchRoads.gd").build(terrain,terrain)
        var road:MeshInstance3D=terrain.get_node_or_null("MarchRoadNetwork") as MeshInstance3D
        check(road!=null and road.mesh.get_surface_count()>0,"Successful packed appends produce the connected road mesh")
    var panels:Node=load("res://scripts/ui/CampaignPanels.gd").new()
    check(not panels.costs({"wood":20,"gold":15}).is_empty(),"Successful packed string appends retain displayed workshop prices")
    panels.free();terrain.queue_free();await process_frame
    print("PACKED APPEND REGRESSION RESULT: ","PASS" if failures==0 else "FAIL")
    quit(0 if failures==0 else 1)
