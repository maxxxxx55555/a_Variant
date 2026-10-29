extends RefCounted

const COLORS: Dictionary[String, Color] = {
	"common": Color("C8CDD2"),
	"uncommon": Color("7FB069"),
	"rare": Color("5B84C4"),
	"epic": Color("9A6CC4"),
	"legendary": Color("C9A227")
}

static func color_of(rarity: String) -> Color:
	return COLORS.get(rarity, COLORS["common"])

static func rarity_of(item: Variant) -> String:
	if item == null:
		return "common"
	var rarity: String = ""
	if item is Dictionary:
		# Inventory records carry validated rarity ids from shipped item data.
		@warning_ignore("unsafe_cast")
		var record: Dictionary = item
		rarity = str(record.get("rarity", ""))
	elif item is ItemData:
		# ItemData is the authored resource type; the type check above proves the cast.
		@warning_ignore("unsafe_cast")
		var data: ItemData = item
		rarity = data.rarity
	if not COLORS.has(rarity):
		return "common"
	return rarity

static func color_for(item: Variant) -> Color:
	return color_of(rarity_of(item))
