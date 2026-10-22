class_name RecipeData
extends Resource

@export var id: String = ""
@export var name_key: String = ""
@export var result_item: Resource
@export var result_count: int = 1
@export var required_ingredients: Array[Resource] = []
@export var required_counts: Array[int] = []
