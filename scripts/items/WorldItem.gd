extends Area3D
const LootStyle=preload("res://scripts/ui/LootStyle.gd")

@export var item_resource: Resource
@export var item_count: int = 1

@onready var prompt_label: String = "prompt.pickup"

var _mesh: MeshInstance3D
var _halo: MeshInstance3D
var _phase: float = 0.0
var _collected: bool = false

func _ready() -> void:
	add_to_group("world_items")
	_phase = randf() * TAU
	_apply_look()

func _apply_look() -> void:
	var rarity: String = LootStyle.rarity_of(item_resource)
	var color: Color = LootStyle.color_of(rarity)
	_mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if _mesh:
		var gem: SphereMesh = SphereMesh.new()
		gem.radius = 0.13
		gem.height = 0.34
		gem.radial_segments = 12
		gem.rings = 6
		_mesh.mesh = gem
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.35
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 1.2 if rarity == "common" else 2.4
		_mesh.material_override = material
	_halo = MeshInstance3D.new()
	_halo.name = "RarityGlow"
	var halo_mesh: SphereMesh = SphereMesh.new()
	halo_mesh.radius = 0.27
	halo_mesh.height = 0.54
	halo_mesh.radial_segments = 12
	halo_mesh.rings = 6
	_halo.mesh = halo_mesh
	var halo_material: StandardMaterial3D = StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	halo_material.albedo_color = Color(color.r, color.g, color.b, 0.17)
	_halo.material_override = halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)

func _process(delta: float) -> void:
	if _collected:
		return
	_phase += delta
	if _mesh:
		_mesh.position.y = 0.12 + sin(_phase * 2.2) * 0.06
		_mesh.rotation.y += delta * 1.4
	if _halo:
		_halo.scale = Vector3.ONE * (1.0 + sin(_phase * 2.2) * 0.12)

func get_interaction_prompt() -> String:
	var name_key:String= "item"
	if item_resource and item_resource.get("name_key"):
		name_key = item_resource.get("name_key")
	var item_name:String= LocalizationManager.get_string(name_key)
	return LocalizationManager.get_string(prompt_label, {"item": item_name})

func interact(_player: Node) -> void:
	if _collected or item_resource == null:
		return
	if not GameState.add_item(item_resource, item_count):
		return
	_collected = true
	_play_rarity_cue()
	_play_pickup_pop()

func _play_rarity_cue() -> void:
	var rarity: String = LootStyle.rarity_of(item_resource)
	var pitches: Dictionary[String, float] = {"rare": 1.0, "epic": 1.08, "legendary": 1.16}
	if not pitches.has(rarity):
		AudioManager.play_sound("pickup")
		return
	var voice: AudioStreamPlayer3D = AudioManager.play_at("loot_chime", global_position)
	if voice:
		voice.pitch_scale = pitches[rarity]

func _play_pickup_pop() -> void:
	monitorable = false
	set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	var pop: Tween = create_tween().set_parallel(true)
	if _mesh:
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		pop.tween_property(_mesh, "position:y", 1.1, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		pop.tween_property(_mesh, "scale", Vector3.ONE * 1.7, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _halo:
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		pop.tween_property(_halo, "scale", Vector3.ONE * 2.2, 0.3)
		# MeshInstance3D swallows light additively; transparency is the 3D equivalent of an alpha fade.
		# Tween retains this fluent configuration.
		@warning_ignore("return_value_discarded")
		pop.tween_property(_halo, "transparency", 1.0, 0.3)
	@warning_ignore("return_value_discarded")
	pop.finished.connect(queue_free)
