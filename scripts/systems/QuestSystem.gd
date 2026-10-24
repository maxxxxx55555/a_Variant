extends Node

signal quest_completed(quest_id: String)

var active_quests: Array = ["main_quest_01", "side_quest_clear_camp", "companion_quest_01"]
var completed_quests: Array = []

func complete_quest(quest_id: String) -> bool:
	if quest_id in active_quests and not (quest_id in completed_quests):
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)

		var res_path = "res://data/quests/" + quest_id + ".tres"
		if FileAccess.file_exists(res_path):
			var res = load(res_path)
			if res:
				if EconomySystem:
					EconomySystem.stockpiles["gold"] = EconomySystem.stockpiles.get("gold", 0.0) + res.reward_gold
				var title = LocalizationManager.get_string(res.title_key)
				EventBus.notification_posted.emit(LocalizationManager.get_string("msg.quest_completed", {
					"title": title,
					"gold": str(res.reward_gold),
					"exp": str(res.reward_exp)
				}), false)

		quest_completed.emit(quest_id)
		return true
	return false

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests
