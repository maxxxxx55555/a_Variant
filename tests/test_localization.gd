extends SceneTree
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",message)
func run() -> void:
	await process_frame
	var locale:Node=root.get_node("LocalizationManager")
	var settings:Node=root.get_node("SettingsManager")
	for key in locale.translations:
		var row:Dictionary=locale.translations[key]
		check(not str(row.get("ru","")).is_empty() and not str(row.get("en","")).is_empty(),"Both languages contain "+key)
	check("language_confirmed" in settings,"First-run language choice has persistent confirmation")
	var menu:Control=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	var choice:OptionButton=menu.find_child("LanguageChoice",true,false)
	check(choice!=null,"Initial menu exposes a real language choice")
	if choice:
		var original_id:=menu.get_instance_id()
		choice.item_selected.emit(1)
		await process_frame
		check(is_instance_valid(menu) and menu.get_instance_id()==original_id,"Language selection updates the existing menu without scene reload")
		check(locale.current_language=="en","Initial selector applies English immediately")
	var font:Font=load("res://assets/fonts/GolosText.ttf")
	for letter in "ёЁ«»—":check(font.has_char(letter.unicode_at(0)),"Body font covers "+letter)
	print("LOCALIZATION RESULT: ","PASS" if failures==0 else "FAIL"," keys=",locale.translations.size())
	quit(0 if failures==0 else 1)
