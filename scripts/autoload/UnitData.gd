class_name UnitData
extends Resource

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var unit_type: String = "infantry" # spear_militia, swordsmen, archer, heavy_infantry
@export var health: float = 100.0
@export var damage: float = 15.0
@export var defense: float = 10.0
@export var speed: float = 4.0
@export var range_distance: float = 2.0
@export var food_consumption: float = 1.5
@export var daily_wage: float = 2.0
@export var formation_type: String = "line" # line, shield_wall, loose
