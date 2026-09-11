extends Node

var current_level_file: String = "circle_test.json"
var current_level_path: String = ""

# Папка для кастомных уровней (.json)
func get_custom_levels_dir() -> String:
	var path: String = ""
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://levels/")
	elif OS.has_feature("android"):
		# На Android создаем папку в общедоступных Документах: Documents/VF+/levels/
		var doc_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		if doc_dir != "" and doc_dir != null:
			path = doc_dir.path_join("VF+").path_join("levels") + "/"
		else:
			path = ProjectSettings.globalize_path("user://levels/")
	else:
		path = OS.get_executable_path().get_base_dir().path_join("levels") + "/"
		
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	return path

# Папка для кастомных скриптов атак (.gd)
func get_custom_patterns_dir() -> String:
	var path: String = ""
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://patterns/")
	elif OS.has_feature("android"):
		var doc_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		if doc_dir != "" and doc_dir != null:
			path = doc_dir.path_join("VF+").path_join("patterns") + "/"
		else:
			path = ProjectSettings.globalize_path("user://patterns/")
	else:
		path = OS.get_executable_path().get_base_dir().path_join("patterns") + "/"
		
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	return path

func get_user_downloads_dir() -> String:
	var path = "user://downloaded_levels/"
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	return path

func get_user_patterns_dir() -> String:
	var path = "user://patterns/"
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	return path

func get_level_search_dirs() -> Array[String]:
	var dirs: Array[String] = []
	if DirAccess.dir_exists_absolute("res://data/"):
		dirs.append("res://data/")
	if DirAccess.dir_exists_absolute("res://levels/"):
		dirs.append("res://levels/")
		
	var custom_dir = get_custom_levels_dir()
	if not dirs.has(custom_dir):
		dirs.append(custom_dir)
		
	var dl_dir = get_user_downloads_dir()
	if not dirs.has(dl_dir):
		dirs.append(dl_dir)
		
	var user_levels = "user://levels/"
	if DirAccess.dir_exists_absolute(user_levels) and not dirs.has(user_levels):
		dirs.append(user_levels)
		
	return dirs

func get_pattern_search_dirs() -> Array[String]:
	var dirs: Array[String] = []
	if DirAccess.dir_exists_absolute("res://scripts/attacks/"):
		dirs.append("res://scripts/attacks/")
	if DirAccess.dir_exists_absolute("res://patterns/"):
		dirs.append("res://patterns/")
		
	var custom_p = get_custom_patterns_dir()
	if not dirs.has(custom_p):
		dirs.append(custom_p)
		
	var user_p = get_user_patterns_dir()
	if not dirs.has(user_p):
		dirs.append(user_p)
		
	return dirs

func open_folder_in_os(folder_path: String) -> String:
	var real_path = ProjectSettings.globalize_path(folder_path)
	if OS.has_feature("android"):
		DisplayServer.clipboard_set(real_path)
		print("Путь скопирован в буфер: ", real_path)
		return real_path
	else:
		OS.shell_open(real_path)
		return real_path
