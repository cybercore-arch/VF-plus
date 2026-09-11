extends Node

const LaserScene = preload("res://scenes/laser.tscn")

func execute(event: Dictionary) -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene:
		return
		
	var screen_size: Vector2 = get_tree().get_root().get_viewport().get_visible_rect().size
	if screen_size.x <= 0 or screen_size.y <= 0:
		screen_size = Vector2(1152.0, 648.0)
		
	# 1. Режимы отображения
	var only_vertical = event.get("only_vertical", false)
	var only_horizontal = event.get("only_horizontal", false)
	var mode = event.get("mode", "grid") # "grid", "vertical", "horizontal"
	if mode == "vertical":
		only_vertical = true
	elif mode == "horizontal":
		only_horizontal = true
		
	# Флаг покрытия всего экрана (по умолчанию ВКЛЮЧЁН!)
	var fit_screen: bool = event.get("fit_screen", event.get("fullscreen", true))
	
	# 2. Количество линий
	var cols = get_random_int(event.get("cols", 5), 3, 7)
	var rows = get_random_int(event.get("rows", 4), 3, 6)
	
	# 3. Тайминги и толщина
	var warn_duration = get_random_float(event.get("warn_duration", 1.0), 0.8, 1.5)
	var laser_duration = get_random_float(event.get("laser_duration", 2.5), 1.8, 3.2)
	var width = get_random_float(event.get("width", 6.0), 4.0, 8.0)
	
	# 4. Безопасные проходы (пропуск одного луча для манёвра игрока)
	var safe_col = get_safe_index(event.get("safe_col", -1), cols)
	var safe_row = get_safe_index(event.get("safe_row", -1), rows)
	
	var safe_gap = str(event.get("safe_gap", "none"))
	if safe_gap == "col" or (safe_gap == "random" and randf() > 0.5):
		if safe_col < 0: safe_col = randi() % cols
	elif safe_gap == "row" or safe_gap == "random":
		if safe_row < 0: safe_row = randi() % rows
	elif safe_gap == "both":
		if safe_col < 0: safe_col = randi() % cols
		if safe_row < 0: safe_row = randi() % rows
		
	# 5. Смещение сетки (shift)
	var shift_x = get_random_shift(event.get("shift_x", 0.0), -30.0, 30.0)
	var shift_y = get_random_shift(event.get("shift_y", 0.0), -20.0, 20.0)
	
	# 6. Волна активации (stagger)
	var stagger = get_random_float(event.get("stagger", 0.0), 0.04, 0.12)
	var stagger_mode = str(event.get("stagger_mode", "none")) # "none", "left_to_right", "right_to_left", "top_to_bottom", "random"
	
	# 7. Расчёт координат линий
	var vert_x_coords: Array[float] = []
	var horiz_y_coords: Array[float] = []
	
	if fit_screen:
		# НА ВЕСЬ ЭКРАН: Равномерное деление арены от стены до стены
		var margin_x = float(event.get("margin_x", 0.0))
		var margin_y = float(event.get("margin_y", 0.0))
		
		var usable_w = screen_size.x - 2.0 * margin_x
		var step_x = usable_w / float(cols + 1)
		for i in range(cols):
			if i != safe_col:
				var x = margin_x + step_x * float(i + 1) + shift_x
				vert_x_coords.append(clamp(x, 10.0, screen_size.x - 10.0))
				
		var usable_h = screen_size.y - 2.0 * margin_y
		var step_y = usable_h / float(rows + 1)
		for j in range(rows):
			if j != safe_row:
				var y = margin_y + step_y * float(j + 1) + shift_y
				horiz_y_coords.append(clamp(y, 10.0, screen_size.y - 10.0))
	else:
		# Ручной режим со старым фиксированным spacing (если явно передали fit_screen: false)
		var spacing_x = get_random_float(event.get("spacing_x", 140.0), 100.0, 180.0)
		var spacing_y = get_random_float(event.get("spacing_y", 120.0), 90.0, 160.0)
		var offset_x = event.get("offset_x", "center")
		var offset_y = event.get("offset_y", "center")
		
		var start_x = 0.0
		if typeof(offset_x) == TYPE_STRING and offset_x == "center":
			start_x = (screen_size.x - (cols - 1) * spacing_x) / 2.0
		else:
			start_x = float(offset_x)
			
		var start_y = 0.0
		if typeof(offset_y) == TYPE_STRING and offset_y == "center":
			start_y = (screen_size.y - (rows - 1) * spacing_y) / 2.0
		else:
			start_y = float(offset_y)
			
		for i in range(cols):
			if i != safe_col:
				vert_x_coords.append(start_x + i * spacing_x + shift_x)
		for j in range(rows):
			if j != safe_row:
				horiz_y_coords.append(start_y + j * spacing_y + shift_y)
				
	# 8. Создание узлов лазеров
	var vert_lasers: Array[Node] = []
	var horiz_lasers: Array[Node] = []
	
	if not only_horizontal:
		for x in vert_x_coords:
			var laser = LaserScene.instantiate()
			get_tree().current_scene.add_child(laser)
			laser.setup(Vector2(x, 0.0), Vector2.DOWN)
			laser.target_width = width
			vert_lasers.append(laser)
			
	if not only_vertical:
		for y in horiz_y_coords:
			var laser = LaserScene.instantiate()
			get_tree().current_scene.add_child(laser)
			laser.setup(Vector2(0.0, y), Vector2.RIGHT)
			laser.target_width = width
			horiz_lasers.append(laser)
			
	var all_lasers: Array[Node] = []
	all_lasers.append_array(vert_lasers)
	all_lasers.append_array(horiz_lasers)
	
	# Время предупреждения для всех линий (тонкий красный лазер)
	await get_tree().create_timer(warn_duration).timeout
	if not is_inside_tree():
		return
		
	# 9. Активация смертоносных лучей
	if stagger <= 0.0 or stagger_mode == "none":
		# Мгновенная активация всей сетки разом
		for l in all_lasers:
			if is_instance_valid(l) and l.is_inside_tree():
				l.activate(laser_duration)
	else:
		# Волновое включение
		var activation_order: Array[Node] = []
		if stagger_mode == "left_to_right":
			activation_order.append_array(vert_lasers)
			activation_order.append_array(horiz_lasers)
		elif stagger_mode == "right_to_left":
			var rev_vert = vert_lasers.duplicate()
			rev_vert.reverse()
			activation_order.append_array(rev_vert)
			activation_order.append_array(horiz_lasers)
		elif stagger_mode == "top_to_bottom":
			activation_order.append_array(horiz_lasers)
			activation_order.append_array(vert_lasers)
		elif stagger_mode == "random":
			activation_order.append_array(all_lasers)
			activation_order.shuffle()
		else:
			activation_order.append_array(all_lasers)
			
		for l in activation_order:
			if not is_inside_tree():
				return
			if is_instance_valid(l) and l.is_inside_tree():
				l.activate(laser_duration)
			if stagger > 0.0:
				await get_tree().create_timer(stagger).timeout
			
	# Ожидание окончания лучей
	await get_tree().create_timer(laser_duration).timeout

# ------------------------------------------------------------
# Вспомогательные функции
# ------------------------------------------------------------
func get_random_int(value, min_val: int, max_val: int) -> int:
	if typeof(value) == TYPE_STRING and value == "random":
		return randi_range(min_val, max_val)
	return int(value)

func get_random_float(value, min_val: float, max_val: float) -> float:
	if typeof(value) == TYPE_STRING and value == "random":
		return randf_range(min_val, max_val)
	return float(value)

func get_random_shift(value, min_val: float, max_val: float) -> float:
	if typeof(value) == TYPE_STRING and value == "random":
		return randf_range(min_val, max_val)
	return float(value)

func get_safe_index(val, total_count: int) -> int:
	if typeof(val) == TYPE_STRING and val == "random":
		return randi() % total_count
	var idx = int(val)
	if idx >= 0 and idx < total_count:
		return idx
	return -1
