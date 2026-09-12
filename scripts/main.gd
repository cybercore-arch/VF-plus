extends Node2D

@onready var player_hud = $canvas_layer/player_hud
@onready var player = $player
@onready var pattern_manager = $pattern_manager

var time_survived: float = 0.0
var current_mode_name: String = ""
var is_game_over: bool = false
var is_victory: bool = false

# Pause state via time_scale = 0.0
var is_game_paused: bool = false
var saved_time_scale: float = 1.0
var pause_overlay: CanvasLayer
var pause_box_container: Control
var pause_dim_rect: ColorRect

# Touch/Mouse HUD buttons
var touch_pause_button: Button
var touch_dev_button: Button

# Dev Overlay elements
var dev_canvas: CanvasLayer
var dev_panel: PanelContainer
var is_dev_menu_open: bool = false
var god_mode_label: Label
var speed_label: Label
var pause_status_label: Label
var bullets_count_label: Label
var fps_label: Label

# UI Overlays
var game_over_canvas: CanvasLayer
var game_over_box: Control
var game_over_dim: ColorRect

var victory_canvas: CanvasLayer
var victory_box: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	RenderingServer.set_default_clear_color(Color("2e3036ff"))
	
	var mm = get_node_or_null("/root/MusicManager")
	if mm and mm.has_method("reset_state"):
		mm.reset_state()
	
	current_mode_name = Global.current_level_file.get_basename()
	
	if player:
		player.died.connect(game_over)
		
	if pattern_manager and pattern_manager.has_signal("level_completed"):
		pattern_manager.level_completed.connect(on_level_completed)
		
	setup_touch_hud_controls()
	setup_pause_overlay()
	setup_dev_menu()

func _process(delta: float) -> void:
	if not is_game_over and not is_game_paused and not is_victory:
		time_survived += delta
		if player_hud:
			player_hud.update_hud(current_mode_name, time_survived)
			
	if is_dev_menu_open:
		update_dev_stats()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
		
	# 1. Dev Menu toggle (~ / Russian letter Yo)
	if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_ASCIITILDE or event.physical_keycode == KEY_QUOTELEFT:
		toggle_dev_menu()
		return
		
	# 2. Fast restart (R)
	if event.keycode == KEY_R:
		_restart_level()
		return
		
	# 3. Pause (Space / P)
	if event.keycode == KEY_P or (event.keycode == KEY_SPACE and not is_game_over and not is_victory):
		toggle_pause()
		return
		
	# 4. Exit to menu (ESC)
	if event.keycode == KEY_ESCAPE:
		_go_to_menu()
		return
		
	# 5. Clear bullets (C)
	if event.keycode == KEY_C:
		clear_all_bullets()
		return
		
	# 6. God Mode (1)
	if event.keycode == KEY_1:
		toggle_god_mode()
		return
		
	# 7. Speed presets
	if event.keycode == KEY_2:
		set_game_speed(0.3)
	elif event.keycode == KEY_3:
		set_game_speed(1.0)
	elif event.keycode == KEY_4:
		set_game_speed(2.0)
		
	# 8. Speed fine-tuning: - and +
	elif event.keycode == KEY_MINUS:
		var target = (saved_time_scale if is_game_paused else Engine.time_scale) - 0.25
		set_game_speed(clamp(target, 0.1, 4.0))
	elif event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS:
		var target = (saved_time_scale if is_game_paused else Engine.time_scale) + 0.25
		set_game_speed(clamp(target, 0.1, 4.0))

func setup_touch_hud_controls() -> void:
	var hud_layer = CanvasLayer.new()
	hud_layer.layer = 50
	add_child(hud_layer)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 16
	margin.offset_top = 16
	hud_layer.add_child(margin)
	
	var bar = HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	margin.add_child(bar)
	
	touch_pause_button = Button.new()
	touch_pause_button.text = "PAUSE"
	touch_pause_button.custom_minimum_size = Vector2(80, 38)
	touch_pause_button.pressed.connect(toggle_pause)
	bar.add_child(touch_pause_button)
	
	touch_dev_button = Button.new()
	touch_dev_button.text = "DEV (~)"
	touch_dev_button.custom_minimum_size = Vector2(80, 38)
	touch_dev_button.pressed.connect(toggle_dev_menu)
	bar.add_child(touch_dev_button)

