class_name LootTableData
extends Resource

@export var possible_items: Array[Resource] = []
@export var drop_chances: Array[float] = []

func get_random_drop() -> Resource:
	if possible_items.is_empty():
		return null
	var roll = randf()
	var cumulative = 0.0
	for i in range(possible_items.size()):
		var chance = drop_chances[i] if i < drop_chances.size() else 0.1
		cumulative += chance
		if roll <= cumulative:
			return possible_items[i]
	return possible_items[0]
