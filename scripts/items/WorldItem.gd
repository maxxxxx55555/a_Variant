extends Area3D

@export var item_resource: Resource
@export var item_count: int = 1

@onready var prompt_label: String = "prompt.pickup"

func _ready() -> void:
	add_to_group("world_items")

func get_interaction_prompt() -> String:
	var name_key:String= "item"
	if item_resource and item_resource.get("name_key"):
		name_key = item_resource.get("name_key")
	var item_name:String= LocalizationManager.get_string(name_key)
	return LocalizationManager.get_string(prompt_label, {"item": item_name})

func interact(_player: Node) -> void:
	if item_resource:
		if GameState.add_item(item_resource, item_count):
			queue_free()
