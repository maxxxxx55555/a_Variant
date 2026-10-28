extends RefCounted
## A stone landmark with the same interaction and collision footprint as the original.
const Art=preload("res://scripts/world/RealWorldArt.gd")

static func stone(parent:Node3D,at:Vector3,dimensions:Vector3,material:String="stone")->void:
	# The landmark owns this decorative part until it is combined into batches.
	@warning_ignore("return_value_discarded")
	Art.box(parent,at,dimensions,material)

static func build(parent:Node3D,origin:Vector3)->Node3D:
	# Retain exactly the three original solid shapes; only their visible meshes change.
	for side:int in [-1,1]:
		var collider_mesh:Node3D=MarchArt.box(parent,origin+Vector3(side*2,2,0),Vector3(0.8,4,0.9),Color("898b7c"),true)
		collider_mesh.visible=false
	var lintel:Node3D=MarchArt.box(parent,origin+Vector3(0,4,0),Vector3(5,0.7,1),Color("969585"),true)
	lintel.visible=false
	var visual:Node3D=Node3D.new()
	visual.name="StoneLandmarkArt"
	visual.position=origin
	parent.add_child(visual)
	for side:int in [-1,1]:
		stone(visual,Vector3(side*2,0.18,0),Vector3(1.20,0.36,1.18))
		for row:int in 5:
			var width:float=0.84 if row%2==0 else 0.94
			stone(visual,Vector3(side*2,0.77+row*0.67,0),Vector3(width,0.64,0.94))
		stone(visual,Vector3(side*2,3.78,0),Vector3(1.15,0.32,1.12))
		stone(visual,Vector3(side*2,4.55,0),Vector3(1.03,0.20,1.06))
	for block:int in 5:
		stone(visual,Vector3((block-2)*0.98,4.11,0),Vector3(0.95,0.56,1.03))
	# Fine colored bands read as crafted details without adding collision or lights.
	stone(visual,Vector3(0,4.41,-0.53),Vector3(3.05,0.06,0.03),"metal")
	Art.bake(visual)
	return visual

## A readable carved pedestal replaces the plain interaction cube.
static func make_marker(parent:Node3D)->Node3D:
	var visual:Node3D=Node3D.new()
	visual.name="LandmarkPedestal"
	parent.add_child(visual)
	stone(visual,Vector3(0,0.10,0),Vector3(1.0,0.20,1.0))
	stone(visual,Vector3(0,0.65,0),Vector3(0.68,0.95,0.68))
	stone(visual,Vector3(0,1.16,0),Vector3(0.86,0.18,0.86))
	stone(visual,Vector3(0,0.73,0.35),Vector3(0.24,0.30,0.035),"metal")
	Art.bake(visual)
	return visual
