extends Node2D

@onready var visual_line: Line2D = $VisualLine
@onready var hitbox_area: Area2D = $Hitbox
@onready var col_shape: CollisionShape2D = $Hitbox/CollisionShape2D

var _origin: Vector2
var _dir: Vector2

# Толщина лазера при активации (задаётся из паттерна)
var target_width: float = 8.0
# Радиус поражения будет вычислен автоматически как (радиус_игрока + половина ширины лазера)
# Можно задать вручную через эту переменную (если >0, то используется она)
var custom_hit_radius: float = 0.0

func setup(origin: Vector2, dir: Vector2):
	_origin = origin
	_dir = dir
	var extend = 2000.0
	var p1 = origin - dir * extend
	var p2 = origin + dir * extend

	visual_line.clear_points()
	visual_line.add_point(p1)
	visual_line.add_point(p2)
	visual_line.width = 1.5
	visual_line.default_color = Color(1, 0, 0, 0.4)

	var seg = SegmentShape2D.new()
	seg.a = p1
	seg.b = p2
	col_shape.shape = seg
	col_shape.disabled = true
	hitbox_area.add_to_group("laser")

func warn(duration: float):
	await get_tree().create_timer(duration).timeout

func activate(duration: float):
	col_shape.disabled = false
	visual_line.default_color = Color(1, 0.3, 0.3, 1)
	var tween = create_tween()
	tween.tween_property(visual_line, "width", target_width, 0.1).set_trans(Tween.TRANS_CUBIC)

	# Получаем радиус игрока
	var player = get_tree().get_first_node_in_group("player")
	var player_radius = 5.0  # значение по умолчанию, если не удастся определить
	if player and is_instance_valid(player):
		# Пытаемся найти CollisionShape2D у игрока
		for child in player.get_children():
			if child is CollisionShape2D and child.shape is CircleShape2D:
				player_radius = child.shape.radius
				break
			elif child is CollisionShape2D and child.shape is RectangleShape2D:
				# Для прямоугольника берём половину диагонали или половину ширины/высоты
				var rect = child.shape.size
				player_radius = max(rect.x, rect.y) / 2.0
				break
		# Если не нашли, оставляем 5.0 (можно подогнать под свой спрайт)

	# Вычисляем радиус поражения: половина ширины лазера + радиус игрока
	var hit_radius = target_width / 2.0 + player_radius
	# Если задан custom_hit_radius, используем его вместо вычисленного
	if custom_hit_radius > 0.0:
		hit_radius = custom_hit_radius

	print("Лазер: ширина=", target_width, ", радиус игрока=", player_radius, ", радиус поражения=", hit_radius)

	var screen_size = get_viewport().get_visible_rect().size
	var prev_pos = player.global_position if (player and is_instance_valid(player)) else screen_size / 2
	var start_time = Time.get_ticks_msec() / 1000.0

	while Time.get_ticks_msec() / 1000.0 - start_time < duration:
		if not is_inside_tree():
			return
		if player and is_instance_valid(player) and player.is_alive:
			if "is_god_mode" in player and player.is_god_mode:
				prev_pos = player.global_position
			else:
				var curr_pos = player.global_position
				if point_to_line_dist(curr_pos, _origin, _dir) < hit_radius \
				or segment_crosses_line(prev_pos, curr_pos, _origin, _dir):
					player.die()
					break
				prev_pos = player.global_position
		await get_tree().process_frame

	col_shape.disabled = true
	var fade = create_tween()
	fade.tween_property(visual_line, "width", 0.0, 0.1)
	await fade.finished
	queue_free()

func point_to_line_dist(point: Vector2, lo: Vector2, ld: Vector2) -> float:
	var v = point - lo
	return abs(v.x * ld.y - v.y * ld.x)

func segment_crosses_line(a: Vector2, b: Vector2, lo: Vector2, ld: Vector2) -> bool:
	var da = (a - lo).x * ld.y - (a - lo).y * ld.x
	var db = (b - lo).x * ld.y - (b - lo).y * ld.x
	return da * db < 0.0
