extends Node

@export var bullet_scene: PackedScene = preload("res://scenes/bullet.tscn")
@onready var player_node = get_tree().get_first_node_in_group("player")

func execute(event: Dictionary):
	var raw_x = event.get("start_x", "center")
	var raw_y = event.get("start_y", 0.0)
	var speed = event.get("speed", 400.0)

	var start_x = get_pos_value(raw_x, false)
	var start_y = get_pos_value(raw_y, true)
	var start_pos = Vector2(start_x, start_y)

	var target_pos = Vector2.ZERO
	if player_node and is_instance_valid(player_node):
		target_pos = player_node.global_position
	else:
		target_pos = Vector2(start_pos.x, start_pos.y + 100.0)

	var dir = start_pos.direction_to(target_pos)
	create_bullet(start_pos, dir, speed)

func create_bullet(pos: Vector2, dir: Vector2, speed: float):
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = pos
	if "direction" in bullet:
		bullet.direction = dir
	if "speed" in bullet:
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
				if is_y:
					# только верхний или нижний край
					return 0.0 if randf() > 0.5 else screen_size.y
				else:
					# вся ширина/высота экрана по краю
					return randf_range(0.0, screen_size.x)
	return 0.0