func setup_pause_overlay() -> void:
	pause_overlay = CanvasLayer.new()
	pause_overlay.layer = 90
	pause_overlay.visible = false
	add_child(pause_overlay)
	
	pause_dim_rect = ColorRect.new()
	pause_dim_rect.color = Color(0, 0, 0, 0.65)
	pause_dim_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(pause_dim_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	
	var box = VBoxContainer.new()
	box.name = "PauseBox"
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	pause_box_container = box
	
	var label = Label.new()
	label.text = "PAUSED"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	box.add_child(label)
	
	var btn_resume = Button.new()
	btn_resume.text = "RESUME"
	btn_resume.custom_minimum_size = Vector2(240, 46)
	btn_resume.pressed.connect(toggle_pause)
	box.add_child(btn_resume)
	
	var btn_restart = Button.new()
	btn_restart.text = "RESTART (R)"
	btn_restart.custom_minimum_size = Vector2(240, 46)
	btn_restart.pressed.connect(_restart_level)
	box.add_child(btn_restart)
	
	var btn_menu = Button.new()
	btn_menu.text = "MAIN MENU (Esc)"
	btn_menu.custom_minimum_size = Vector2(240, 46)
	btn_menu.pressed.connect(_go_to_menu)
	box.add_child(btn_menu)

func toggle_pause() -> void:
	if is_game_over or is_victory:
		return
		
	is_game_paused = !is_game_paused
	
	if is_game_paused:
		saved_time_scale = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
		Engine.time_scale = 0.0
		if player:
			player.is_paused = true
		if pause_overlay:
			pause_overlay.visible = true
		if touch_pause_button:
			touch_pause_button.text = "RESUME"
			
		var mm = get_node_or_null("/root/MusicManager")
		if mm:
			mm.pause_song()
	else:
		Engine.time_scale = saved_time_scale if saved_time_scale > 0.0 else 1.0
		if player:
			player.is_paused = false
		if pause_overlay:
			pause_overlay.visible = false
		if touch_pause_button:
			touch_pause_button.text = "PAUSE"
			
		var mm = get_node_or_null("/root/MusicManager")
		if mm:
			mm.resume_song()
			
	if is_dev_menu_open:
		update_dev_stats()

func setup_dev_menu() -> void:
	dev_canvas = CanvasLayer.new()
	dev_canvas.layer = 100
	dev_canvas.visible = false
	add_child(dev_canvas)
	
	dev_panel = PanelContainer.new()
	dev_panel.position = Vector2(20, 20)
	dev_panel.custom_minimum_size = Vector2(340, 450)
	dev_canvas.add_child(dev_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	dev_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	var top_bar = HBoxContainer.new()
	vbox.add_child(top_bar)
	
	var title = Label.new()
	title.text = "DEV MENU (~)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	top_bar.add_child(title)
	
	var btn_close = Button.new()
	btn_close.text = "[ X ]"
	btn_close.custom_minimum_size = Vector2(40, 32)
	btn_close.pressed.connect(toggle_dev_menu)
	top_bar.add_child(btn_close)
	
	var stats_box = VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 4)
	vbox.add_child(stats_box)
	
	god_mode_label = Label.new()
	god_mode_label.text = "God Mode: [OFF] (1)"
	stats_box.add_child(god_mode_label)
	
	speed_label = Label.new()
	speed_label.text = "Speed: 1.0x"
	stats_box.add_child(speed_label)
	
	pause_status_label = Label.new()
	pause_status_label.text = "Pause: [NO] (P)"
	stats_box.add_child(pause_status_label)
	
	bullets_count_label = Label.new()
	bullets_count_label.text = "Bullets on screen: 0"
	stats_box.add_child(bullets_count_label)
	
	fps_label = Label.new()
	fps_label.text = "FPS: 60"
	stats_box.add_child(fps_label)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	var btn_god = Button.new()
	btn_god.text = "Toggle God Mode (1)"
	btn_god.custom_minimum_size = Vector2(0, 34)
	btn_god.pressed.connect(toggle_god_mode)
	vbox.add_child(btn_god)
	
	var btn_pause = Button.new()
	btn_pause.text = "Pause / Resume (P)"
	btn_pause.custom_minimum_size = Vector2(0, 34)
	btn_pause.pressed.connect(toggle_pause)
	vbox.add_child(btn_pause)
	
	var speed_bar = HBoxContainer.new()
	speed_bar.add_theme_constant_override("separation", 6)
	vbox.add_child(speed_bar)
	
	var speeds = [0.3, 0.5, 1.0, 2.0]
	for sp in speeds:
		var b = Button.new()
		b.text = str(sp) + "x"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): set_game_speed(sp))
		speed_bar.add_child(b)
		
	var btn_clear = Button.new()
	btn_clear.text = "Clear Bullets (C)"
	btn_clear.custom_minimum_size = Vector2(0, 34)
	btn_clear.pressed.connect(clear_all_bullets)
	vbox.add_child(btn_clear)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var cheat_sheet = Label.new()
	cheat_sheet.text = "Hotkeys:\n[ ~ ] / [DEV] - Dev menu | [ 1 ] - God Mode\n[ 2/3/4 ] - 0.3x/1x/2x | [ - / + ] - Speed\n[ C ] - Clear bullets | [ P ] / [PAUSE] - Pause\n[ R ] - Restart | [ Esc ] - Menu"
	cheat_sheet.add_theme_font_size_override("font_size", 11)
	cheat_sheet.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(cheat_sheet)

