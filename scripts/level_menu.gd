extends Control

var official_levels: Dictionary = {}
var endless_levels: Dictionary = {}
var custom_levels: Dictionary = {}

var bg_rect: ColorRect
var radial_container: Control
var radial_hub: Control
var lines_container: Control
var connector_lines: Array[Line2D] = []
var center_circle_btn: Button
var category_buttons: Array[Button] = []
var is_radial_open: bool = false

var list_view_container: Control
var list_title_label: Label
var list_scroll: ScrollContainer
var list_vbox: VBoxContainer
var custom_toolbar: HBoxContainer
var current_category: String = ""

const RADIAL_RADIUS: float = 190.0

const CIRCLE_SIZE: Vector2 = Vector2(130, 130)
const BUTTON_SIZE: Vector2 = Vector2(170, 50)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	setup_background()
	scan_all_levels()
	setup_radial_menu()
	setup_list_view()

func setup_background() -> void:
	bg_rect = ColorRect.new()
	bg_rect.name = "Background"
	bg_rect.color = Color(0.12, 0.12, 0.14, 1.0)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

func setup_radial_menu() -> void:
	radial_container = Control.new()
	radial_container.name = "RadialContainer"
	radial_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(radial_container)
	
	radial_hub = Control.new()
	radial_hub.name = "RadialHub"
	radial_hub.set_anchors_preset(Control.PRESET_CENTER)
	radial_container.add_child(radial_hub)
	
	lines_container = Control.new()
	lines_container.name = "LinesContainer"
	radial_hub.add_child(lines_container)
	
	var categories = [
		{"id": "official", "title": "Official Levels", "angle_deg": -90.0},
		{"id": "endless",  "title": "Endless Levels",  "angle_deg": 35.0},
		{"id": "custom",   "title": "Custom Levels",   "angle_deg": 145.0}
	]
	
	for item in categories:
		var line = Line2D.new()
		line.name = "Line_" + item["id"]
		line.width = 2.0
		line.default_color = Color(0.32, 0.35, 0.40, 0.8)
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2.ZERO)
		line.modulate.a = 0.0
		line.visible = false
		line.set_meta("angle_deg", item["angle_deg"])
		connector_lines.append(line)
		lines_container.add_child(line)

		var btn = create_radial_item_button(item["title"], item["id"], item["angle_deg"])
		category_buttons.append(btn)
		radial_hub.add_child(btn)
		
	center_circle_btn = Button.new()
	center_circle_btn.name = "CenterCircle"
	center_circle_btn.text = "START"
	center_circle_btn.custom_minimum_size = CIRCLE_SIZE
	center_circle_btn.size = CIRCLE_SIZE
	center_circle_btn.pivot_offset = CIRCLE_SIZE / 2.0
	center_circle_btn.position = -CIRCLE_SIZE / 2.0
	
	var circle_style = StyleBoxFlat.new()
	circle_style.set_corner_radius_all(65)
	circle_style.bg_color = Color(0.22, 0.23, 0.26, 1.0)
	circle_style.border_color = Color(0.35, 0.37, 0.42, 1.0)
	circle_style.border_width_bottom = 2
	circle_style.border_width_left = 2
	circle_style.border_width_right = 2
	circle_style.border_width_top = 2
	
	var circle_hover = circle_style.duplicate()
	circle_hover.bg_color = Color(0.28, 0.30, 0.34, 1.0)
	circle_hover.border_color = Color(0.55, 0.58, 0.65, 1.0)
	
	center_circle_btn.add_theme_stylebox_override("normal", circle_style)
	center_circle_btn.add_theme_stylebox_override("hover", circle_hover)
	center_circle_btn.add_theme_stylebox_override("pressed", circle_hover)
	center_circle_btn.add_theme_stylebox_override("focus", circle_hover)
	center_circle_btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	center_circle_btn.add_theme_font_size_override("font_size", 18)
	
	center_circle_btn.mouse_entered.connect(_on_center_circle_hover)
	center_circle_btn.mouse_exited.connect(_on_center_circle_unhover)
	center_circle_btn.pressed.connect(toggle_radial_menu)
	
	radial_hub.add_child(center_circle_btn)

