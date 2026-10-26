extends Node
# Shared interface instrumentation; action/model sounds remain owned by each game.
var director:Node
var last_focus_ms:int=-1000

func start(audio:Node) -> void:
	director=audio
	process_mode=Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_consider)
	_walk(get_tree().root)

func _walk(node:Node) -> void:
	_consider(node)
	for child in node.get_children():_walk(child)

func _consider(node:Node) -> void:
	if node is Control:call_deferred("_register",weakref(node))

func _register(reference:WeakRef) -> void:
	var control:Control=reference.get_ref()
	if not is_instance_valid(control) or control.has_meta("audio_feedback_registered"):return
	control.set_meta("audio_feedback_registered",true)
	control.focus_entered.connect(_focus.bind(reference))
	if control is BaseButton:
		control.button_down.connect(_arm.bind(reference))
		control.pressed.connect(_finish.bind(reference))
	if control is OptionButton:
		control.item_selected.connect(func(_index):_selection(reference))
	elif control is ItemList:
		control.item_selected.connect(func(_index):_selection(reference))
	elif control is Range:
		control.value_changed.connect(func(_value):
			var live:Control=reference.get_ref()
			if is_instance_valid(live) and live.has_focus():_focus(reference)
		)

func _focus(reference:WeakRef) -> void:
	var control:Control=reference.get_ref()
	if not is_instance_valid(control) or not control.is_visible_in_tree():return
	if control is BaseButton and control.disabled:return
	var now:int=Time.get_ticks_msec()
	if now-last_focus_ms<80:return
	last_focus_ms=now
	director.play_sfx("ui_focus")

func _selection(reference:WeakRef) -> void:
	var control:Control=reference.get_ref()
	if is_instance_valid(control) and control.is_visible_in_tree():director.play_sfx("ui_click")

func _arm(reference:WeakRef) -> void:
	var button:BaseButton=reference.get_ref()
	if is_instance_valid(button):button.set_meta("audio_action_start",director.feedback_serial)

func _finish(reference:WeakRef) -> void:
	var button:BaseButton=reference.get_ref()
	if not is_instance_valid(button) or button.disabled:return
	var serial:int=int(button.get_meta("audio_action_start",director.feedback_serial))
	button.remove_meta("audio_action_start")
	call_deferred("_complete",serial)

func _complete(serial:int) -> void:
	# The accepted action can close/free its own control before this callback.
	if director.feedback_serial==serial:director.play_sfx("ui_click")
