extends PanelContainer
## Shared council contract keeps the map/workshop adapter independent of StrategyUI.
var tabs:TabContainer

func button(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	parent.add_child(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