func create_radial_item_button(title_text: String, cat_id: String, angle_deg: float) -> Button:
	var btn = Button.new()
	btn.name = "RadialBtn_" + cat_id
	btn.text = title_text
	btn.custom_minimum_size = BUTTON_SIZE
	btn.size = BUTTON_SIZE
	btn.pivot_offset = BUTTON_SIZE / 2.0
	
	var style_norm = StyleBoxFlat.new()
	style_norm.bg_color = Color(0.18, 0.19, 0.22, 0.95)
	style_norm.set_corner_radius_all(6)
	style_norm.border_width_bottom = 1
	style_norm.border_width_top = 1
	style_norm.border_width_left = 1
	style_norm.border_width_right = 1
	style_norm.border_color = Color(0.30, 0.32, 0.36, 1.0)
	style_norm.content_margin_left = 14
	style_norm.content_margin_right = 14
	
	var style_hover = style_norm.duplicate()
	style_hover.bg_color = Color(0.25, 0.27, 0.31, 1.0)
	style_hover.border_color = Color(0.60, 0.62, 0.68, 1.0)
	
	btn.add_theme_stylebox_override("normal", style_norm)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_color_override("font_color", Color(0.85, 0.86, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_font_size_override("font_size", 15)
	
	btn.position = -BUTTON_SIZE / 2.0
	btn.modulate.a = 0.0
	btn.visible = false
	
	btn.set_meta("angle_deg", angle_deg)
	btn.set_meta("cat_id", cat_id)
	
	btn.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	btn.pressed.connect(func():
		_on_category_selected(cat_id)
	)
	
	return btn

func _on_center_circle_hover() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_circle_btn, "scale", Vector2(1.08, 1.08), 0.15)

func _on_center_circle_unhover() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_circle_btn, "scale", Vector2(1.0, 1.0), 0.15)

func toggle_radial_menu() -> void:
	is_radial_open = !is_radial_open
	
	if is_radial_open:
		center_circle_btn.text = "CLOSE"
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for i in range(category_buttons.size()):
			var btn = category_buttons[i]
			var line = connector_lines[i]
			btn.visible = true
			line.visible = true
			
			var angle_rad = deg_to_rad(btn.get_meta("angle_deg"))
			var dir = Vector2(cos(angle_rad), sin(angle_rad))
			var offset = dir * RADIAL_RADIUS
			var target_pos = offset - (BUTTON_SIZE / 2.0)
			
			tw.tween_property(btn, "position", target_pos, 0.35)
			tw.tween_property(btn, "modulate:a", 1.0, 0.3)
			
			tw.tween_method(func(p: Vector2):
				line.set_point_position(1, p)
			, Vector2.ZERO, offset, 0.35)
			tw.tween_property(line, "modulate:a", 1.0, 0.3)
	else:
		center_circle_btn.text = "START"
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for i in range(category_buttons.size()):
			var btn = category_buttons[i]
			var line = connector_lines[i]
			var center_pos = -BUTTON_SIZE / 2.0
			
			tw.tween_property(btn, "position", center_pos, 0.42)
			tw.tween_property(btn, "modulate:a", 0.0, 0.38)
			
			var cur_p = line.get_point_position(1)
			tw.tween_method(func(p: Vector2):
				line.set_point_position(1, p)
			, cur_p, Vector2.ZERO, 0.42)
			tw.tween_property(line, "modulate:a", 0.0, 0.38)
			
		tw.chain().tween_callback(func():
			for i in range(category_buttons.size()):
				if not is_radial_open:
					category_buttons[i].visible = false
					connector_lines[i].visible = false
		)

