extends Node

# Core signals
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal player_hp_changed(current_hp: float, max_hp: float)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal player_stamina_changed(current_stamina: float, max_stamina: float)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal player_died()
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal item_picked_up(item_data: Resource, count: int)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal inventory_updated()
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal equipment_updated()
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal notification_posted(text: String, is_warning: bool)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal language_changed(new_lang: String)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal game_paused(is_paused: bool)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal enemy_damaged(enemy_node: Node, damage: float, current_hp: float, max_hp: float)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal enemy_died(enemy_node: Node)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal potion_brewed(recipe: Resource)
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal settlement_updated()
# Public event bus signals are consumed by other nodes, verified by gameplay tests.
@warning_ignore("unused_signal")
signal tutorial_updated(text: String, completed: bool)
