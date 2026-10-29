extends RefCounted

const DURATION:float=0.16
const REVEAL_DURATION:float=0.18
const HOVER_SCALE:float=1.02

static func attach(button:Button) -> void:
	if button.has_meta("ui_motion"):
		return
	button.set_meta("ui_motion",true)
	@warning_ignore("return_value_discarded")
	button.mouse_entered.connect(func()->void: _scale(button,HOVER_SCALE))
	@warning_ignore("return_value_discarded")
	button.mouse_exited.connect(func()->void: _scale(button,1.0))
	@warning_ignore("return_value_discarded")
	button.focus_entered.connect(func()->void: _scale(button,HOVER_SCALE))
	@warning_ignore("return_value_discarded")
	button.focus_exited.connect(func()->void: _scale(button,1.0))

static func _scale(button:Button, factor:float) -> void:
	if SettingsManager.reduced_motion:
		button.scale=Vector2.ONE
		return
	button.pivot_offset=button.size*0.5
	var tween:Tween=button.create_tween()
	tween=tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	@warning_ignore("return_value_discarded")
	tween.tween_property(button,"scale",Vector2.ONE*factor,DURATION)

static func reveal(control:Control) -> void:
	if SettingsManager.reduced_motion:
		control.modulate=Color.WHITE
		return
	control.modulate.a=0.0
	var tween:Tween=control.create_tween()
	tween=tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	@warning_ignore("return_value_discarded")
	tween.tween_property(control,"modulate:a",1.0,REVEAL_DURATION)
