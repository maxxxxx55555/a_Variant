extends Control

@onready var recipe_list: ItemList = $MarginContainer/HBoxContainer/RecipeList
@onready var info_label: RichTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/InfoLabel
@onready var brew_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/BrewButton

var selected_recipe: RecipeData = null

func _ready() -> void:
	brew_button.pressed.connect(_on_brew_pressed)
	recipe_list.item_selected.connect(_on_recipe_selected)
	EventBus.inventory_updated.connect(update_info)
	EventBus.language_changed.connect(func(_lang): refresh_recipes())
	refresh_recipes()

func refresh_recipes() -> void:
	recipe_list.clear()
	var sample_recipe = RecipeData.new()
	sample_recipe.id = "health_potion_recipe"
	sample_recipe.name_key = "item.health_potion.name"
	sample_recipe.result_item = load("res://data/potions/health_potion.tres")
	sample_recipe.result_count = 1
	sample_recipe.required_ingredients.append(load("res://data/potions/healing_herb.tres"))
	sample_recipe.required_counts.append(2)

	if AlchemySystem.known_recipes.is_empty():
		AlchemySystem.known_recipes.append(sample_recipe)

	for r in AlchemySystem.known_recipes:
		var name_str = LocalizationManager.get_string(r.result_item.get("name_key"))
		recipe_list.add_item(name_str)
	brew_button.text = LocalizationManager.get_string("ui.brew")
	if not AlchemySystem.known_recipes.is_empty():
		recipe_list.select(0)
		_on_recipe_selected(0)

func _on_recipe_selected(idx: int) -> void:
	if idx >= 0 and idx < AlchemySystem.known_recipes.size():
		selected_recipe = AlchemySystem.known_recipes[idx]
		update_info()

func update_info() -> void:
	if not selected_recipe:
		info_label.text = ""
		brew_button.disabled = true
		brew_button.tooltip_text=LocalizationManager.get_string("ui.select_recipe")
		return

	var name_str = LocalizationManager.get_string(selected_recipe.result_item.get("name_key"))
	var text = "[b]" + name_str + "[/b]\n\n"
	text += LocalizationManager.get_string("ui.ingredients") + ":\n"
	for i in range(selected_recipe.required_ingredients.size()):
		var ing = selected_recipe.required_ingredients[i]
		var cnt = selected_recipe.required_counts[i]
		var ing_name = LocalizationManager.get_string(ing.get("name_key"))
		var has_cnt = AlchemySystem.has_ingredient(ing, cnt)
		var col = "[color=green]" if has_cnt else "[color=red]"
		text += "- " + ing_name + " x" + str(cnt) + " (" + col + "OK[/color])\n"

	info_label.text = text
	brew_button.disabled = not AlchemySystem.can_brew(selected_recipe)
	brew_button.tooltip_text=LocalizationManager.get_string("ui.brew_requirements") if brew_button.disabled else ""

func _on_brew_pressed() -> void:
	if selected_recipe:
		if AlchemySystem.brew_potion(selected_recipe):
			update_info()
