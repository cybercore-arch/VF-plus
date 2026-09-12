extends Node

var audio_player: AudioStreamPlayer
var http_request: HTTPRequest

var current_song_id: Variant = null
var current_song_title: String = "no music"
var current_playback_position: float = 0.0
var default_volume_db: float = 0.0

var is_downloading: bool = false
var download_target_id: int = 0
var download_percent: int = 0
var hud_status_text: String = "Now playing: no music"

var api_attempt: int = 0

var stream_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_download_completed)
	
	ensure_music_directories()

func _process(_delta: float) -> void:
	if is_downloading and http_request:
		var body_size = http_request.get_body_size()
		var downloaded = http_request.get_downloaded_bytes()
		if body_size > 0:
			download_percent = int((float(downloaded) / float(body_size)) * 100.0)
			hud_status_text = "(" + str(download_percent) + "%) Downloading " + str(download_target_id) + "..."
		elif downloaded > 0:
			hud_status_text = "Downloading " + str(download_target_id) + "... (" + str(downloaded / 1024) + " KB)"

func get_music_storage_dir() -> String:
	var path = ""
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://music/")
	elif OS.has_feature("android"):
		var doc_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		if doc_dir != "" and doc_dir != null:
			path = doc_dir.path_join("VF+").path_join("music") + "/"
		else:
			path = ProjectSettings.globalize_path("user://music/")
	else:
		path = OS.get_executable_path().get_base_dir().path_join("music") + "/"
	return path

func ensure_music_directories() -> void:
	var dir_path = get_music_storage_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	var user_cache = "user://music_cache/"
	if not DirAccess.dir_exists_absolute(user_cache):
		DirAccess.make_dir_recursive_absolute(user_cache)

func reset_state() -> void:
	stop_song()
	current_song_id = null
	current_song_title = "no music"
	hud_status_text = "Now playing: no music"
	is_downloading = false
	if http_request:
		http_request.cancel_request()

func handle_music_event(event: Dictionary) -> void:
	var action = str(event.get("action", "play")).to_lower()
	match action:
		"play":
			var raw_id = event.get("id", 0)
			var offset = float(event.get("start_offset", 0.0))
			var vol_db = float(event.get("volume_db", 0.0))
			var fade_in = float(event.get("fade_in", 0.0))
			play_song(raw_id, offset, vol_db, fade_in)
		"pause":
			pause_song()
		"resume", "continue", "contwith":
			resume_song(float(event.get("from_time", -1.0)))
		"stop":
			stop_song()

func play_song(song_id: Variant, start_offset: float = 0.0, volume_db: float = 0.0, fade_in: float = 0.0) -> void:
	var clean_id: Variant = song_id
	if typeof(song_id) == TYPE_FLOAT:
		clean_id = int(song_id)
		
	current_song_id = clean_id
	default_volume_db = volume_db
	
	current_song_title = str(clean_id)
	hud_status_text = "Now playing: " + current_song_title
	
	var stream = get_or_load_stream(clean_id)
	
	if stream == null:
		if (typeof(clean_id) == TYPE_INT and clean_id > 0) or (str(clean_id).is_valid_int() and str(clean_id).to_int() > 0):
			download_from_newgrounds(int(clean_id), start_offset, volume_db)
		else:
			hud_status_text = "Now playing: no music"
			print("MusicManager: трек с ID '", clean_id, "' не найден")
		return
		
	audio_player.stream = stream
	audio_player.stream_paused = false
	audio_player.volume_db = -40.0 if fade_in > 0.0 else volume_db
	audio_player.play(start_offset)
	
	hud_status_text = "Now playing: " + current_song_title
	print("MusicManager: -> ", current_song_title)
	
	if fade_in > 0.0:
		var tw = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(audio_player, "volume_db", volume_db, fade_in)

func pause_song(_fade_out: float = 0.0) -> void:
	if not audio_player.playing and not audio_player.stream_paused:
		return
	current_playback_position = audio_player.get_playback_position()
	audio_player.stream_paused = true

func resume_song(from_time: float = -1.0, _fade_in: float = 0.0) -> void:
	if audio_player.stream == null:
		return
		
	audio_player.volume_db = default_volume_db
	
	if from_time >= 0.0:
		audio_player.stream_paused = false
		audio_player.play(from_time)
	else:
		if audio_player.stream_paused:
			audio_player.stream_paused = false
		elif not audio_player.playing:
			audio_player.play(current_playback_position)

func stop_song(_fade_out: float = 0.0) -> void:
	if audio_player:
		audio_player.stop()
		audio_player.stream_paused = false
	current_playback_position = 0.0

func get_or_load_stream(song_id: Variant) -> AudioStream:
	var clean_id: Variant = song_id
	if typeof(song_id) == TYPE_FLOAT:
		clean_id = int(song_id)
		
	var key = str(clean_id).strip_edges()
	if stream_cache.has(key):
		current_song_title = key
		return stream_cache[key]
		
	var file_path = find_song_file(clean_id)
	if file_path == "":
		return null
		
	current_song_title = file_path.get_file().get_basename().strip_edges()
	
	var stream: AudioStream = null
	if file_path.begins_with("res://"):
		stream = load(file_path)
	else:
		stream = load_audio_from_disk(file_path)
		
	if stream != null:
		stream_cache[key] = stream
		return stream
		
	return null

