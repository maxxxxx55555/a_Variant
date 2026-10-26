extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:failures+=1;print("FAIL: ",message)
func run() -> void:
	await process_frame
	var state:Node=root.get_node("GameState")
	state.inventory.clear()
	var panel:Control=load("res://scenes/ui/alchemy_ui.tscn").instantiate()
	root.add_child(panel)
	var recipe:Resource=panel.selected_recipe
	for language in ["en","ru"]:
		root.get_node("LocalizationManager").set_language(language)
		state.inventory.clear();panel.update_info()
		check(not "OK" in panel.info_label.text,"Missing ingredients are never labelled OK")
		check(root.get_node("LocalizationManager").get_string("ui.ingredient_missing") in panel.info_label.text,"Shortage has a localized explanation")
		for i in recipe.required_ingredients.size():state.add_item(recipe.required_ingredients[i],recipe.required_counts[i])
		panel.update_info()
		check(root.get_node("LocalizationManager").get_string("ui.ingredient_ready") in panel.info_label.text,"Available ingredients have accurate localized feedback")
	print("LOCALIZED FEEDBACK RESULT: ","PASS" if failures==0 else "FAIL")
	quit(0 if failures==0 else 1)
