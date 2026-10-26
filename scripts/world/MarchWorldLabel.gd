extends Label3D
## Node-bound locale subscription disconnects automatically when this world label is freed.
func _ready() -> void:
	# This signal is wired once per owning node; lifecycle and navigation tests cover teardown.
	@warning_ignore("return_value_discarded")
	EventBus.language_changed.connect(refresh_copy)
func refresh_copy(_language:String="") -> void:
	var key:String=get_meta("locale_key","")
	if not key.is_empty():text=LocalizationManager.get_string(key)+str(get_meta("locale_suffix",""))
