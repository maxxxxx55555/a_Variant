extends PanelContainer

var tabs: TabContainer
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
var campaign_panels: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.07, 0.065, 0.98)
	style.content_margin_left = 50
	style.content_margin_right = 50
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	title_label = Label.new()
	title_label.text = LocalizationManager.get_string("ui.strategy")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	button(header, "ui.close", func(): get_tree().current_scene.toggle_pause())
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var army := VBoxContainer.new()
	army.name = "Army"
	army.add_theme_constant_override("separation", 18)
	tabs.add_child(army)
	roster = ItemList.new()
	roster.custom_minimum_size.y = 160
	army.add_child(roster)
	roster.item_selected.connect(func(index): ArmySystem.select_squad(index))
	var enlistment := HBoxContainer.new()
	army.add_child(enlistment)
	unit_choice = OptionButton.new()
	enlistment.add_child(unit_choice)
	for id in ArmySystem.UNIT_IDS:
		var data: Resource = ArmySystem.unit_data(id)
		unit_choice.add_item(LocalizationManager.get_string(data.name_key) + " · " + str(data.recruit_gold))
	recruit_count = SpinBox.new()
	recruit_count.min_value = 1
	recruit_count.max_value = 50
	recruit_count.value = 3
	enlistment.add_child(recruit_count)
	button(enlistment, "ui.recruit", func():
		var ok: bool = ArmySystem.recruit(ArmySystem.UNIT_IDS[unit_choice.selected], int(recruit_count.value))
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
		refresh()
	)
	var orders := HBoxContainer.new()
	army.add_child(orders)
	for order in ArmySystem.ORDERS:
		button(orders, "order." + order, func(): ArmySystem.issue_order_to_selected(order); refresh())
	var formations := HBoxContainer.new()
	army.add_child(formations)
	for formation in ArmySystem.FORMATIONS:
		button(formations, "formation." + formation, func(): ArmySystem.set_formation_for_selected(formation); refresh())
	button(formations, "ui.disband", func(): ArmySystem.disband_selected(); refresh())
	upkeep = Label.new()
	army.add_child(upkeep)
	var relations := VBoxContainer.new()
	relations.name = "Diplomacy"
	relations.add_theme_constant_override("separation", 18)
	tabs.add_child(relations)
	faction_list = ItemList.new()
	faction_list.custom_minimum_size.y = 220
	relations.add_child(faction_list)
	faction_list.item_selected.connect(func(index): selected_faction = FactionSystem.factions.keys()[index]; refresh())
	treaty_choice = OptionButton.new()
	relations.add_child(treaty_choice)
	for id in DiplomacySystem.terms:
		var terms: Dictionary = DiplomacySystem.terms[id]
		treaty_choice.add_item(LocalizationManager.get_string("ui.treaty_terms", {"treaty": LocalizationManager.get_string("treaty." + id), "relation": terms.relationship, "gold": terms.gold}))
	button(relations, "ui.sign_treaty", func():
		var id: String = DiplomacySystem.terms.keys()[treaty_choice.selected]
		var ok: bool = DiplomacySystem.propose_treaty(selected_faction, id)
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.treaty_failed")
		refresh()
	)
	var gifts := HBoxContainer.new()
	relations.add_child(gifts)
	gift_amount = SpinBox.new()
	gift_amount.min_value = 10
	gift_amount.max_value = 500
	gift_amount.value = 50
	gifts.add_child(gift_amount)
	button(gifts, "ui.gift", func():
		var ok: bool = DiplomacySystem.give_gift(selected_faction, int(gift_amount.value))
		result_label.text = LocalizationManager.get_string("ui.action_done" if ok else "ui.recruit_failed")
		refresh()
	)
	journal = RichTextLabel.new()
	journal.name = "Journal"
	journal.bbcode_enabled = true
	tabs.add_child(journal)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(result_label)
	ArmySystem.roster_changed.connect(refresh)
	FactionSystem.faction_relationship_changed.connect(func(_id, _value): refresh())
	TimeSystem.day_passed.connect(func(_day): refresh())
	EventBus.language_changed.connect(func(_language): localize())
	localize()
	campaign_panels = preload("res://scripts/ui/CampaignPanels.gd").new()
	add_child(campaign_panels)
	campaign_panels.attach(self)
	CampaignSystem.changed.connect(refresh)

