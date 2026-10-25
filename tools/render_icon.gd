extends SceneTree
func _initialize() -> void:
	var image:=Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"),1.0)!=OK:
		push_error("Application vector icon cannot render")
		quit(1)
		return
	image.resize(512,512,Image.INTERPOLATE_LANCZOS)
	var result:=image.save_png("res://assets/ui/app-icon.png")
	print("ICON RENDER RESULT: ","PASS" if result==OK else "FAIL")
	quit(0 if result==OK else 1)
