class_name BuildingData
extends Resource

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var build_cost_wood: float = 50.0
@export var build_cost_stone: float = 30.0
@export var max_workers: int = 5
@export var resource_type: String = "food" # food, wood, ore, stone
@export var base_output: float = 10.0
