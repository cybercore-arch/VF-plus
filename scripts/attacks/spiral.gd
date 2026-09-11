extends Node

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func execute(event: Dictionary):
	var spawn_x = get_pos_value(event["spawn_x"], false)
	var spawn_y = get_pos_value(event["spawn_y"], true)
	var spawn_pos = Vector2(spawn_x, spawn_y)

	await show_warning(spawn_pos)

	run_spiral_logic(
		spawn_pos,
		event["speed"],
		event["duration"],
		event["step_delay"],
		event.get("angle_step", 15.0)
	)

func show_warning(pos: Vector2):
	var container = Node2D.new()
	container.global_position = pos
	get_tree().current_scene.add_child(container)

	var h = ColorRect.new()
	h.size = Vector2(30, 4)
	h.position = Vector2(-15, -2)
	h.color = Color(1, 0.3, 0.3)
	container.add_child(h)

	var v = ColorRect.new()
	v.size = Vector2(4, 30)
	v.position = Vector2(-2, -15)
	v.color = Color(1, 0.3, 0.3)
	container.add_child(v)

	var tween = container.create_tween().set_loops(4)
	tween.tween_property(container, "modulate:a", 0.1, 0.12)
	tween.tween_property(container, "modulate:a", 1.0, 0.12)

	await get_tree().create_timer(1.0).timeout
	container.queue_free()

func run_spiral_logic(pos: Vector2, speed: float, duration: float, delay: float, angle_step: float):
	var start_time = Time.get_ticks_msec() / 1000.0
	var current_angle = 0.0

	while (Time.get_ticks_msec() / 1000.0) - start_time < duration:
		if not is_inside_tree(): return
		var dir = Vector2.from_angle(deg_to_rad(current_angle))
		create_bullet(pos, dir, speed)
		current_angle = fmod(current_angle + angle_step, 360.0)
		await get_tree().create_timer(delay).timeout

func create_bullet(pos: Vector2, dir: Vector2, speed: float):
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = pos
	if "direction" in bullet:
		bullet.direction = dir
	bullet.speed = speed

func get_pos_value(val, is_y: bool) -> float:
	if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
		return float(val)
	if typeof(val) == TYPE_STRING:
		var screen_size = get_viewport().get_visible_rect().size
		match val:
			"center":
				return screen_size.y / 2.0 if is_y else screen_size.x / 2.0
			"random":
				return randf_range(50.0, screen_size.y - 50.0) if is_y else randf_range(50.0, screen_size.x - 50.0)
	return float(val)
