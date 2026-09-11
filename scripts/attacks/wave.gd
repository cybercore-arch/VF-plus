extends Node

# В кастомный паттерн автоматически передается bullet_scene из pattern_manager
var bullet_scene: PackedScene

# Метод execute вызывается при наступлении события в таймлайне JSON
func execute(event: Dictionary) -> void:
	var count = int(event.get("count", 8))
	var speed = float(event.get("speed", 220.0))
	var screen_size = get_viewport().get_visible_rect().size
	
	# Волна пуль, расходящихся сверху вниз
	for i in range(count):
		var x = (screen_size.x / float(count + 1)) * float(i + 1)
		var spawn_pos = Vector2(x, -10.0)
		var dir = Vector2.DOWN
		create_bullet(spawn_pos, dir, speed)

# Для режима "All Stars" (рандом): если этот метод есть, random.gd возьмет параметры отсюда!
func get_random_params() -> Dictionary:
	return {
		"count": randi_range(6, 12),
		"speed": randf_range(180.0, 260.0)
	}

func create_bullet(pos: Vector2, dir: Vector2, speed: float) -> void:
	if bullet_scene == null:
		bullet_scene = load("res://scenes/bullet.tscn")
		
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = pos
	bullet.direction = dir
	bullet.speed = speed
