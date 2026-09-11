extends Node

const LaserScene = preload("res://scenes/laser.tscn")

func execute(event: Dictionary) -> void:
	# 1. Количество и частота выстрелов
	var count = int(event.get("count", 14))
	var spawn_interval = float(event.get("spawn_interval", 0.12)) # Пауза между спавном лучей
	var track_duration = float(event.get("track_duration", 0.75)) # Сколько времени луч доворачивает за игроком
	var freeze_delay = float(event.get("freeze_delay", 0.3)) # Пауза после застывания до активации
	var laser_duration = float(event.get("laser_duration", 0.55)) # Длительность активного луча
	var width = float(event.get("width", 7.0)) # Толщина
	var turn_speed = float(event.get("turn_speed", 0.0)) # 0 = идеальное мгновенное слежение, >0 = плавный доворот
	
	# 2. Единая точка истока (все лучи выходят из ОДНОЙ позиции)
	var screen_size = get_viewport().get_visible_rect().size
	var origin_x_raw = event.get("origin_x", "center")
	var origin_y_raw = event.get("origin_y", 80.0) # По умолчанию сверху по центру
	
	var origin_point = Vector2.ZERO
	if str(origin_x_raw) == "center":
		origin_point.x = screen_size.x / 2.0
	elif str(origin_x_raw) == "player":
		var p = get_tree().get_first_node_in_group("player")
		origin_point.x = p.global_position.x if (p and is_instance_valid(p)) else screen_size.x / 2.0
	elif str(origin_x_raw) == "random":
		origin_point.x = randf_range(100.0, screen_size.x - 100.0)
	else:
		origin_point.x = float(origin_x_raw)
		
	if str(origin_y_raw) == "center":
		origin_point.y = screen_size.y / 2.0
	elif str(origin_y_raw) == "player":
		var p = get_tree().get_first_node_in_group("player")
		origin_point.y = p.global_position.y if (p and is_instance_valid(p)) else screen_size.y / 2.0
	elif str(origin_y_raw) == "random":
		origin_point.y = randf_range(60.0, screen_size.y - 60.0)
	else:
		origin_point.y = float(origin_y_raw)
		
	# Запуск очереди из одной точки
	run_swords_barrage(origin_point, count, spawn_interval, track_duration, freeze_delay, laser_duration, width, turn_speed)

func run_swords_barrage(origin: Vector2, count: int, spawn_interval: float, track_dur: float, freeze_delay: float, laser_dur: float, width: float, turn_speed: float) -> void:
	for i in range(count):
		if not is_inside_tree():
			return
			
		spawn_tracking_laser(origin, track_dur, freeze_delay, laser_dur, width, turn_speed)
		await get_tree().create_timer(spawn_interval).timeout

func spawn_tracking_laser(origin: Vector2, track_dur: float, freeze_delay: float, laser_dur: float, width: float, turn_speed: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	var screen_size = get_viewport().get_visible_rect().size
	var target_pos = player.global_position if (player and is_instance_valid(player)) else (screen_size / 2.0)
	var dir = (target_pos - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
		
	var laser = LaserScene.instantiate()
	laser.target_width = width
	get_tree().current_scene.add_child(laser)
	laser.setup(origin, dir)
	
	# Стандартный красный цвет прицела
	if laser.has_node("VisualLine"):
		var vline = laser.get_node("VisualLine") as Line2D
		vline.default_color = Color(1.0, 0.15, 0.15, 0.45)
		vline.width = 1.8
		
	# ФАЗА 1: СЛЕЖЕНИЕ ЗА ИГРОКОМ (TRACKING)
	var elapsed = 0.0
	while elapsed < track_dur:
		if not is_instance_valid(laser) or not laser.is_inside_tree():
			return
			
		if player and is_instance_valid(player) and player.is_alive:
			var curr_target = player.global_position
			var desired_dir = (curr_target - origin).normalized()
			if desired_dir != Vector2.ZERO:
				if turn_speed <= 0.0:
					dir = desired_dir
				else:
					var cur_ang = dir.angle()
					var des_ang = desired_dir.angle()
					var new_ang = rotate_toward(cur_ang, des_ang, turn_speed * get_process_delta_time())
					dir = Vector2.from_angle(new_ang)
					
				laser.setup(origin, dir)
				
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		
	# ФАЗА 2: ЗАСТЫВАНИЕ (FREEZE) — угол зафиксирован, полоса становится ярче
	if is_instance_valid(laser) and laser.has_node("VisualLine"):
		var vline = laser.get_node("VisualLine") as Line2D
		vline.default_color = Color(1.0, 0.25, 0.25, 0.85)
		vline.width = 2.8
		
	await get_tree().create_timer(freeze_delay).timeout
	
	# ФАЗА 3: АКТИВАЦИЯ (ВЫСТРЕЛ ЛАЗЕРА)
	if is_instance_valid(laser) and laser.is_inside_tree():
		laser.activate(laser_dur)
