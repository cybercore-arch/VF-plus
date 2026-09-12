extends Node

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func execute(event: Dictionary):
	var direction_side = event.get("direction", "top") 
	var count = event.get("count", 10)
	var base_speed = event.get("speed", 300.0)
	var speed_random = event.get("speed_random", 50.0) 
	
	
	var screen_size = get_viewport().get_visible_rect().size
	
	
	var spawn_vector = Vector2.ZERO
	var move_dir = Vector2.DOWN 
	var line_length = 0.0
	
	match direction_side:
		"top":
			move_dir = Vector2.DOWN
			spawn_vector.y = -20.0 
			line_length = screen_size.x
		"bottom":
			move_dir = Vector2.UP
			spawn_vector.y = screen_size.y + 20.0 
			line_length = screen_size.x
		"left":
			move_dir = Vector2.RIGHT
			spawn_vector.x = -20.0 
			line_length = screen_size.y
		"right":
			move_dir = Vector2.LEFT
			spawn_vector.x = screen_size.x + 20.0 
			line_length = screen_size.y

	
	var step = line_length / (count + 1)
	
	
	for i in range(count):
		var offset = (i + 1) * step
		var final_spawn_pos = Vector2.ZERO
		
		
		if direction_side == "top" or direction_side == "bottom":
			final_spawn_pos = Vector2(offset, spawn_vector.y)
		else:
			final_spawn_pos = Vector2(spawn_vector.x, offset)
			
		
		var random_offset = randf_range(-speed_random, speed_random)
		var final_speed = base_speed + random_offset
		
		create_bullet(final_spawn_pos, move_dir, final_speed)

func create_bullet(pos: Vector2, dir: Vector2, speed: float):
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = pos
	
	if "direction" in bullet:
		bullet.direction = dir
		
	bullet.speed = speed
