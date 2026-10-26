class_name WeaponData
extends EquipmentData

@export var damage: float = 15.0
@export var speed: float = 1.0
@export var reach: float = 2.0
@export var stamina_cost: float = 10.0

func _init() -> void:
	type = "weapon"
