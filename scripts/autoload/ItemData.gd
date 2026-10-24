class_name ItemData
extends Resource

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var icon: Texture2D
@export var weight: float = 1.0
@export var rarity: String = "common" # common, uncommon, rare, epic, legendary
@export var type: String = "misc" # weapon, armor, potion, misc
@export var repair_cost_per_point: float = 0.25
