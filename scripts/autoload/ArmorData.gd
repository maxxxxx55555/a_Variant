class_name ArmorData
extends ItemData

@export var defense: float = 20.0
@export var slot: String = "torso" # head, torso, legs
@export var durability: float = 100.0

func _init() -> void:
	type = "armor"
