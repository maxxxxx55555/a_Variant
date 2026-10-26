extends StaticBody3D

var faction_id: String
var health_label: Label3D

func _ready() -> void:
	set_meta("surface", "wood")
	var collider:CollisionShape3D= CollisionShape3D.new()
	var shape:BoxShape3D= BoxShape3D.new()
	shape.size = Vector3(5, 3.4, 0.65)
	collider.shape = shape
	collider.position.y = 1.7
	add_child(collider)
	for side:int in [-1, 1]:
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(self, Vector3(side * 3.2, 2.5, 0), Vector3(1.5, 5, 1.5), Color("6f786d"))
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		for top:int in [-1, 1]: MarchArt.box(self, Vector3(side * 3.2 + top * 0.45, 5.2, 0), Vector3(0.4, 0.6, 1.6), Color("879080"))
	for index:int in 10:
		# The generated mesh is attached to its parent; no separate handle is needed here.
		@warning_ignore("return_value_discarded")
		MarchArt.box(self, Vector3(index * 0.5 - 2.25, 1.7, 0), Vector3(0.45, 3.4, 0.6), Color("66503a"))
	# The generated mesh is attached to its parent; no separate handle is needed here.
	@warning_ignore("return_value_discarded")
	for height:float in [0.6, 2.6]: MarchArt.box(self, Vector3(0, height, 0.36), Vector3(5, 0.16, 0.12), Color("303a39"))
	health_label = MarchArt.label(self, "", Vector3(0, 4.4, 0))
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	SiegeSystem.changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void:refresh())
	refresh()

func take_damage(amount: float) -> void:
	if SiegeSystem.damage_gate(faction_id, amount):
		AudioManager.play_sound("swing")

func refresh() -> void:
	if not SiegeSystem.states.has(faction_id) or SiegeSystem.states[faction_id].wall_hp <= 0 or faction_id in CampaignSystem.conquests:
		collision_layer = 0
		queue_free()
		return
	var wall_hp:float=SiegeSystem.states[faction_id].wall_hp
	health_label.text = LocalizationManager.get_string("siege.gate", {"hp": int(wall_hp)})
