class_name ArmorData
extends EquipmentData

@export var defense: float = 20.0
@export var slot: String = "torso" # head, torso, legs

func _init() -> void:
	type = "armor"
