extends Area2D

func _ready() -> void:
	add_to_group("bullet")

var direction: Vector2 = Vector2.ZERO
var speed: float = 0.0

var pool = null

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	global_position += direction * speed * delta

func deactivate() -> void:
	direction = Vector2.ZERO
	speed = 0.0
	visible = false
	set_physics_process(false)
	monitoring = false
	monitorable = false
	if pool and pool.has_method("return_bullet"):
		pool.return_bullet(self)
	else:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	deactivate()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("laser"):
		deactivate()
		return
		
	if area.is_in_group("player"):
		if "is_god_mode" in area and area.is_god_mode:
			deactivate()
			return
		
		if area.has_method("die"):
			area.die()
		
		deactivate()
