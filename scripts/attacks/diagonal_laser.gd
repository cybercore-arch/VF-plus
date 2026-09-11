extends Node

const LaserScene = preload("res://scenes/laser.tscn")

func execute(event: Dictionary) -> void:
	var mode = event.get("mode", "cross") # "slash", "backslash", "cross", "corner_sweep", "star"
	var warn_dur = event.get("warn_duration", 1.0)
	var laser_dur = event.get("laser_duration", 2.2)
	var count = event.get("count", 3)
	var spacing = event.get("spacing", 180.0)
	var width = event.get("width", 6.0)
	
	var screen_size = get_viewport().get_visible_rect().size
	var center = screen_size / 2.0
	
	match mode:
		"slash":
			# Диагонали снизу-слева наверх-направо (/)
			spawn_parallel_diagonals(center, Vector2(1, -1).normalized(), count, spacing, warn_dur, laser_dur, width)
			
		"backslash":
			# Диагонали сверху-слева вниз-направо (\)
			spawn_parallel_diagonals(center, Vector2(1, 1).normalized(), count, spacing, warn_dur, laser_dur, width)
			
		"cross":
			# Крест-накрест (X)
			spawn_parallel_diagonals(center, Vector2(1, 1).normalized(), count, spacing, warn_dur, laser_dur, width)
			spawn_parallel_diagonals(center, Vector2(1, -1).normalized(), count, spacing, warn_dur, laser_dur, width)
			
		"corner_sweep":
			# Лазеры из всех 4 углов экрана в центр
			spawn_corner_sweeps(screen_size, warn_dur, laser_dur, width)
			
		"star":
			# Звезда: 2 диагонали + прямой вертикальный и горизонтальный лазер через центр (+)
			spawn_star(center, warn_dur, laser_dur, width)

# Спавн параллельных диагональных линий
func spawn_parallel_diagonals(center: Vector2, dir: Vector2, count: int, spacing: float, warn: float, dur: float, w: float) -> void:
	var perp = Vector2(-dir.y, dir.x)
	var start_idx = -int(count / 2)
	
	for i in range(count):
		var offset = (start_idx + i) * spacing
		var origin = center + perp * offset
		fire_laser(origin, dir, warn, dur, w)

# Лучи из 4-х углов экрана
func spawn_corner_sweeps(screen_size: Vector2, warn: float, dur: float, w: float) -> void:
	var corners = [
		Vector2(0, 0),
		Vector2(screen_size.x, 0),
		Vector2(screen_size.x, screen_size.y),
		Vector2(0, screen_size.y)
	]
	var center = screen_size / 2.0
	for c in corners:
		var dir = (center - c).normalized()
		fire_laser(c, dir, warn, dur, w)

# Звезда (диагонали + крест)
func spawn_star(center: Vector2, warn: float, dur: float, w: float) -> void:
	fire_laser(center, Vector2(1, 0), warn, dur, w)
	fire_laser(center, Vector2(0, 1), warn, dur, w)
	fire_laser(center, Vector2(1, 1).normalized(), warn, dur, w)
	fire_laser(center, Vector2(1, -1).normalized(), warn, dur, w)

# Функция запуска лазера с корректным предупреждением и таймером
func fire_laser(origin: Vector2, dir: Vector2, warn: float, dur: float, w: float) -> void:
	var laser = LaserScene.instantiate()
	laser.target_width = w
	get_tree().current_scene.add_child(laser)
	laser.setup(origin, dir)
	
	run_laser_sequence(laser, warn, dur)

func run_laser_sequence(laser: Node, warn: float, dur: float) -> void:
	laser.warn(warn)
	await get_tree().create_timer(warn).timeout
	if is_instance_valid(laser) and laser.is_inside_tree():
		laser.activate(dur)