func toggle_dev_menu() -> void:
	is_dev_menu_open = !is_dev_menu_open
	if dev_canvas:
		dev_canvas.visible = is_dev_menu_open
	if is_dev_menu_open:
		update_dev_stats()

func toggle_god_mode() -> void:
	if player:
		player.is_god_mode = !player.is_god_mode
		if is_dev_menu_open:
			update_dev_stats()

func set_game_speed(val: float) -> void:
	var rounded = snapped(val, 0.05)
	if is_game_paused:
		saved_time_scale = rounded
	else:
		Engine.time_scale = rounded
	if is_dev_menu_open:
		update_dev_stats()

func clear_all_bullets() -> void:
	get_tree().call_group("bullet", "deactivate")

func update_dev_stats() -> void:
	if not is_instance_valid(god_mode_label):
		return
	if player and player.is_god_mode:
		god_mode_label.text = "God Mode: [ON] (1)"
		god_mode_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		god_mode_label.text = "God Mode: [OFF] (1)"
		god_mode_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		
	var current_sp = saved_time_scale if is_game_paused else Engine.time_scale
	speed_label.text = "Speed: " + str(snapped(current_sp, 0.05)) + "x"
	
	if is_game_paused:
		pause_status_label.text = "Pause: [PAUSED (0.0x)]"
		pause_status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	else:
		pause_status_label.text = "Pause: [NO]"
		pause_status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
	bullets_count_label.text = "Bullets on screen: " + str(get_tree().get_nodes_in_group("bullet").size())
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

func game_over() -> void:
	if is_game_over or is_victory:
		return
		
	is_game_over = true
	set_process(false)
	Engine.time_scale = 1.0
	is_game_paused = false
	if pause_overlay:
		pause_overlay.visible = false
	
	if pattern_manager:
		pattern_manager.set_process(false)
		
	var mm = get_node_or_null("/root/MusicManager")
	if mm:
		mm.stop_song()
		
	show_game_over_screen()

