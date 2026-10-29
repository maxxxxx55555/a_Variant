extends Control
const UITheme=preload("res://scripts/ui/MarchTheme.gd")

@onready var recipe_list: ItemList = $MarginContainer/HBoxContainer/RecipeList
@onready var info_label: RichTextLabel = $MarginContainer/HBoxContainer/VBoxContainer/InfoLabel
@onready var brew_button: Button = $MarginContainer/HBoxContainer/VBoxContainer/BrewButton

var selected_recipe: RecipeData = null

func _ready() -> void:
	_style_shell()
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	brew_button.pressed.connect(_on_brew_pressed)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	recipe_list.item_selected.connect(_on_recipe_selected)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.inventory_updated.connect(update_info)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: refresh_recipes())
	refresh_recipes()

# Same ledger shell as the inventory: scrim, card, titled column.
func _style_shell() -> void:
	var scrim:ColorRect = $ColorRect as ColorRect
	scrim.color = Color(UITheme.INK, 0.8)
	var card:PanelContainer = PanelContainer.new()
	card.name = "AlchemyCard"
	card.add_theme_stylebox_override("panel", UITheme.panel(UITheme.SLATE))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	move_child(card, 1)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 220
	card.offset_right = -220
	card.offset_top = 100
	card.offset_bottom = -100
	var margin:MarginContainer = $MarginContainer as MarginContainer
	for side:String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 260)
	for side:String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 140)
	var row:HBoxContainer = $MarginContainer/HBoxContainer as HBoxContainer
	row.add_theme_constant_override("separation", 40)
	var holder:VBoxContainer = VBoxContainer.new()
	holder.add_theme_constant_override("separation", 12)
	row.add_child(holder)
	row.move_child(holder, 0)
	var title:Label = Label.new()
	title.text = LocalizationManager.get_string("ui.alchemy")
	title.set_meta("locale_key", "ui.alchemy")
	title.add_theme_font_override("font", UITheme.display_font())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", UITheme.BRASS)
	holder.add_child(title)
	recipe_list.reparent(holder)
	recipe_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_list.custom_minimum_size = Vector2(470, 0)
	recipe_list.add_theme_font_size_override("font_size", 19)
	info_label.add_theme_font_size_override("normal_font_size", 20)
	info_label.add_theme_font_size_override("bold_font_size", 24)
	info_label.add_theme_color_override("default_color", UITheme.CHALK)
	brew_button.custom_minimum_size = Vector2(220, 56)
	brew_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	brew_button.add_theme_font_size_override("font_size", 20)

func refresh_recipes() -> void:
	var selection:int=AlchemySystem.known_recipes.find(selected_recipe)
	recipe_list.clear()
	var sample_recipe:RecipeData= RecipeData.new()
	sample_recipe.id = "health_potion_recipe"
	sample_recipe.name_key = "item.health_potion.name"
	sample_recipe.result_item = load("res://data/potions/health_potion.tres")
	sample_recipe.result_count = 1
	sample_recipe.required_ingredients.append(load("res://data/potions/healing_herb.tres"))
	sample_recipe.required_counts.append(2)

	if AlchemySystem.known_recipes.is_empty():
		AlchemySystem.known_recipes.append(sample_recipe)

	for r:RecipeData in AlchemySystem.known_recipes:
		var name_str:String= LocalizationManager.get_string(str(r.result_item.get("name_key")))
		# This list owns the row; selection is managed separately.
		@warning_ignore("return_value_discarded")
		recipe_list.add_item(name_str)
	brew_button.text = LocalizationManager.get_string("ui.brew")
	if not AlchemySystem.known_recipes.is_empty():
		recipe_list.select(maxi(0,selection))
		_on_recipe_selected(maxi(0,selection))

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

	var name_str:String= LocalizationManager.get_string(str(selected_recipe.result_item.get("name_key")))
	var text:String= "[b]" + name_str + "[/b]\n\n"
	text += LocalizationManager.get_string("ui.ingredients") + ":\n"
	for i:int in range(selected_recipe.required_ingredients.size()):
		var ing:Resource= selected_recipe.required_ingredients[i]
		var cnt:int= selected_recipe.required_counts[i]
		var ing_name:String= LocalizationManager.get_string(str(ing.get("name_key")))
		var has_cnt:bool= AlchemySystem.has_ingredient(ing, cnt)
		var col:String= "[color=green]" if has_cnt else "[color=red]"
		var availability:String=LocalizationManager.get_string("ui.ingredient_ready" if has_cnt else "ui.ingredient_missing")
		text += "- " + ing_name + " ×" + str(cnt) + " (" + col + availability + "[/color])\n"

	info_label.text = text
	brew_button.disabled = not AlchemySystem.can_brew(selected_recipe)
	brew_button.tooltip_text=LocalizationManager.get_string("ui.brew_requirements") if brew_button.disabled else ""

func _on_brew_pressed() -> void:
	if selected_recipe and AlchemySystem.brew_potion(selected_recipe):
		update_info()
	else:
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		AudioManager.play_sfx("ui_error")
		update_info()