func setup_list_view() -> void:
	list_view_container = Control.new()
	list_view_container.name = "ListViewContainer"
	list_view_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_view_container.modulate.a = 0.0
	list_view_container.visible = false
	add_child(list_view_container)
	
	var header_bar = HBoxContainer.new()
	header_bar.name = "HeaderBar"
	header_bar.position = Vector2(32, 24)
	header_bar.add_theme_constant_override("separation", 16)
	list_view_container.add_child(header_bar)
	
	var back_btn = create_minimal_button("← BACK", Vector2(80, 36))
	back_btn.pressed.connect(return_to_radial_menu)
	header_bar.add_child(back_btn)
	
	list_title_label = Label.new()
	list_title_label.name = "CategoryTitle"
	list_title_label.text = "OFFICIAL LEVELS"
	list_title_label.add_theme_font_size_override("font_size", 18)
	list_title_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.92))
	header_bar.add_child(list_title_label)
	
	custom_toolbar = HBoxContainer.new()
	custom_toolbar.name = "CustomToolbar"
	custom_toolbar.add_theme_constant_override("separation", 10)
	header_bar.add_child(custom_toolbar)
	
	var btn_refresh = create_minimal_button("[ UPDATE ]", Vector2(90, 36))
	btn_refresh.pressed.connect(func():
		scan_all_levels()
		render_current_category_levels()
		show_temp_notice("Levels refreshed")
	)
	custom_toolbar.add_child(btn_refresh)
	
	var btn_levels = create_minimal_button("[ levels ]", Vector2(90, 36))
	btn_levels.tooltip_text = "Open levels folder"
	btn_levels.pressed.connect(func():
		var p = Global.get_custom_levels_dir()
		var res = Global.open_folder_in_os(p)
		show_temp_notice("Path: " + res)
	)
	custom_toolbar.add_child(btn_levels)
	
	var btn_patterns = create_minimal_button("[ patterns ]", Vector2(95, 36))
	btn_patterns.tooltip_text = "Open patterns folder"
	btn_patterns.pressed.connect(func():
		var p = Global.get_custom_patterns_dir()
		var res = Global.open_folder_in_os(p)
		show_temp_notice("Path: " + res)
	)
	custom_toolbar.add_child(btn_patterns)
	
	list_scroll = ScrollContainer.new()
	list_scroll.name = "ScrollContainer"
	list_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	list_scroll.offset_left = 32
	list_scroll.offset_top = 80
	list_scroll.offset_right = -32
	list_scroll.offset_bottom = -24
	list_view_container.add_child(list_scroll)
	
	list_vbox = VBoxContainer.new()
	list_vbox.name = "LevelVBox"
	list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vbox.add_theme_constant_override("separation", 8)
	list_scroll.add_child(list_vbox)

func _on_category_selected(cat_id: String) -> void:
	current_category = cat_id
	
	if is_radial_open:
		toggle_radial_menu()
		
	var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.18)
	tw.tween_property(radial_container, "modulate:a", 0.0, 0.25)
	tw.tween_property(radial_container, "scale", Vector2(0.92, 0.92), 0.25)
	tw.tween_callback(func():
		radial_container.visible = false
		radial_container.scale = Vector2.ONE
		show_list_view_for_category(cat_id)
	)

func show_list_view_for_category(cat_id: String) -> void:
	list_view_container.visible = true
	list_view_container.modulate.a = 0.0
	
	match cat_id:
		"official":
			list_title_label.text = "OFFICIAL LEVELS"
			custom_toolbar.visible = false
		"endless":
			list_title_label.text = "ENDLESS LEVELS"
			custom_toolbar.visible = false
		"custom":
			list_title_label.text = "CUSTOM LEVELS"
			custom_toolbar.visible = true
			
	render_current_category_levels()
	
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(list_view_container, "modulate:a", 1.0, 0.25)

func return_to_radial_menu() -> void:
	var tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(list_view_container, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func():
		list_view_container.visible = false
		radial_container.visible = true
		radial_container.scale = Vector2.ONE
		is_radial_open = false
		center_circle_btn.text = "START"
		for btn in category_buttons:
			btn.visible = false
			btn.position = -BUTTON_SIZE / 2.0
			btn.modulate.a = 0.0
		for line in connector_lines:
			line.visible = false
			line.set_point_position(1, Vector2.ZERO)
			line.modulate.a = 0.0
		var tw_in = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw_in.tween_property(radial_container, "modulate:a", 1.0, 0.25)
	)

func render_current_category_levels() -> void:
	for child in list_vbox.get_children():
		child.queue_free()
		
	var target_dict: Dictionary
	var empty_hint: String = ""
	
	match current_category:
		"official":
			target_dict = official_levels
			empty_hint = "No official levels found (files containing 'OFFIC' in data/)."
		"endless":
			target_dict = endless_levels
			empty_hint = "No endless levels found (files containing 'ENDLESS' in data/)."
		"custom":
			target_dict = custom_levels
			empty_hint = "No custom levels yet. Click [ levels ] and drop your .json files there."
			
	if target_dict.is_empty():
		var lbl = Label.new()
		lbl.text = empty_hint
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.55, 0.56, 0.6))
		list_vbox.add_child(lbl)
		return
		
	var sorted_keys = target_dict.keys()
	sorted_keys.sort()
	
	for file_name in sorted_keys:
		var full_path = target_dict[file_name]
		var btn = create_level_row_button(file_name, full_path)
		list_vbox.add_child(btn)

