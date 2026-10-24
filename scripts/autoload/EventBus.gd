extends Node

# Core signals
signal player_hp_changed(current_hp: float, max_hp: float)
signal player_stamina_changed(current_stamina: float, max_stamina: float)
signal player_died()
signal item_picked_up(item_data: Resource, count: int)
signal inventory_updated()
signal equipment_updated()
signal notification_posted(text: String, is_warning: bool)
signal language_changed(new_lang: String)
signal game_paused(is_paused: bool)
signal enemy_damaged(enemy_node: Node, damage: float, current_hp: float, max_hp: float)
signal enemy_died(enemy_node: Node)
signal potion_brewed(recipe: Resource)
signal settlement_updated()
signal tutorial_updated(text: String, completed: bool)
