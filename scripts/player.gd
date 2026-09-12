extends Area2D

signal died

@onready var screen_size: Vector2 = get_viewport_rect().size

var is_god_mode: bool = false
var is_alive: bool = true
var is_paused: bool = false

func _ready() -> void:
	add_to_group("player")
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()

func _on_viewport_resized() -> void:
	screen_size = get_viewport_rect().size

func _input(event: InputEvent) -> void:
	if not is_alive or is_paused:
		return
		
	var is_mouse_drag = event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var is_touch_drag = event is InputEventScreenDrag
	
	if is_mouse_drag or is_touch_drag:
		global_position += event.relative
		global_position.x = clamp(global_position.x, 20.0, screen_size.x - 20.0)
		global_position.y = clamp(global_position.y, 20.0, screen_size.y - 20.0)

func die() -> void:
	if not is_alive:
		return
		
	is_alive = false
	
	modulate.a = 0.5
	died.emit()
