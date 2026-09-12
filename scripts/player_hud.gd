extends Control

@onready var mode_label: Label = $mode_label
@onready var time_label: Label = $time_label

var music_label: Label
var hud_vbox: VBoxContainer

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	hud_vbox = VBoxContainer.new()
	hud_vbox.name = "HUD_VBox"
	hud_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_vbox.add_theme_constant_override("separation", 3)
	
	hud_vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hud_vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hud_vbox.grow_vertical = Control.GROW_DIRECTION_END
	hud_vbox.offset_right = -20
	hud_vbox.offset_top = 16
	
	add_child(hud_vbox)
	
	if mode_label:
		mode_label.get_parent().remove_child(mode_label)
		hud_vbox.add_child(mode_label)
	else:
		mode_label = Label.new()
		hud_vbox.add_child(mode_label)
		
	if time_label:
		time_label.get_parent().remove_child(time_label)
		hud_vbox.add_child(time_label)
	else:
		time_label = Label.new()
		hud_vbox.add_child(time_label)
		
	music_label = Label.new()
	music_label.name = "music_label"
	hud_vbox.add_child(music_label)
	
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95))
	
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.86))
	
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	music_label.add_theme_font_size_override("font_size", 12)
	music_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74))

func update_hud(mode_name: String, current_time: float) -> void:
	var clean_name = mode_name.replace("_OFFIC", "").replace("_ENDLESS", "").replace(".json", "")
	
	if mode_label:
		mode_label.text = "УРОВЕНЬ: " + clean_name.to_upper()
	if time_label:
		time_label.text = "ВРЕМЯ: " + str(snapped(current_time, 0.1)) + " сек."
		
	if music_label:
		if Engine.has_singleton("MusicManager") or get_node_or_null("/root/MusicManager"):
			var status = MusicManager.hud_status_text
			music_label.text = status
			
			if status.begins_with("Downloaded."):
				music_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			elif status.contains("Downloading"):
				music_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			else:
				music_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.74))
		else:
			music_label.text = "Now playing: no music"
