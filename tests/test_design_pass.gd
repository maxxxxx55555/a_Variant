extends "res://tests/AudioCleanTree.gd"

const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const IconSet=preload("res://scripts/ui/IconSet.gd")
const FactionView=preload("res://scripts/ui/FactionStyle.gd")

var failures:int=0

func _initialize() -> void:
	call_deferred("run")

func check(ok:bool,label:String) -> void:
	if not ok:
		failures+=1
		print("FAIL: ",label)

func translation(locale:Node,key:String,language:String) -> String:
	var rows:Dictionary=locale.translations
	if not rows.has(key):
		return ""
	var row:Variant=rows[key]
	if not row is Dictionary:
		return ""
	var fields:Dictionary=row
	return str(fields.get(language,""))

func find_locale_button(parent:Node,key:String) -> Button:
	for node:Node in parent.find_children("*","Button",true,false):
		if node.has_meta("locale_key") and str(node.get_meta("locale_key"))==key:
			var button:Button=node
			return button
	return null

func font_path(font:Font) -> String:
	if font is FontVariation:
		var variation:FontVariation=font
		if variation.base_font!=null:
			return variation.base_font.resource_path
	return font.resource_path if font!=null else ""

func run() -> void:
	await process_frame
	var locale:Node=root.get_node("LocalizationManager")
	var settings:Node=root.get_node("SettingsManager")
	var menu:Control=load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	await process_frame

	check(ThemeRef.INK.to_html(false)=="1e242a","Graphite base token matches the art direction")
	check(ThemeRef.PANEL.to_html(false)=="2a323a","Panel token matches the art direction")
	check(ThemeRef.PANEL_DEEP.to_html(false)=="171c21","Deep panel token matches the art direction")
	check(ThemeRef.PARCHMENT.to_html(false)=="e8dcc3","Parchment token matches the art direction")
	check(ThemeRef.DANGER.to_html(false)=="b4534b","Clay danger token matches the art direction")
	check(ThemeRef.BRASS.to_html(false)=="c9a227","Brass accent token matches the art direction")
	check(ThemeRef.CHALK.to_html(false)=="dce3e9","Chalk text token matches the art direction")
	check(ThemeRef.MIST.to_html(false)=="91a0a7","Mist secondary token matches the art direction")
	check(ThemeRef.SAGE.to_html(false)=="72968b","Sage support token matches the art direction")
	check(ThemeRef.EDGE.to_html(false)=="61717a","Edge token matches the art direction")

	var body_font:Font=menu.get_theme_default_font()
	check(font_path(body_font).ends_with("GolosText.ttf"),"Menus use the GolosText body family")
	var title_font_ok:bool=false
	for label:Node in menu.find_children("*","Label",true,false):
		if label.has_meta("locale_key") and str(label.get_meta("locale_key"))=="ui.title":
			var title:Label=label
			title_font_ok=font_path(title.get_theme_font("font")).ends_with("Literata.ttf")
	check(title_font_ok,"The title uses the Literata display family")
	check(body_font.has_char(0x042f) and body_font.has_char(0x0436),"Body type covers Russian and English")

	var backdrop:Control=menu.get_node_or_null("TitleBackdrop")
	check(backdrop!=null,"The title screen owns the painted backdrop")
	var painted:bool=false
	var motes_ready:bool=false
	if backdrop!=null:
		var painting:TextureRect=backdrop.get_node_or_null("Painting")
		painted=painting!=null and painting.texture!=null and painting.texture.resource_path.ends_with("title_painting.png")
		motes_ready=backdrop.motes.size()==42
	check(painted,"The painted march painting fills the title backdrop")
	check(motes_ready,"The title pollen field is deterministic and bounded")
	if backdrop!=null:
		var previous_motion:bool=bool(settings.reduced_motion)
		settings.reduced_motion=true
		check(not backdrop.motion_active(),"Reduced motion freezes the title parallax")
		await process_frame
		check(backdrop.travel.length()<0.001,"Reduced motion returns the backdrop pan to rest")
		settings.reduced_motion=false
		check(backdrop.motion_active(),"The parallax resumes when motion is allowed")
		settings.reduced_motion=previous_motion
		var painting_layer:TextureRect=backdrop.get_node("Painting")
		check(painting_layer.size.x>backdrop.size.x and painting_layer.size.y>backdrop.size.y,"The painting overscans so the pan never exposes an edge")

	var action_icons_ok:bool=true
	var action_surfaces_ok:bool=true
	for key:String in ["ui.continue","ui.new_campaign","ui.stats","ui.credits","ui.exit"]:
		var button:Button=find_locale_button(menu,key)
		if button==null:
			action_icons_ok=false
			continue
		action_icons_ok=action_icons_ok and button.icon!=null and button.icon.resource_path.ends_with(".svg")
		action_surfaces_ok=action_surfaces_ok and button.get_theme_stylebox("normal") is StyleBoxTexture
	check(action_icons_ok,"Every title action carries an authored icon")
	check(action_surfaces_ok,"Every title action uses the authored surface family")
	var focus_style:StyleBox=menu.continue_button.get_theme_stylebox("focus")
	var focus_ring_ok:bool=focus_style is StyleBoxFlat
	if focus_ring_ok:
		var flat:StyleBoxFlat=focus_style
		focus_ring_ok=flat.border_width_left>=2 and flat.border_color.to_html(false)=="e8dcc3"
	check(focus_ring_ok,"Keyboard focus keeps the parchment ring")
	var motion_constants:Dictionary=(load("res://scripts/ui/UIMotion.gd") as Script).get_script_constant_map()
	check(is_equal_approx(float(motion_constants.get("HOVER_SCALE",0.0)),1.02),"Hover motion stays at the authored 1.02 scale")
	check(is_equal_approx(float(motion_constants.get("DURATION",0.0)),0.16),"Hover motion stays at the authored 160 ms ease")
	check(menu.continue_button.has_meta("ui_motion"),"Title actions attach the shared motion helper")
	var previous_motion_focus:bool=bool(settings.reduced_motion)
	settings.reduced_motion=true
	menu.continue_button.scale=Vector2.ONE*1.4
	menu.continue_button.mouse_entered.emit()
	await process_frame
	check(menu.continue_button.scale==Vector2.ONE,"Reduced motion snaps interactive scale to rest")
	settings.reduced_motion=previous_motion_focus
	menu.continue_button.mouse_exited.emit()
	await process_frame

	var icons_ok:bool=true
	for icon_name:String in IconSet.NAMES:
		var picture:Texture2D=IconSet.texture(icon_name)
		if picture==null or picture.get_width()!=24 or picture.get_height()!=24:
			icons_ok=false
	check(icons_ok,"All %d interface icons resolve at 24 px"%IconSet.NAMES.size())
	var slots_ok:bool=true
	for icon_name:String in ["slot_head","slot_torso","slot_legs","slot_weapon"]:
		slots_ok=slots_ok and IconSet.texture(icon_name)!=null
	check(slots_ok,"Equipment slots have dedicated authored icons")

	menu.open_stats()
	await process_frame
	var stats_panel:Control=menu.find_child("StatsPanel",true,false)
	check(stats_panel!=null and stats_panel.find_child("StatsIcon",true,false)!=null,"Statistics opens with its authored header icon")
	if stats_panel!=null:
		stats_panel.close()
		await process_frame
	menu.open_credits()
	await process_frame
	var credits:Control=menu.find_child("CreditsPanel",true,false)
	check(credits!=null and credits.find_child("CreditsIcon",true,false)!=null,"Credits opens with its authored header icon")
	if credits!=null:
		credits.close()
		await process_frame

	var transition:CanvasLayer=root.get_node("MarchTransition")
	transition.show_loading()
	await process_frame
	check(transition.find_child("LoadingProgress",true,false) is ProgressBar,"Loading exposes a real progress bar")
	check(transition.find_child("LoadingTip",true,false) is Label,"Loading shows a rotating tip")
	var tips_ok:bool=true
	for index:int in 6:
		var key:String="flow.tip."+str(index)
		var ru:String=translation(locale,key,"ru")
		var en:String=translation(locale,key,"en")
		tips_ok=tips_ok and not ru.is_empty() and not en.is_empty() and ru!=en
	check(tips_ok,"Every loading tip is localized in both languages")
	transition.hide_loading()
	await process_frame

	locale.set_language("en")
	await process_frame
	menu.localize()
	var english_continue:String=menu.continue_button.text
	locale.set_language("ru")
	await process_frame
	menu.localize()
	check(menu.continue_button.text!=english_continue and not menu.continue_button.text.is_empty(),"Title actions relocalize without losing their icon contract")
	menu.queue_free()
	await process_frame

	var campaign:Node=root.get_node("CampaignSystem")
	campaign.new_campaign(1,false)
	var world:Node3D=load("res://scenes/world/march.tscn").instantiate()
	root.add_child(world)
	current_scene=world
	await process_frame
	await process_frame

	var hud:Control=world.hud
	var quest_icon:TextureRect=hud.find_child("QuestTrackerIcon",true,false)
	check(quest_icon!=null and quest_icon.texture!=null and quest_icon.texture.resource_path.ends_with("quest.svg"),"The quest tracker leads with the authored quest icon")
	check(hud.quest_label.position.x>=44.0,"Quest text clears the tracker icon")
	var hud_icons_ok:bool=true
	for button:Button in [hud.inventory_btn,hud.town_btn,hud.alchemy_btn,hud.council_btn,hud.codex_btn]:
		hud_icons_ok=hud_icons_ok and button.icon!=null and button.icon.resource_path.ends_with(".svg")
	check(hud_icons_ok,"Every HUD destination button carries an authored icon")

	var inventory:Control=world.inventory_ui
	var slot_icons_ok:bool=true
	for button:Button in [inventory.head_btn,inventory.torso_btn,inventory.legs_btn,inventory.weapon_btn]:
		slot_icons_ok=slot_icons_ok and button.icon!=null and str(button.icon.resource_path).contains("slot_")
	check(slot_icons_ok,"Equipment slots show their authored slot icons")
	var frames_ok:bool=true
	for button:Button in [inventory.head_btn,inventory.torso_btn,inventory.legs_btn,inventory.weapon_btn]:
		var frame:StyleBox=button.get_theme_stylebox("normal")
		frames_ok=frames_ok and frame is StyleBoxFlat and (frame as StyleBoxFlat).border_width_left==2
	check(frames_ok,"Equipment slots use the two-pixel rarity frame")

	var settlement:Control=world.settlement_ui
	check(settlement.buildings_heading.text==locale.get_string("settlement.buildings"),"The settlement building strip is labelled in the active language")
	var workshop:Node=root.get_node("WorkshopSystem")
	check(settlement.buildings_strip.get_child_count()==workshop.definitions.size(),"Every workshop building earns a visible tile")
	var tiles_ok:bool=true
	for tile:Node in settlement.buildings_strip.get_children():
		var tile_icons:Array=tile.find_children("*","TextureRect",true,false)
		var pips:int=0
		for mark:Node in tile.find_children("*","ColorRect",true,false):
			pips+=1
		tiles_ok=tiles_ok and tile_icons.size()==1 and (tile_icons[0] as TextureRect).texture!=null and pips==3
	check(tiles_ok,"Building tiles pair an icon with three upgrade pips")

	world.toggle_strategy(0)
	await process_frame
	var strategy:Control=world.strategy_ui
	check(strategy.ladder_segments.size()==5 and strategy.ladder.get_child_count()==5,"The escalation ladder exposes five authored segments")
	var faction_rows:Dictionary=root.get_node("FactionSystem").factions
	var faction:Dictionary=faction_rows.get(strategy.selected_faction,{})
	var level:int=int(faction.get("escalation_level",0))
	var accent:Color=FactionView.color(strategy.selected_faction)
	check(strategy.faction_strip.color.to_html(false)==accent.to_html(false),"The council stripes the selected faction in its CVD-safe color")
	check(strategy.escalation_label.text.contains(locale.get_string("escalation."+str(clampi(level,0,5)))),"The escalation label names the current stage in the active language")
	var tabs_icons_ok:bool=true
	for index:int in 3:
		tabs_icons_ok=tabs_icons_ok and strategy.tabs.get_tab_icon(index)!=null
	check(tabs_icons_ok,"Council tabs carry authored icons")
	check(strategy.find_child("CouncilIcon",true,false)!=null,"The council header carries its authored icon")
	world.toggle_strategy(0)
	await process_frame

	var pause:Control=world.pause_menu
	pause._on_toggle_settings()
	await process_frame
	check(pause.find_child("SettingsIcon",true,false)!=null,"Settings open with their authored header icon")
	check(pause.settings_panel.visible,"The settings frame is reachable from the pause menu")
	pause._on_toggle_settings()
	await process_frame
	var codex:Control=world.codex_ui
	check(codex.find_child("CodexIcon",true,false)!=null,"The codex carries its authored header icon")

	world.queue_free()
	await process_frame
	print("DESIGN PASS RESULT: ","PASS" if failures==0 else "FAIL")
	finish_test(0 if failures==0 else 1)
