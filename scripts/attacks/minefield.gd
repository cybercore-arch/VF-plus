extends Node

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")

func execute(event: Dictionary):
	var count = event.get("count", 5)
	var base_speed = event.get("speed", 200.0)
	var shards_count = event.get("shards", 8)

	var screen_size = get_viewport().get_visible_rect().size

	var positions = []
	for i in range(count):
		positions.append(Vector2(
			randf_range(50.0, screen_size.x - 50.0),
			randf_range(50.0, screen_size.y - 50.0)
		))

	for pos in positions:
		show_warning(pos)

	await get_tree().create_timer(0.5).timeout

	for pos in positions:
		spawn_mine(pos, shards_count, base_speed)

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

	var tween = container.create_tween().set_loops(2)
	tween.tween_property(container, "modulate:a", 0.1, 0.12)
	tween.tween_property(container, "modulate:a", 1.0, 0.12)

	await get_tree().create_timer(0.5).timeout
	container.queue_free()

func spawn_mine(pos: Vector2, shards: int, speed: float):
	var mine = bullet_scene.instantiate()
	get_tree().current_scene.add_child(mine)
	mine.global_position = pos
	if "direction" in mine:
		mine.direction = Vector2.ZERO
		mine.speed = 0.0
	trigger_explosion(mine, pos, shards, speed)

func trigger_explosion(mine: Node2D, pos: Vector2, shards: int, speed: float):
	var tween = create_tween().set_loops(3)
	tween.tween_property(mine, "scale", Vector2(1.5, 1.5), 0.25)
	tween.tween_property(mine, "scale", Vector2(0.8, 0.8), 0.25)

	await get_tree().create_timer(1.5).timeout

	if not is_instance_valid(mine): return
	mine.queue_free()

	var angle_step = 360.0 / shards
	for i in range(shards):
		var dir = Vector2.from_angle(deg_to_rad(i * angle_step))
		var shard = bullet_scene.instantiate()
		get_tree().current_scene.add_child(shard)
		shard.global_position = pos
		if "direction" in shard:
			shard.direction = dir
		shard.speed = speed
