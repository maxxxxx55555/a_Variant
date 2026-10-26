extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	if not ok:failures+=1;print("FAIL: ",label)
func run() -> void:
	await process_frame
	if DisplayServer.get_name()=="headless":
		print("ROAD LANDMARKS requires the real Compatibility renderer; dummy MultiMesh has no readable transform buffer")
		quit(2);return
	root.get_node("CampaignSystem").new_campaign(1,false)
	var terrain:Node3D=load("res://scripts/world/MarchTerrain.gd").new()
	root.add_child(terrain);terrain.generate()
	var stage:=Node3D.new();root.add_child(stage)
	load("res://scripts/world/MarchRoads.gd").build(stage,terrain)
	var batches:Array=stage.find_children("Roadside*","MultiMeshInstance3D",true,false)
	check(not batches.is_empty(),"Long routes contain batched physical landmarks")
	var positions:Array[Vector2]=[]
	for batch in batches:
		check(batch.find_children("*","CollisionObject3D",true,false).is_empty(),"Decorative landmarks never block movement")
		check(batch.visibility_range_end<=280 and batch.visibility_range_end>0,"Landmark batches have bounded draw distance")
		for i in batch.multimesh.instance_count:
			var at:Vector3=batch.transform*batch.multimesh.get_instance_transform(i).origin
			positions.append(Vector2(at.x,at.z))
	check(batches.size()<400,"Map-wide landmarks retain a bounded spatial batch budget")
	print("LANDMARK BATCHES ",batches.size()," POSITIONS ",positions.size())
	for link in load("res://scripts/world/MarchRoads.gd").route_links():
		var a:Vector2=link[0];var b:Vector2=link[1]
		var length:float=a.distance_to(b)
		if length<=120:continue
		var direction:Vector2=(b-a).normalized()
		var along:Array[float]=[0.0,length]
		for point in positions:
			var relative:Vector2=point-a
			var distance:float=relative.dot(direction)
			var across:float=absf(relative.cross(direction))
			if distance>0 and distance<length and across>=5 and across<=10:along.append(distance)
		along.sort()
		var max_gap:float=0.0
		for i in range(1,along.size()):max_gap=maxf(max_gap,along[i]-along[i-1])
		if max_gap>120:print("ROAD GAP ",a," -> ",b," length ",length," samples ",along.size()," gap ",max_gap)
		for i in range(1,along.size()):check(along[i]-along[i-1]<=120.01,"No empty road stretch exceeds twenty seconds of ordinary walking")
	print("ROAD LANDMARKS RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
