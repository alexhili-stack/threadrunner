extends SceneTree


func _initialize() -> void:
	var text: String = (
		"GODOT ENGINE\n\n" + Engine.get_license_text() + "\n\nTHIRD-PARTY COMPONENTS\n"
	)
	for item: Dictionary in Engine.get_copyright_info():
		text += "\n" + JSON.stringify(item, "\t") + "\n"
	text += "\nLICENSE TEXTS\n" + JSON.stringify(Engine.get_license_info(), "\t")
	DirAccess.make_dir_recursive_absolute("res://third_party/godot")
	var file: FileAccess = FileAccess.open("res://third_party/godot/NOTICES.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	quit()