func find_song_file(song_id: Variant) -> String:
	var clean_id: Variant = song_id
	if typeof(song_id) == TYPE_FLOAT:
		clean_id = int(song_id)
	var str_id = str(clean_id).strip_edges()
	
	var search_dirs = [
		"res://music/",
		get_music_storage_dir(),
		"user://music_cache/",
		"res://audio/"
	]
	
	for dir in search_dirs:
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var d = DirAccess.open(dir)
		if not d:
			continue
			
		d.list_dir_begin()
		var f_name = d.get_next()
		while f_name != "":
			if not d.current_is_dir() and (f_name.ends_with(".mp3") or f_name.ends_with(".ogg")):
				var base = f_name.get_basename().strip_edges()
				
				if base == str_id \
				or base.ends_with("_" + str_id) \
				or base.ends_with("-" + str_id.trim_prefix("-")) \
				or base.ends_with(" " + str_id) \
				or base == "ng_" + str_id \
				or base.begins_with("ng_" + str_id):
					d.list_dir_end()
					print("MusicManager: найден файл для ID ", clean_id, " -> ", dir.path_join(f_name))
					return dir.path_join(f_name)
					
			f_name = d.get_next()
		d.list_dir_end()
		
	
	return ""

func load_audio_from_disk(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var bytes = file.get_buffer(file.get_length())
	file.close()
	
	if bytes.size() < 100:
		
		DirAccess.remove_absolute(path)
		return null
		
	if path.ends_with(".mp3"):
		var mp3 = AudioStreamMP3.new()
		mp3.data = bytes
		return mp3
	elif path.ends_with(".ogg"):
		return AudioStreamOggVorbis.load_from_buffer(bytes)
		
	return null

func download_from_newgrounds(id: int, _start_offset: float, _volume_db: float) -> void:
	if is_downloading:
		return
	is_downloading = true
	download_target_id = id
	download_percent = 0
	api_attempt = 1
	hud_status_text = "(0%) Resolving " + str(id) + "..."
	
	
	var url = "https://geometrydash.io/api/song/" + str(id)
	var headers = PackedStringArray(["User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)"])
	var err = http_request.request(url, headers)
	if err != OK:
		try_next_gateway()

func try_next_gateway() -> void:
	api_attempt += 1
	
	
	if api_attempt == 2:
		var url = "https://api.allorigins.win/raw?url=" + ("https://gdbrowser.com/api/song/" + str(download_target_id)).uri_encode()
		http_request.request(url, PackedStringArray(["User-Agent: Mozilla/5.0"]))
	elif api_attempt == 3:
		var url = "http://www.boomlings.com/database/getGJSongInfo.php"
		var headers = PackedStringArray([
			"Content-Type: application/x-www-form-urlencoded",
			"User-Agent: "
		])
		var post_data = "songID=" + str(download_target_id) + "&secret=Wmfd2893gb7"
		http_request.request(url, headers, HTTPClient.METHOD_POST, post_data)
	else:
		hud_status_text = "Song not found on NG"
		is_downloading = false

func _on_http_download_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	
	
	if body.size() > 30000 and (response_code == 200 or response_code == 206):
		var save_path = "user://music_cache/ng_" + str(download_target_id) + ".mp3"
		var f = FileAccess.open(save_path, FileAccess.WRITE)
		if f:
			f.store_buffer(body)
			f.close()
			
			is_downloading = false
			hud_status_text = "Downloaded. Restart level (R)"
			
			stream_cache.erase(str(download_target_id))
			play_song(download_target_id)
			return
		else:
			hud_status_text = "Save error"
			is_downloading = false
			return

	if response_code != 200:
		try_next_gateway()
		return
		
	var text = body.get_string_from_utf8().strip_edges()
	
	
	var json = JSON.new()
	if json.parse(text) == OK:
		var data = json.get_data()
		if data is Dictionary:
			var link = ""
			if data.has("link"):
				link = str(data["link"])
			elif data.has("url"):
				link = str(data["url"])
			elif data.has("downloadUrl"):
				link = str(data["downloadUrl"])
				
			if link != "":
				link = link.uri_decode().replace("\\/", "/")
				print("Получено: ", link)
				hud_status_text = "Downloading audio..."
				http_request.request(link, PackedStringArray(["User-Agent: Mozilla/5.0"]))
				return
				
	if text.contains("~|~10~|~"):
		var parts = text.split("~|~")
		for i in range(parts.size() - 1):
			if parts[i] == "10":
				var direct_url = parts[i + 1].uri_decode()
				print("Boomlings CDN URL: ", direct_url)
				hud_status_text = "Downloading audio..."
				http_request.request(direct_url, PackedStringArray(["User-Agent: Mozilla/5.0"]))
				return
				
	try_next_gateway()
