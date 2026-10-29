extends PanelContainer
## Shared council contract keeps the map/workshop adapter independent of StrategyUI.
const UITheme=preload("res://scripts/ui/MarchTheme.gd")
var tabs:TabContainer

func button(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	# Actions sit at their natural width instead of stretching into full-bleed slabs.
	control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	control.custom_minimum_size = Vector2(0, 56)
	control.add_theme_font_size_override("font_size", 20)
	parent.add_child(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

