extends RefCounted

const ThemeRef=preload("res://scripts/ui/MarchTheme.gd")
const FALLBACK:Color=Color("72968b")

static func color(faction_id:String) -> Color:
	var tree:SceneTree=Engine.get_main_loop() as SceneTree
	if tree==null:
		return FALLBACK
	var campaign:Node=tree.root.get_node_or_null("CampaignSystem")
	if campaign==null:
		return FALLBACK
	var definition:Variant=campaign.get("definition")
	if not definition is Dictionary:
		return FALLBACK
	@warning_ignore("unsafe_cast")
	var rows:Variant=(definition as Dictionary).get("factions",[])
	if not rows is Array:
		return FALLBACK
	@warning_ignore("unsafe_cast")
	for faction:Variant in rows as Array:
		if not faction is Dictionary:
			continue
		@warning_ignore("unsafe_cast")
		var row:Dictionary=faction as Dictionary
		if str(row.get("id",""))==faction_id:
			return Color(str(row.get("color","#72968b")))
	return FALLBACK

static func text_color(faction_id:String) -> Color:
	return ThemeRef.accent_text(color(faction_id))
