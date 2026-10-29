extends PanelContainer
## Shared council contract keeps the map/workshop adapter independent of StrategyUI.
var tabs:TabContainer
const IconView=preload("res://scripts/ui/IconSet.gd")
const MotionView=preload("res://scripts/ui/UIMotion.gd")
const ICONS:Dictionary={
	"ui.close":"close","ui.recruit":"army","ui.sign_treaty":"diplomacy","ui.gift":"diplomacy",
	"ui.disband":"army","ui.travel":"map","ui.travel_home":"town","ui.craft":"workshop",
}

static func icon_for(key:String) -> String:
	if ICONS.has(key):return str(ICONS[key])
	if key.begins_with("order.") or key.begins_with("formation."):return "army"
	return ""

func button(parent: Node, key: String, callback: Callable) -> Button:
	var control:Button= Button.new()
	control.text = LocalizationManager.get_string(key)
	control.set_meta("text_key", key)
	parent.add_child(control)
	var icon_name:String=icon_for(key)
	if not icon_name.is_empty():IconView.apply(control,icon_name,20)
	MotionView.attach(control)
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	control.pressed.connect(callback)
	return control

