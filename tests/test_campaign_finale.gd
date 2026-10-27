extends "res://tests/AudioCleanTree.gd"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	await process_frame
	var path:="res://scripts/ui/CampaignFinale.gd"
	if not ResourceLoader.exists(path):
		print("FAIL: Campaign ending needs its illustrated, themed presentation")
		finish_test(1)
		return
	var before: Dictionary=root.get_node("CampaignSystem").capture_state()
	var panel: Control=load(path).new()
	panel.route="diplomatic"
	panel.quests=60
	panel.days=8
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	var button:=panel.find_child("ContinueEnding",true,false) as Button
	var calls: Array=[0]
	panel.continued.connect(func(): calls[0]+=1)
	var ok: bool=button!=null and button.has_focus() and button.get_theme_stylebox("normal") is StyleBoxTexture
	ok=ok and root.get_visible_rect().encloses(button.get_global_rect()) and panel.find_children("*","TextureRect",true,false).size()>=1
	button.pressed.emit()
	ok=ok and calls[0]==1 and root.get_node("CampaignSystem").capture_state()==before
	print("CAMPAIGN FINALE RESULT: ","PASS" if ok else "FAIL")
	finish_test(0 if ok else 1)
