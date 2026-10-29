extends "res://scripts/ui/CouncilFrame.gd"
const PanelsView=preload("res://scripts/ui/CampaignPanels.gd")

var roster: ItemList
var unit_choice: OptionButton
var recruit_count: SpinBox
var upkeep: Label
var faction_list: ItemList
var treaty_choice: OptionButton
var gift_amount: SpinBox
var result_label: Label
var journal: RichTextLabel
var selected_faction: String = "iron_guild"
var title_label: Label
var campaign_panels:PanelsView

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Scrim plus a single ledger card; the council never covers the world edge to edge.
	var scrim:StyleBoxFlat = StyleBoxFlat.new()
	scrim.bg_color = Color(UITheme.INK, 0.8)
	scrim.set_corner_radius_all(0)
	scrim.set_content_margin_all(0)
	add_theme_stylebox_override("panel", scrim)
	var frame:MarginContainer = MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_constant_override("margin_left", 260)
	frame.add_theme_constant_override("margin_right", 260)
	frame.add_theme_constant_override("margin_top", 84)
	frame.add_theme_constant_override("margin_bottom", 92)
	add_child(frame)
	var card:PanelContainer = PanelContainer.new()
	card.name = "CouncilCard"
	var surface:StyleBoxFlat = UITheme.panel(UITheme.SLATE)
	surface.content_margin_left = 60
	surface.content_margin_right = 60
	surface.content_margin_top = 46
	surface.content_margin_bottom = 40
	card.add_theme_stylebox_override("panel", surface)
	# The card hugs its content; leftover viewport stays world, not dead panel.
	var stack:VBoxContainer = VBoxContainer.new()
	frame.add_child(stack)
	stack.add_child(card)
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size.y = 800
	var column:VBoxContainer= VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var header:HBoxContainer= HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	column.add_child(header)
	title_label = Label.new()
	title_label.text = LocalizationManager.get_string("ui.strategy")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_override("font", UITheme.display_font())
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.add_theme_color_override("font_color", UITheme.BRASS)
	header.add_child(title_label)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	var close_button:Button = button(header, "ui.close", func()->void: get_tree().current_scene.call("toggle_pause"))
	close_button.custom_minimum_size = Vector2(140, 58)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var rule:ColorRect = ColorRect.new()
	rule.color = UITheme.LINE_SOFT
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var army:VBoxContainer= VBoxContainer.new()
	army.name = "Army"
	army.add_theme_constant_override("separation", 18)
	tabs.add_child(army)
	roster = ItemList.new()
	roster.custom_minimum_size.y = 160
	army.add_child(roster)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	roster.item_selected.connect(func(index:int)->void: ArmySystem.select_squad(index))
	var enlistment:HBoxContainer= HBoxContainer.new()
	army.add_child(enlistment)
	unit_choice = OptionButton.new()
	enlistment.add_child(unit_choice)
	for id:String in ArmySystem.UNIT_IDS:
		var data:UnitData=ArmySystem.unit_data(id)
		unit_choice.add_item(LocalizationManager.get_string(str(data.name_key)) + " · " + str(data.recruit_gold))
	recruit_count = SpinBox.new()
	recruit_count.min_value = 1
	recruit_count.max_value = 50
	recruit_count.value = 3
	enlistment.add_child(recruit_count)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	button(enlistment, "ui.recruit", func()->void:
		var ok: bool = ArmySystem.recruit(str(ArmySystem.UNIT_IDS[unit_choice.selected]), int(recruit_count.value))
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		AudioManager.play_sfx("purchase" if ok else "ui_error")
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
		refresh()
	)
	var orders:HBoxContainer= HBoxContainer.new()
	army.add_child(orders)
	for order:String in ArmySystem.ORDERS:
		# The container owns this action button and its callback.
		@warning_ignore("return_value_discarded")
		button(orders, "order." + order, func()->void: ArmySystem.issue_order_to_selected(order); refresh())
	var formations:HBoxContainer= HBoxContainer.new()
	army.add_child(formations)
	for formation:String in ArmySystem.FORMATIONS:
		# The container owns this action button and its callback.
		@warning_ignore("return_value_discarded")
		button(formations, "formation." + formation, func()->void: ArmySystem.set_formation_for_selected(formation); refresh())
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	button(formations, "ui.disband", func()->void: ArmySystem.disband_selected(); refresh())
	upkeep = Label.new()
	army.add_child(upkeep)
	var relations:VBoxContainer= VBoxContainer.new()
	relations.name = "Diplomacy"
	relations.add_theme_constant_override("separation", 18)
	tabs.add_child(relations)
	faction_list = ItemList.new()
	faction_list.custom_minimum_size.y = 220
	relations.add_child(faction_list)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	faction_list.item_selected.connect(func(index:int)->void: selected_faction = FactionSystem.factions.keys()[index]; refresh())
	treaty_choice = OptionButton.new()
	relations.add_child(treaty_choice)
	for id:String in DiplomacySystem.terms:
		var terms: Dictionary = DiplomacySystem.terms[id]
		treaty_choice.add_item(LocalizationManager.get_string("ui.treaty_terms", {"treaty": LocalizationManager.get_string("treaty." + id), "relation": terms.relationship, "gold": terms.gold}))
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	button(relations, "ui.sign_treaty", func()->void:
		var id: String = DiplomacySystem.terms.keys()[treaty_choice.selected]
		var ok: bool = DiplomacySystem.propose_treaty(selected_faction, id)
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		AudioManager.play_sfx("upgrade" if ok else "ui_error")
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.treaty_failed")
		refresh()
	)
	var gifts:HBoxContainer= HBoxContainer.new()
	relations.add_child(gifts)
	gift_amount = SpinBox.new()
	gift_amount.min_value = 10
	gift_amount.max_value = 500
	gift_amount.value = 50
	gifts.add_child(gift_amount)
	# The container owns this action button and its callback.
	@warning_ignore("return_value_discarded")
	button(gifts, "ui.gift", func()->void:
		var ok: bool = DiplomacySystem.give_gift(selected_faction, int(gift_amount.value))
		# AudioManager owns the voice and records the feedback acknowledgment.
		@warning_ignore("return_value_discarded")
		AudioManager.play_sfx("coin" if ok else "ui_error")
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
		refresh()
	)
	journal = RichTextLabel.new()
	journal.name = "Journal"
	journal.bbcode_enabled = true
	journal.custom_minimum_size.y = 380
	tabs.add_child(journal)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 19)
	result_label.add_theme_color_override("font_color", UITheme.BRASS)
	column.add_child(result_label)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	ArmySystem.roster_changed.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	FactionSystem.faction_relationship_changed.connect(func(_id:Variant, _value:Variant)->void: refresh())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	TimeSystem.day_passed.connect(func(_day:Variant)->void: refresh())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_language:Variant)->void: localize())
	localize()
	campaign_panels = preload("res://scripts/ui/CampaignPanels.gd").new()
	add_child(campaign_panels)
	campaign_panels.attach(self)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	CampaignSystem.changed.connect(refresh)


