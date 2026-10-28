extends RefCounted
## Small authored atlas; keys are derived from validated item categories, never paths from a save.
static var cache:Dictionary[String,Texture2D]={}

static func category(id:String,kind:String)->String:
	var key:String=id.to_lower()
	if "sword" in key:return "sword"
	if "dagger" in key:return "dagger"
	if "axe" in key:return "axe"
	if "spear" in key:return "spear"
	if "bow" in key:return "bow"
	if "mace" in key:return "mace"
	if "shield" in key:return "shield"
	if "helmet" in key:return "helmet"
	if "boots" in key or "greaves" in key:return "boots"
	if kind=="armor":return "armor"
	if kind=="potion":
		if "stamina" in key or "vigor" in key or "swift" in key:return "potion_blue"
		if "antidote" in key or "barkskin" in key:return "potion_green"
		if "might" in key or "strength" in key:return "potion_gold"
		return "potion_red"
	if kind=="misc":return "herb"
	return "fallback"

static func texture_for(id:String,kind:String)->Texture2D:
	var key:String=category(id,kind)
	if not cache.has(key):cache[key]=load("res://assets/ui/items/"+key+".svg") as Texture2D
	return cache[key]

static func for_item(item:ItemData)->Texture2D:
	if item==null:return texture_for("","")
	return texture_for(item.id,item.type)

static func for_record(item:Dictionary)->Texture2D:
	return texture_for(str(item.get("id","")),str(item.get("type","")))
