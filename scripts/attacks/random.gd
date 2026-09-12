extends Node

@onready var pattern_manager = get_parent()

func execute(event: Dictionary):
	var delay = event.get("delay", 2.0)
	var duration = event.get("duration", -1.0)
	run_random_mode(delay, duration)

func run_random_mode(delay: float, duration: float):
	preload_all_available_attacks()
	
	var start_time = Time.get_ticks_msec() / 1000.0
	while duration == -1.0 or (Time.get_ticks_msec() / 1000.0) - start_time < duration:
		if not is_inside_tree():
			return
			
		var pool: Array[Node] = []
		for child in pattern_manager.get_children():
			if child.name != "random" and child.name != "loop" and child.has_method("execute"):
				pool.append(child)
				
		if pool.is_empty():
			print("All Stars: нет доступных атак для выбора!")
			return
			
		var random_node = pool[randi() % pool.size()]
		var type_name = str(random_node.name)
		
		var random_event: Dictionary
		if random_node.has_method("get_random_params"):
			random_event = random_node.get_random_params()
			random_event["type"] = type_name
		else:
			random_event = generate_random_params(type_name)
			
		random_node.execute(random_event)
		
		await get_tree().create_timer(delay).timeout

func preload_all_available_attacks() -> void:
	if not pattern_manager or not pattern_manager.has_method("get_attack_node"):
		return
		
	for dir in Global.get_pattern_search_dirs():
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var d = DirAccess.open(dir)
		if d:
			d.list_dir_begin()
			var file_name = d.get_next()
			while file_name != "":
				if not d.current_is_dir() and file_name.ends_with(".gd"):
					var attack_name = file_name.get_basename()
					if attack_name != "random" and attack_name != "loop":
						pattern_manager.get_attack_node(attack_name)
				file_name = d.get_next()
			d.list_dir_end()

func generate_random_params(type: String) -> Dictionary:
	var data = {"type": type}
	var screen_size = get_viewport().get_visible_rect().size
	
	match type:
		"aimed":
			data["start_x"] = "center" if randf() > 0.5 else randf_range(100.0, 500.0)
			data["start_y"] = 0.0
			data["speed"] = randf_range(300.0, 450.0)
			
		"circle":
			data["spawn_x"] = "center" if randf() > 0.4 else randf_range(100.0, screen_size.x - 100.0)
			data["spawn_y"] = "center" if randf() > 0.4 else randf_range(100.0, screen_size.y - 100.0)
			data["count"] = randi_range(8, 16)
			data["speed"] = randf_range(180.0, 250.0)
			
		"spiral":
			data["spawn_x"] = "center" if randf() > 0.4 else randf_range(100.0, screen_size.x - 100.0)
			data["spawn_y"] = "center" if randf() > 0.4 else randf_range(100.0, screen_size.y - 100.0)
			data["speed"] = randf_range(200.0, 300.0)
			data["duration"] = randf_range(2.0, 4.0)
			data["step_delay"] = randf_range(0.05, 0.09)
			data["angle_step"] = randf_range(10.0, 25.0)
			
		"rain":
			var sides = ["top", "left", "right"]
			data["direction"] = sides[randi() % sides.size()]
			data["count"] = randi_range(12, 18)
			data["speed"] = randf_range(250.0, 350.0)
			data["speed_random"] = randf_range(40.0, 80.0)
			
		"minefield":
			data["count"] = randi_range(4, 7)
			data["shards"] = randi_range(6, 10)
			data["speed"] = randf_range(200.0, 280.0)
			
		"aimed_laser":
			data["start_x"] = "random"
			data["start_y"] = 0.0 if randf() > 0.5 else screen_size.y
			data["warn_duration"] = randf_range(0.5, 1.5)
			data["laser_duration"] = randf_range(1.0, 2.0)
			data["width"] = randf_range(6.0, 12.0)
			
		"laser_grid":
			data["cols"] = randi_range(4, 7)
			data["rows"] = randi_range(4, 7)
			data["spacing_x"] = randf_range(100.0, 160.0)
			data["spacing_y"] = randf_range(90.0, 140.0)
			data["offset_x"] = "center"
			data["offset_y"] = "center"
			data["warn_duration"] = randf_range(0.8, 1.5)
			data["laser_duration"] = randf_range(0.3, 1.5)
			data["width"] = randf_range(4.0, 8.0)
			if randf() > 0.7:
				data["only_vertical"] = true
				data["only_horizontal"] = false
			elif randf() > 0.7:
				data["only_vertical"] = false
				data["only_horizontal"] = true
			else:
				data["only_vertical"] = false
				data["only_horizontal"] = false
				
		_:
			data["count"] = randi_range(8, 16)
			data["speed"] = randf_range(180.0, 260.0)
			data["spawn_x"] = "center" if randf() > 0.5 else randf_range(60.0, screen_size.x - 60.0)
			data["spawn_y"] = "center" if randf() > 0.5 else randf_range(60.0, screen_size.y - 60.0)
			
	return data
