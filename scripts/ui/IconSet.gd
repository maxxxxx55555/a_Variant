extends RefCounted

const DIR:String="res://assets/ui/icons/"
const NAMES:Array[String]=["inventory","potion","food","diplomacy","siege","objective","codex","settings","sound","language","stats","credits","continue","new_campaign","save","load","exit","close","map","army","workshop","journal","town","road","explored","player","selection","pause","quest","faction","oath","tier","building_farm","building_housing","building_infirmary","building_well","building_market","building_sawmill","building_quarry","building_forge","building_barracks","building_hall","slot_head","slot_torso","slot_legs","slot_weapon"]

static var _cache:Dictionary={}

static func texture(icon_name:String) -> Texture2D:
	if _cache.has(icon_name):
		@warning_ignore("unsafe_cast")
		var cached:Texture2D = _cache[icon_name] as Texture2D
		return cached
	var picture:Texture2D=load(DIR+icon_name+".svg") as Texture2D
	_cache[icon_name]=picture
	return picture

static func apply(button:Button, icon_name:String, size:int=26) -> void:
	var picture:Texture2D=texture(icon_name)
	if picture==null:
		return
	button.icon=picture
	button.expand_icon=true
	button.add_theme_constant_override("icon_max_width",size)

static func rect(icon_name:String, tint:Color, size:Vector2, label_name:String="") -> TextureRect:
	var view:TextureRect=TextureRect.new()
	view.name=label_name if not label_name.is_empty() else icon_name.capitalize()+"Icon"
	view.texture=texture(icon_name)
	view.modulate=tint
	view.custom_minimum_size=size
	view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return view
