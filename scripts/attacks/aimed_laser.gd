extends Node

const LaserScene = preload("res://scenes/laser.tscn")

func execute(event: Dictionary):
	var start_x = get_pos_value(event.get("start_x", "center"), false)
	var start_y = get_pos_value(event.get("start_y", 0.0), true)
	var warn_duration = event.get("warn_duration", 1.5)
	var laser_duration = event.get("laser_duration", 1.5)
	fire_laser(Vector2(start_x, start_y), warn_duration, laser_duration)

func fire_laser(origin: Vector2, warn_dur: float, laser_dur: float):
	var screen_size = get_viewport().get_visible_rect().size
	var player = get_tree().get_first_node_in_group("player")
	var target = player.global_position if (player and is_instance_valid(player)) else screen_size / 2
	var dir = (target - origin).normalized()

	var laser = LaserScene.instantiate()
	get_tree().current_scene.add_child(laser)
	laser.setup(origin, dir)

	await laser.warn(warn_dur)
	if not is_inside_tree():
		return
	await laser.activate(laser_dur)

func get_pos_value(val, is_y: bool) -> float:
	if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
		return float(val)
	if typeof(val) == TYPE_STRING:
		var screen_size = get_viewport().get_visible_rect().size
		match val:
			"center":
				return screen_size.y / 2.0 if is_y else screen_size.x / 2.0
			"random":
				if is_y:
					return 0.0 if randf() > 0.5 else screen_size.y
				else:
					return randf_range(0.0, screen_size.x)
	return 0.0
