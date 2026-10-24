extends SceneTree

func _initialize() -> void:
	var valid: bool = ProjectSettings.get_setting("application/config/name") == "Marchland Oaths"
	valid = valid and OS.get_user_data_dir().get_file() == "Oaths of the March"
	print("IDENTITY RESULT: ", "PASS" if valid else "FAIL", " path=", OS.get_user_data_dir())
	quit(0 if valid else 1)
