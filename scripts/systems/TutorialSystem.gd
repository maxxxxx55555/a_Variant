extends Node

# The repository contains a Stage 3 test location, not the full campaign.
# These goals give its existing mechanics an explicit, persistent ending.
var enemy_defeated: bool = false
var potion_brewed: bool = false
var completed: bool = false

func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.enemy_died.connect(func(_enemy:Variant)->void: enemy_defeated = true; refresh())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.potion_brewed.connect(func(_recipe:Variant)->void: potion_brewed = true; refresh())
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.equipment_updated.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.settlement_updated.connect(refresh)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(func(_lang:Variant)->void: refresh())
	refresh()

func get_progress() -> Dictionary:
	return {
		"weapon": GameState.equipment.get("weapon") != null,
		"armor": GameState.equipment.get("torso") != null,
		"combat": enemy_defeated,
		"alchemy": potion_brewed,
		"settlement": EconomySystem.stockpiles.food > 0 and EconomySystem.get_food_days_remaining() == 999
	}

func refresh() -> void:
	var progress:Dictionary= get_progress()
	var all_done:bool= true
	var text:String= LocalizationManager.get_string("tutorial.campaign_title" if CampaignSystem.active else "tutorial.title") + "\n"
	for goal:String in progress:
		all_done = all_done and progress[goal]
		text += LocalizationManager.get_string("tutorial.done" if progress[goal] else "tutorial.pending") + " · " + LocalizationManager.get_string("tutorial." + goal) + "\n"
	completed = completed or all_done
	if completed:
		text += "\n" + LocalizationManager.get_string("tutorial.basics_complete" if CampaignSystem.active else "tutorial.completed")
	EventBus.tutorial_updated.emit(text, completed)

func get_state() -> Dictionary:
	return {"enemy_defeated": enemy_defeated, "potion_brewed": potion_brewed, "completed": completed}

func restore_state(data: Dictionary) -> void:
	enemy_defeated = data.get("enemy_defeated", false)
	potion_brewed = data.get("potion_brewed", false)
	completed = data.get("completed", false)
	refresh()