func show_game_over_screen() -> void:
	game_over_canvas = CanvasLayer.new()
	game_over_canvas.layer = 95
	add_child(game_over_canvas)
	
	game_over_dim = ColorRect.new()
	game_over_dim.color = Color(0, 0, 0, 0.7)
	game_over_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_canvas.add_child(game_over_dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_canvas.add_child(center)
	
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.pivot_offset = Vector2(120, 110)
	center.add_child(box)
	game_over_box = box
	
	var title = Label.new()
	title.text = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	box.add_child(title)
	
	var time_label = Label.new()
	time_label.text = "Survived: " + str(snapped(time_survived, 0.1)) + " sec"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.86))
	box.add_child(time_label)
	
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	box.add_child(btn_box)
	
	var btn_restart = Button.new()
	btn_restart.text = "RESTART (R)"
	btn_restart.custom_minimum_size = Vector2(240, 48)
	btn_restart.pressed.connect(_restart_level)
	btn_box.add_child(btn_restart)
	
	var btn_menu = Button.new()
	btn_menu.text = "MAIN MENU (Esc)"
	btn_menu.custom_minimum_size = Vector2(240, 48)
	btn_menu.pressed.connect(_go_to_menu)
	btn_box.add_child(btn_menu)
	
	game_over_dim.modulate.a = 0.0
	box.modulate.a = 0.0
	box.scale = Vector2(0.9, 0.9)
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(game_over_dim, "modulate:a", 1.0, 0.3)
	tw.tween_property(box, "modulate:a", 1.0, 0.3)
	tw.tween_property(box, "scale", Vector2.ONE, 0.3)

func on_level_completed() -> void:
	if is_game_over or is_victory:
		return
		
	is_victory = true
	set_process(false)
	
	if player:
		player.is_alive = false
		
	victory_canvas = CanvasLayer.new()
	victory_canvas.layer = 95
	add_child(victory_canvas)
	
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.modulate.a = 0.0
	victory_canvas.add_child(dim)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_canvas.add_child(center)
	
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.pivot_offset = Vector2(120, 110)
	box.scale = Vector2(0.9, 0.9)
	box.modulate.a = 0.0
	center.add_child(box)
	victory_box = box
	
	var title = Label.new()
	title.text = "LEVEL COMPLETED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	box.add_child(title)
	
	var time_label = Label.new()
	time_label.text = "Total Time: " + str(snapped(time_survived, 0.1)) + " sec"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	box.add_child(time_label)
	
	var btn_box = VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	box.add_child(btn_box)
	
	var btn_restart = Button.new()
	btn_restart.text = "PLAY AGAIN (R)"
	btn_restart.custom_minimum_size = Vector2(240, 48)
	btn_restart.pressed.connect(_restart_level)
	btn_box.add_child(btn_restart)
	
	var btn_menu = Button.new()
	btn_menu.text = "MAIN MENU (Esc)"
	btn_menu.custom_minimum_size = Vector2(240, 48)
	btn_menu.pressed.connect(_go_to_menu)
	btn_box.add_child(btn_menu)
	
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(dim, "modulate:a", 1.0, 0.35)
	tw.tween_property(box, "modulate:a", 1.0, 0.35)
	tw.tween_property(box, "scale", Vector2.ONE, 0.35)

func _restart_level() -> void:
	Engine.time_scale = 1.0
	is_game_paused = false
	var mm = get_node_or_null("/root/MusicManager")
	if mm and mm.has_method("reset_state"):
		mm.reset_state()
	get_tree().reload_current_scene()

func _go_to_menu() -> void:
	Engine.time_scale = 1.0
	is_game_paused = false
	var mm = get_node_or_null("/root/MusicManager")
	if mm and mm.has_method("reset_state"):
		mm.reset_state()
	get_tree().change_scene_to_file("res://scenes/level_menu.tscn")