func format_level_display_name(raw_name: String) -> String:
	var clean = raw_name.trim_suffix(".json")
	
	var reg_offic = RegEx.new()
	reg_offic.compile("(?i)(offic(ial)?)[_\\-\\s]*")
	clean = reg_offic.sub(clean, "", true)
	
	var reg_endless = RegEx.new()
	reg_endless.compile("(?i)(endless)[_\\-\\s]*")
	clean = reg_endless.sub(clean, "", true)
	
	clean = clean.strip_edges()
	while clean.begins_with("_") or clean.begins_with("-"):
		clean = clean.substr(1).strip_edges()
	while clean.ends_with("_") or clean.ends_with("-"):
		clean = clean.substr(0, clean.length() - 1).strip_edges()
		
	if clean.is_empty():
		return raw_name.trim_suffix(".json")
	return clean

func create_level_row_button(file_name: String, full_path: String) -> Button:
	var btn = Button.new()
	btn.text = format_level_display_name(file_name)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 14)
	
	var style_norm = StyleBoxFlat.new()
	style_norm.bg_color = Color(0.16, 0.17, 0.19, 0.9)
	style_norm.set_corner_radius_all(4)
	style_norm.content_margin_left = 16
	style_norm.content_margin_right = 16
	style_norm.border_width_left = 1
	style_norm.border_width_right = 1
	style_norm.border_width_top = 1
	style_norm.border_width_bottom = 1
	style_norm.border_color = Color(0.24, 0.25, 0.28, 1.0)
	
	var style_hover = style_norm.duplicate()
	style_hover.bg_color = Color(0.22, 0.24, 0.28, 1.0)
	style_hover.border_color = Color(0.45, 0.48, 0.54, 1.0)
	
	btn.add_theme_stylebox_override("normal", style_norm)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.add_theme_stylebox_override("focus", style_hover)
	btn.add_theme_color_override("font_color", Color(0.85, 0.86, 0.88))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	
	btn.pressed.connect(func(): _on_level_selected(file_name, full_path))
	return btn

func scan_all_levels() -> void:
	official_levels.clear()
	endless_levels.clear()
	custom_levels.clear()
	
	var data_files: Dictionary = {}
	scan_folder("res://data/", data_files)
	
	for file_name in data_files.keys():
		var upper_name = file_name.to_upper()
		var full_path = data_files[file_name]
		if upper_name.contains("OFFIC"):
			official_levels[file_name] = full_path
		elif upper_name.contains("ENDLESS"):
			endless_levels[file_name] = full_path
		else:
			official_levels[file_name] = full_path
			
	var search_dirs = Global.get_level_search_dirs()
	for dir_path in search_dirs:
		if dir_path == "res://data/":
			continue
		scan_folder(dir_path, custom_levels)

func scan_folder(dir_path: String, out_dict: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			if not out_dict.has(file_name):
				out_dict[file_name] = dir_path.path_join(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func _on_level_selected(file_name: String, full_path: String) -> void:
	Global.current_level_file = file_name
	Global.current_level_path = full_path
	print("Starting level: ", file_name, " (", full_path, ")")
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func show_temp_notice(msg: String) -> void:
	print(msg)
	var notice = Label.new()
	notice.text = msg
	notice.position = Vector2(32, get_viewport_rect().size.y - 36)
	notice.add_theme_color_override("font_color", Color(0.7, 0.72, 0.76))
	notice.add_theme_font_size_override("font_size", 12)
	add_child(notice)
	
	var tw = create_tween()
	tw.tween_interval(3.0)
	tw.tween_property(notice, "modulate:a", 0.0, 0.6)
	tw.tween_callback(notice.queue_free)

func create_minimal_button(text: String, min_size: Vector2) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.19, 0.22, 1.0)
	style.set_corner_radius_all(4)
	style.border_width_bottom = 1
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.28, 0.30, 0.34, 1.0)
	style.content_margin_left = 10
	style.content_margin_right = 10
	
	var style_h = style.duplicate()
	style_h.bg_color = Color(0.24, 0.26, 0.30, 1.0)
	style_h.border_color = Color(0.50, 0.52, 0.58, 1.0)
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.add_theme_stylebox_override("pressed", style_h)
	btn.add_theme_stylebox_override("focus", style_h)
	btn.add_theme_color_override("font_color", Color(0.85, 0.86, 0.88))
	btn.add_theme_font_size_override("font_size", 12)
	return btn
