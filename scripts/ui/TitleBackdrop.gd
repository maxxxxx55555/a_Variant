extends Control

## Painted title scene with a slow, bounded parallax pan and quiet pollen motes.

const PAINTING:Texture2D=preload("res://assets/art/title_painting.png")
const MOTES:int=42
const INSET:Vector2=Vector2(26,16)

var layer:TextureRect
var haze:ColorRect
var elapsed:float=0.0
var travel:Vector2=Vector2.ZERO
var motes:Array[Vector3]=[]

func _ready() -> void:
	name="TitleBackdrop"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer=TextureRect.new()
	layer.name="Painting"
	layer.texture=PAINTING
	layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	haze=ColorRect.new()
	haze.name="Haze"
	haze.color=Color(0.055,0.075,0.09,0.20)
	haze.mouse_filter=Control.MOUSE_FILTER_IGNORE
	haze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(haze)
	var rng:RandomNumberGenerator=RandomNumberGenerator.new()
	rng.seed=0xA17E5
	for index:int in MOTES:
		motes.append(Vector3(rng.randf(),rng.randf(),rng.randf()*TAU))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_instance_valid(layer):
		return
	layer.position=-INSET
	layer.size=size+INSET*2.0

func motion_active() -> bool:
	var tree:SceneTree=Engine.get_main_loop() as SceneTree
	if tree==null:
		return true
	var settings:Node=tree.root.get_node_or_null("SettingsManager")
	if settings==null:
		return true
	return settings.get("reduced_motion")!=true

func _process(delta:float) -> void:
	var active:bool=motion_active()
	if active:
		elapsed+=minf(delta,0.1)
		var target:Vector2=Vector2(sin(elapsed*0.075)*INSET.x*0.8,cos(elapsed*0.048)*INSET.y*0.5)
		travel=travel.lerp(target,1.0-exp(-delta*1.3))
	else:
		travel=Vector2.ZERO
	if is_instance_valid(layer):
		layer.position=-INSET+travel
	queue_redraw()

func _draw() -> void:
	var time:float=elapsed if motion_active() else 0.0
	for mote:Vector3 in motes:
		var x:float=fposmod(mote.x*size.x+sin(time*0.6+mote.z)*7.0+time*4.0,size.x+24.0)-12.0
		var y:float=size.y-fposmod(mote.y*size.y+time*(4.0+mote.z*1.7),size.y+48.0)+24.0
		var radius:float=1.1+mote.z*0.22
		var alpha:float=0.10+absf(sin(time*0.35+mote.z))*0.16
		draw_circle(Vector2(x,y),radius,Color(0.91,0.86,0.76,alpha))
