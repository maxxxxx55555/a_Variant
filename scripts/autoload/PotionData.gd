class_name PotionData
extends ItemData

@export var heal_amount: float = 35.0
@export var stamina_amount: float = 0.0
@export var damage_multiplier: float = 1.0
@export var defense_bonus: float = 0.0
@export var movement_multiplier: float = 1.0
@export var effect_duration: float = 30.0

func _init() -> void:
	type = "potion"
	weight = 0.5
