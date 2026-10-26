extends Node
const Guard=preload("res://scripts/security/SaveGuard.gd")

var known_recipes:Array[RecipeData] = []

func _ready() -> void:
	var catalog: Array = BuildIntegrity.read_json("res://data/balance/alchemy.json")
	for entry:Dictionary in catalog:
		var recipe:RecipeData= RecipeData.new()
		recipe.id = entry.id
		var result_path:String=entry.result
		var result_item:ItemData=load(result_path) as ItemData
		recipe.result_item=result_item
		recipe.name_key=result_item.name_key
		recipe.result_count = 1
		var ingredients:Dictionary=entry.ingredients
		for id:String in ingredients:
			recipe.required_ingredients.append(load("res://data/potions/" + id + ".tres"))
			var amount:int=ingredients[id]
			recipe.required_counts.append(amount)
		known_recipes.append(recipe)

func can_brew(recipe: RecipeData) -> bool:
	if not recipe or not recipe.result_item or recipe.result_count <= 0 or recipe.required_ingredients.is_empty() or recipe.required_counts.size() != recipe.required_ingredients.size():
		return false
	if not GameState.can_add_item(recipe.result_item,recipe.result_count): return false
	for i:int in range(recipe.required_ingredients.size()):
		var ing:Resource= recipe.required_ingredients[i]
		var req_cnt:int= recipe.required_counts[i] if i < recipe.required_counts.size() else 1
		if req_cnt <= 0 or not has_ingredient(ing, req_cnt):
			return false
	return true

func has_ingredient(ingredient: Resource, count: int) -> bool:
	if not ingredient or not ingredient.resource_path:
		return false
	var found:int= 0
	for item:Dictionary in GameState.inventory:
		if item.get("resource_path") == ingredient.resource_path:
			found += item.get("count", 1)
	return found >= count

func brew_potion(recipe: RecipeData) -> bool:
	if not can_brew(recipe) or not Guard.begin_transaction():
		return false
	for i:int in range(recipe.required_ingredients.size()):
		var ing:Resource= recipe.required_ingredients[i]
		var req_cnt:int= recipe.required_counts[i] if i < recipe.required_counts.size() else 1
		consume_ingredient(ing, req_cnt)

	# Capacity is checked before the non-reentrant, guarded inventory transaction.
	@warning_ignore("return_value_discarded")
	GameState.add_item(recipe.result_item, recipe.result_count)
	Guard.end_transaction()
	EventBus.potion_brewed.emit(recipe)
	if AudioManager: AudioManager.play_sound("potion")
	return true

func consume_ingredient(ingredient: Resource, count: int) -> void:
	var remaining:int= count
	var i:int= GameState.inventory.size() - 1
	while i >= 0 and remaining > 0:
		var item:Dictionary= GameState.inventory[i]
		if item.get("resource_path") == ingredient.resource_path:
			var c:int= item.get("count", 1)
			if c <= remaining:
				remaining -= c
				GameState.inventory.remove_at(i)
			else:
				item["count"] = c - remaining
				remaining = 0
		i -= 1
