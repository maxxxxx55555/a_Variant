extends "res://scripts/ai/Enemy.gd"

@export var boss_name_key: String = "boss.bandit_leader.name"
@export var enraged_damage_mult: float = 1.5

var is_enraged: bool = false

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp -= amount
	# AudioManager owns and recycles the spatial voice.
	@warning_ignore("return_value_discarded")
	AudioManager.play_at("enemy_hurt", global_position)

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
	# AudioManager owns and recycles the spatial voice.
	@warning_ignore("return_value_discarded")
	AudioManager.play_at("enemy_death", global_position)
	EventBus.enemy_died.emit(self)

	var boss_title:String= LocalizationManager.get_string(boss_name_key)
	var msg_template:String= LocalizationManager.get_string("msg.boss_defeated")
	EventBus.notification_posted.emit(msg_template.replace("{boss}", boss_title), false)
	queue_free()
