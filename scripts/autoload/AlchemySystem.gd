extends Node

var known_recipes: Array[Resource] = []

func can_brew(recipe: RecipeData) -> bool:
	if not recipe:
		return false
	for i in range(recipe.required_ingredients.size()):
		var ing = recipe.required_ingredients[i]
		var req_cnt = recipe.required_counts[i] if i < recipe.required_counts.size() else 1
		if not has_ingredient(ing, req_cnt):
			return false
	return true

func has_ingredient(ingredient: Resource, count: int) -> bool:
	if not ingredient or not ingredient.resource_path:
		return false
	var found = 0
	for item in GameState.inventory:
		if item.get("resource_path") == ingredient.resource_path:
			found += item.get("count", 1)
	return found >= count

func brew_potion(recipe: RecipeData) -> bool:
	if not can_brew(recipe):
		return false
	for i in range(recipe.required_ingredients.size()):
		var ing = recipe.required_ingredients[i]
		var req_cnt = recipe.required_counts[i] if i < recipe.required_counts.size() else 1
		consume_ingredient(ing, req_cnt)

	GameState.add_item(recipe.result_item, recipe.result_count)
	EventBus.potion_brewed.emit(recipe)
	if AudioManager: AudioManager.play_sound("potion")
	return true

func consume_ingredient(ingredient: Resource, count: int) -> void:
	var remaining = count
	var i = GameState.inventory.size() - 1
	while i >= 0 and remaining > 0:
		var item = GameState.inventory[i]
		if item.get("resource_path") == ingredient.resource_path:
			var c = item.get("count", 1)
			if c <= remaining:
				remaining -= c
				GameState.inventory.remove_at(i)
			else:
				item["count"] = c - remaining
				remaining = 0
		i -= 1
