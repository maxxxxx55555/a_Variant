extends Area3D

var data: Dictionary = {}
var is_town: bool = false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.3
	shape.radius = 0.7
	collider.shape = shape
	collider.position.y = 1.1
	add_child(collider)
	if is_town:
		MarchArt.humanoid(self, Color("a6976b"))
	else:
		MarchArt.box(self, Vector3(0, 0.7, 0), Vector3(0.8, 1.4, 0.8), Color("989887"), false)
	var key: String = data.name if is_town else "poi." + data.kind
	MarchArt.label(self, LocalizationManager.get_string(key) + " [E]", Vector3(0, 2.7, 0))

func get_interaction_prompt() -> String:
	return LocalizationManager.get_string("ui.talk" if is_town else "ui.investigate") + " [E]"

func interact(_player: Node) -> void:
	if is_town:
		get_tree().current_scene.open_town(data.id)
	else:
		var found := CampaignSystem.explore(data)
		EventBus.notification_posted.emit(LocalizationManager.get_string("ui.cache_found" if found else "ui.already_explored"), false)
