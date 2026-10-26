extends Node

# External quest listeners consume this public signal; retained for saved quest compatibility.
@warning_ignore("unused_signal")
signal quest_completed(quest_id: String)

var active_quests: Array = ["main_quest_01", "side_quest_clear_camp", "companion_quest_01"]
var completed_quests: Array = []

