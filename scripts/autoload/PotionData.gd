class_name PotionData
extends ItemData

@export var heal_amount: float = 35.0

func _init() -> void:
	type = "potion"
	weight = 0.5
