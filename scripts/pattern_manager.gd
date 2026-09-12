extends Node

signal level_completed

var time_elapsed: float = 0.0
var timeline: Array = []
var is_ended: bool = false

var dynamic_attack_nodes: Dictionary = {}

func _ready() -> void:
	var level_path: String = ""
	
	if Global.current_level_path != "" and FileAccess.file_exists(Global.current_level_path):
		level_path = Global.current_level_path
	else:
		level_path = find_level_path(Global.current_level_file)
		
	load_timeline_from_file(level_path)

func _process(delta: float) -> void:
	if is_ended:
		return
		
	time_elapsed += delta
	
	for i in range(timeline.size() - 1, -1, -1):
		var event = timeline[i]
		
		if time_elapsed >= event.get("time", 0.0):
			var attack_type = str(event.get("type", ""))
			
			if attack_type == "music":
				print("", event)
				var mm = get_node_or_null("/root/MusicManager")
				if mm:
					mm.handle_music_event(event)
				elif Engine.has_singleton("MusicManager"):
					MusicManager.handle_music_event(event)
				else:
					print("")
				timeline.remove_at(i)
				continue
			
			if attack_type == "end":
				trigger_level_end(event)
				timeline.remove_at(i)
				return
				
			var attack_node = get_attack_node(attack_type)
			if attack_node and attack_node.has_method("execute"):
				attack_node.execute(event)
			else:
				print("Ошибка: Модуль атаки '", attack_type, "' не найден")
				
			timeline.remove_at(i)

func trigger_level_end(event: Dictionary) -> void:
	is_ended = true
	var delay = float(event.get("delay", 1.0))
	print("end")
	
	var mm = get_node_or_null("/root/MusicManager")
	if mm:
		mm.stop_song(delay if delay > 0.0 else 0.5)
	
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		
	if is_inside_tree():
		get_tree().call_group("bullet", "deactivate")
		level_completed.emit()

func get_attack_node(attack_type: String) -> Node:
	var existing = get_node_or_null(attack_type)
	if existing:
		return existing
		
	if dynamic_attack_nodes.has(attack_type):
		return dynamic_attack_nodes[attack_type]
		
	var script = find_and_load_pattern_script(attack_type)
	if script != null:
		var node = Node.new()
		node.name = attack_type
		node.set_script(script)
		
		if "bullet_scene" in node and node.bullet_scene == null:
			node.bullet_scene = load("res://scenes/bullet.tscn")
			
		add_child(node)
		dynamic_attack_nodes[attack_type] = node
		print("Динамический паттерн '", attack_type, "' успешно подключен")
		return node
		
	return null

func find_and_load_pattern_script(attack_type: String) -> Script:
	var file_name = attack_type + ".gd"
	for dir in Global.get_pattern_search_dirs():
		var full_path = dir.path_join(file_name)
		if FileAccess.file_exists(full_path):
			var script = load_script_file(full_path)
			if script != null:
				return script
	return null

func load_script_file(path: String) -> Script:
	if path.begins_with("res://"):
		var res = load(path)
		if res is Script:
			return res
			
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var code = file.get_as_text()
			file.close()
			
			var gd_script = GDScript.new()
			gd_script.source_code = code
			var err = gd_script.reload()
			if err == OK:
				return gd_script
			else:
				print("Ошибка компиляции кастомного паттерна '", path, "': код ", err)
	return null

func find_level_path(file_name: String) -> String:
	for dir in Global.get_level_search_dirs():
		var full = dir.path_join(file_name)
		if FileAccess.file_exists(full):
			return full
	return "res://data/".path_join(file_name)

func load_timeline_from_file(file_path: String) -> void:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var err = json.parse(json_text)
			if err == OK:
				var data = json.get_data()
				if data is Array:
					timeline = data
					print("Таймлайн загружен. Всего событий: ", timeline.size(), " (из: ", file_path, ")")
				else:
					print("Ошибка формата")
			else:
				print("Ошибка парсинга JSON: ", json.get_error_message())
	else:
		print("Ошибка: Файл уровня не найден по пути: ", file_path)
