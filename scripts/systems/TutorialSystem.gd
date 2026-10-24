extends Node

# The repository contains a Stage 3 test location, not the full campaign.
# These goals give its existing mechanics an explicit, persistent ending.
var enemy_defeated: bool = false
var potion_brewed: bool = false
var completed: bool = false

func _ready() -> void:
	EventBus.enemy_died.connect(func(_enemy): enemy_defeated = true; refresh())
	EventBus.potion_brewed.connect(func(_recipe): potion_brewed = true; refresh())
	EventBus.equipment_updated.connect(refresh)
	EventBus.settlement_updated.connect(refresh)
	EventBus.language_changed.connect(func(_lang): refresh())
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
	var progress := get_progress()
	var all_done := true
	var text := LocalizationManager.get_string("tutorial.campaign_title" if CampaignSystem.active else "tutorial.title") + "\n"
	for goal in progress:
		all_done = all_done and progress[goal]
		text += ("✓ " if progress[goal] else "□ ") + LocalizationManager.get_string("tutorial." + goal) + "\n"
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
