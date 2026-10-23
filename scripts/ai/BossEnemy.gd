extends "res://scripts/ai/Enemy.gd"

@export var boss_name_key: String = "boss.bandit_leader.name"
@export var enraged_damage_mult: float = 1.5

var is_enraged: bool = false

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	if AudioManager: AudioManager.play_sound("enemy_hurt")

	if not is_enraged and current_hp <= (max_hp * 0.5):
		is_enraged = true
		damage *= enraged_damage_mult
		move_speed *= 1.25
		EventBus.notification_posted.emit(LocalizationManager.get_string("msg.boss_enraged"), true)

	EventBus.enemy_damaged.emit(self, amount, current_hp, max_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	if AudioManager: AudioManager.play_sound("enemy_death")
	EventBus.enemy_died.emit(self)

	# Check for quest completion
	if QuestSystem:
		QuestSystem.complete_quest("main_quest_01")

	var boss_title = LocalizationManager.get_string(boss_name_key)
	EventBus.notification_posted.emit(boss_title + " defeated!", false)
	queue_free()