func button(parent: Node, key: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	parent.add_child(control)
	control.pressed.connect(func(): AudioManager.play_sound("ui_click"); callback.call())
	return control

func localize() -> void:
	title_label.text = LocalizationManager.get_string("ui.strategy")
	for index in ArmySystem.UNIT_IDS.size():
		var data: Resource = ArmySystem.unit_data(ArmySystem.UNIT_IDS[index])
		unit_choice.set_item_text(index, LocalizationManager.get_string(data.name_key) + " · " + str(data.recruit_gold))
	for index in DiplomacySystem.terms.size():
		var id: String = DiplomacySystem.terms.keys()[index]
		var terms: Dictionary = DiplomacySystem.terms[id]
		treaty_choice.set_item_text(index, LocalizationManager.get_string("ui.treaty_terms", {"treaty": LocalizationManager.get_string("treaty." + id), "relation": terms.relationship, "gold": terms.gold}))
	for control in find_children("*", "Button", true, false):
		if control.has_meta("text_key"):
			control.text = LocalizationManager.get_string(control.get_meta("text_key"))
	tabs.set_tab_title(0, LocalizationManager.get_string("ui.army"))
	tabs.set_tab_title(1, LocalizationManager.get_string("ui.diplomacy"))
	tabs.set_tab_title(2, LocalizationManager.get_string("ui.journal"))
	refresh()

func refresh() -> void:
	if not is_instance_valid(roster):
		return
	for control in find_children("*","Button",true,false):
		var key:String=control.get_meta("text_key","")
		if key.begins_with("order.") or key.begins_with("formation.") or key=="ui.disband":
			control.disabled=ArmySystem.squads.is_empty()
			control.tooltip_text=LocalizationManager.get_string("ui.recruit_first") if control.disabled else ""
	roster.clear()
	for squad in ArmySystem.squads:
		var data = load(squad.unit_res_path)
		roster.add_item(LocalizationManager.get_string(data.name_key) + " · " + str(squad.count) + " · " + LocalizationManager.get_string("ui.morale") + " " + str(int(squad.morale)) + " · " + LocalizationManager.get_string("order." + squad.order))
	if not ArmySystem.squads.is_empty():
		roster.select(clampi(ArmySystem.selected_squad_index, 0, ArmySystem.squads.size() - 1))
	var costs: Dictionary = ArmySystem.get_upkeep()
	upkeep.text = LocalizationManager.get_string("ui.army_upkeep", {"food": snappedf(costs.food, 0.1), "gold": snappedf(costs.gold, 0.1), "workers": PopulationSystem.available_workers})
	faction_list.clear()
	for id in FactionSystem.factions:
		var faction: Dictionary = FactionSystem.factions[id]
		var data = load(faction.res_path)
		faction_list.add_item(LocalizationManager.get_string(data.name_key) + " · " + str(int(faction.relationship)) + " · " + LocalizationManager.get_string("ui.threat") + " " + str(int(faction.threat)) + " · " + str(faction.escalation_level) + "/5")
	var index: int = FactionSystem.factions.keys().find(selected_faction)
	if index >= 0:
		faction_list.select(index)
	journal.text = "[b]" + LocalizationManager.get_string("ui.journal") + "[/b]\n\n"
	for id in QuestSystem.active_quests:
		var quest = load("res://data/quests/" + id + ".tres")
		if quest:
			journal.text += "[b]" + LocalizationManager.get_string(quest.title_key) + "[/b]\n" + LocalizationManager.get_string(quest.desc_key) + "\n\n"
	if CampaignSystem.active:
		journal.text = "[b]" + LocalizationManager.get_string("ui.campaign_progress", {"quests": CampaignSystem.completed.size(), "regions": CampaignSystem.reports.size()}) + "[/b]\n\n"
		for quest in CampaignSystem.active_quests():
			journal.text += "[b]" + LocalizationManager.get_string(quest.title) + "[/b]\n" + LocalizationManager.get_string(quest.description) + "\n\n"
		if not CampaignSystem.companions.is_empty():
			journal.text += "[b]" + LocalizationManager.get_string("ui.companions") + "[/b]\n"
			for id in CampaignSystem.companions:
				journal.text += LocalizationManager.get_string("companion." + id + ".name") + "\n"

func show_tab(index: int) -> void:
	tabs.current_tab = index
	refresh()
	show()
