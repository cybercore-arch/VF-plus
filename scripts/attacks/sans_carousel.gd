extends Node

const LaserScene = preload("res://scenes/laser.tscn")

func execute(event: Dictionary) -> void:
	var center_x_raw = event.get("center_x", "center")
	var center_y_raw = event.get("center_y", "center")
	var radius = event.get("radius", 260.0)
	var count = event.get("count", 18)
	var step_delay = event.get("step_delay", 0.18)
	var warn_dur = event.get("warn_duration", 0.6)
	var laser_dur = event.get("laser_duration", 0.45)
	var width = event.get("width", 7.0)
	var clockwise = event.get("clockwise", true)
	var start_angle_deg = event.get("start_angle", 0.0)
	var angle_step = event.get("angle_step", 20.0)
	var target_offset = event.get("target_offset", 0.0)
	
	var screen_size = get_viewport().get_visible_rect().size
	var center_x = screen_size.x / 2.0 if str(center_x_raw) == "center" else float(center_x_raw)
	var center_y = screen_size.y / 2.0 if str(center_y_raw) == "center" else float(center_y_raw)
	var center = Vector2(center_x, center_y)
	
	run_carousel(center, radius, count, step_delay, warn_dur, laser_dur, width, clockwise, start_angle_deg, angle_step, target_offset)

func run_carousel(center: Vector2, radius: float, count: int, step_delay: float, warn_dur: float, laser_dur: float, width: float, clockwise: bool, start_angle_deg: float, angle_step: float, target_offset: float) -> void:
	var current_angle = start_angle_deg
	var dir_mult = 1.0 if clockwise else -1.0
	
	for i in range(count):
		if not is_inside_tree():
			return
			
		var rad = deg_to_rad(current_angle)
		var blaster_pos = center + Vector2(cos(rad), sin(rad)) * radius
		
		var target_point = center
		if target_offset != 0.0:
			var tangent = Vector2(-sin(rad), cos(rad)) * dir_mult
			target_point += tangent * target_offset
			
		var shoot_dir = (target_point - blaster_pos).normalized()
		
		fire_blaster_laser(blaster_pos, shoot_dir, warn_dur, laser_dur, width)
		
		current_angle += angle_step * dir_mult
		
		await get_tree().create_timer(step_delay).timeout

func fire_blaster_laser(origin: Vector2, dir: Vector2, warn: float, dur: float, w: float) -> void:
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