func localize() -> void:
	title_label.text = LocalizationManager.get_string("ui.strategy")
	for index:int in ArmySystem.UNIT_IDS.size():
		var data:UnitData=ArmySystem.unit_data(str(ArmySystem.UNIT_IDS[index]))
		unit_choice.set_item_text(index, LocalizationManager.get_string(str(data.name_key)) + " · " + str(data.recruit_gold))
	for index:int in DiplomacySystem.terms.size():
		var id: String = DiplomacySystem.terms.keys()[index]
		var terms: Dictionary = DiplomacySystem.terms[id]
		treaty_choice.set_item_text(index, LocalizationManager.get_string("ui.treaty_terms", {"treaty": LocalizationManager.get_string("treaty." + id), "relation": terms.relationship, "gold": terms.gold}))
	for control:Button in find_children("*", "Button", true, false):
		if control.has_meta("text_key"):
			control.text = LocalizationManager.get_string(str(control.get_meta("text_key")))
	tabs.set_tab_title(0, LocalizationManager.get_string("ui.army"))
	tabs.set_tab_title(1, LocalizationManager.get_string("ui.diplomacy"))
	tabs.set_tab_title(2, LocalizationManager.get_string("ui.journal"))
	refresh()

func refresh() -> void:
	if not is_instance_valid(roster):
		return
	for control:Button in find_children("*","Button",true,false):
		var key:String=control.get_meta("text_key","")
		if key.begins_with("order.") or key.begins_with("formation.") or key=="ui.disband":
			control.disabled=ArmySystem.squads.is_empty()
			control.tooltip_text=LocalizationManager.get_string("ui.recruit_first") if control.disabled else ""
	roster.clear()
	for squad:Dictionary in ArmySystem.squads:
		var squad_morale:float=squad.morale
		var path:String=squad.unit_res_path
		var data:UnitData=load(path) as UnitData
		# This list owns the row; selection is managed separately.
		@warning_ignore("return_value_discarded")
		roster.add_item(LocalizationManager.get_string(str(data.name_key)) + " · " + str(squad.count) + " · " + LocalizationManager.get_string("ui.morale") + " " + str(int(squad_morale)) + " · " + LocalizationManager.get_string("order." + str(squad.order)))
	if not ArmySystem.squads.is_empty():
		roster.select(clampi(ArmySystem.selected_squad_index, 0, ArmySystem.squads.size() - 1))
	var costs:Dictionary=ArmySystem.get_upkeep()
	var food:float=costs.food
	var gold:float=costs.gold
	upkeep.text = LocalizationManager.get_string("ui.army_upkeep", {"food": snappedf(food,0.1), "gold": snappedf(gold,0.1), "workers": PopulationSystem.available_workers})
	faction_list.clear()
	for id:String in FactionSystem.factions:
		var faction:Dictionary=FactionSystem.factions[id]
		var relationship:float=faction.relationship
		var threat:float=faction.threat
		var path:String=faction.res_path
		var data:FactionData=load(path) as FactionData
		# This list owns the row; selection is managed separately.
		@warning_ignore("return_value_discarded")
		faction_list.add_item(LocalizationManager.get_string(str(data.name_key)) + " · " + str(int(relationship)) + " · " + LocalizationManager.get_string("ui.threat") + " " + str(int(threat)) + " · " + str(faction.escalation_level) + "/5")
	var index: int = FactionSystem.factions.keys().find(selected_faction)
	if index >= 0:
		faction_list.select(index)
	journal.text = "[b]" + LocalizationManager.get_string("ui.journal") + "[/b]\n\n"
	for id:String in QuestSystem.active_quests:
		var quest:QuestData=load("res://data/quests/"+id+".tres") as QuestData
		if quest:
			journal.text += "[b]" + LocalizationManager.get_string(str(quest.title_key)) + "[/b]\n" + LocalizationManager.get_string(str(quest.desc_key)) + "\n\n"
	if CampaignSystem.active:
		journal.text = "[b]" + LocalizationManager.get_string("ui.campaign_progress", {"quests": CampaignSystem.completed.size(), "regions": CampaignSystem.reports.size()}) + "[/b]\n\n"
		for quest:Dictionary in CampaignSystem.active_quests():
			journal.text += "[b]" + LocalizationManager.get_string(str(quest.title)) + "[/b]\n" + LocalizationManager.get_string(str(quest.description)) + "\n\n"
		if not CampaignSystem.companions.is_empty():
			journal.text += "[b]" + LocalizationManager.get_string("ui.companions") + "[/b]\n"
			for id:String in CampaignSystem.companions:
				journal.text += LocalizationManager.get_string("companion." + id + ".name") + "\n"

func show_tab(index: int) -> void:
	tabs.current_tab = index
	refresh()
	show()
