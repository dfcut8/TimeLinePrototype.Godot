extends VBoxContainer
## Exactly one decoder and one full-sized image; enlarge uses this same instance.
signal preferences_changed(volume: float, muted: bool)

var current_event: Dictionary = {}
var document: ArchiveDocument
var volume: float = 0.5
var muted: bool = false
var available: bool = false
var _is_video: bool = false
@onready var video: VideoStreamPlayer = %Video

func _ready() -> void:
	%Play.pressed.connect(toggle_play)
	%Restart.pressed.connect(restart_video)
	%Mute.pressed.connect(func() -> void:
		set_preferences(volume, not muted)
		preferences_changed.emit(volume, muted))
	%Volume.value_changed.connect(func(value: float) -> void:
		set_preferences(value, muted)
		preferences_changed.emit(volume, muted))
	%Retry.pressed.connect(retry)
	video.finished.connect(_finished)
	video.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			toggle_play()
			video.accept_event())

func show_event(item: Dictionary, archive: ArchiveDocument) -> void:
	release()
	current_event = item
	document = archive
	_is_video = item.kind == "video_text"
	%Play.visible = _is_video
	%Restart.visible = _is_video
	%Mute.visible = _is_video
	%Volume.visible = _is_video
	%Elapsed.visible = _is_video
	%Surface.ratio = 16.0 / 9.0
	if _is_video:
		if item.media.has("poster"):
			%Image.texture = _load_image(archive.resolve_media(item.media.poster.path))
		var path: String = archive.resolve_media(item.media.path)
		if path.begins_with("res://") and ResourceLoader.exists(path):
			video.stream = load(path) as VideoStream
			available = video.stream != null and video.get_video_texture() != null
			if not available:
				_unavailable("The bundled video could not be decoded.")
			else:
				%MediaStatus.text = "Video ready · Press Play · " + item.media.description
				%Retry.visible = false
				%Play.disabled = false
				%Restart.disabled = false
				set_preferences(volume, muted)
			return
		if not FileAccess.file_exists(path):
			_unavailable("Video file is missing. Read the transcript below or Retry.")
			return
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null or file.get_buffer(4).get_string_from_ascii() != "OggS":
			_unavailable("Video is not a readable Ogg Theora file. Text and transcript remain available.")
			return
		var stream := VideoStreamTheora.new()
		stream.file = ProjectSettings.globalize_path(path)
		video.stream = stream
		available = video.get_video_texture() != null
		if not available:
			_unavailable("The video could not be decoded. Text and transcript remain available.")
			return
		%MediaStatus.text = "Video ready · Press Play · " + item.media.description
	else:
		%Image.texture = _load_image(archive.resolve_media(item.media.path))
		available = %Image.texture != null
		if not available:
			_unavailable("Image unavailable (missing, corrupt or larger than 4096 px). " + item.media.description)
			return
		var texture: Texture2D = %Image.texture
		%Surface.ratio = float(texture.get_width()) / texture.get_height()
		%MediaStatus.text = item.media.description
	%Retry.visible = false
	%Play.disabled = not available
	%Restart.disabled = not available
	set_preferences(volume, muted)

func _load_image(path: String) -> Texture2D:
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null and imported.get_width() <= 4096 and imported.get_height() <= 4096:
			return imported
		return null
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty() or image.get_width() > 4096 or image.get_height() > 4096:
		return null
	return ImageTexture.create_from_image(image)

func _unavailable(reason: String) -> void:
	available = false
	%MediaStatus.text = reason
	%Retry.visible = true
	%Play.disabled = true
	%Restart.disabled = true
	video.stop()
	video.stream = null

func retry() -> void:
	if not current_event.is_empty():
		show_event(current_event, document)

func toggle_play() -> void:
	if not _is_video or not available:
		return
	if video.is_playing():
		video.paused = not video.paused
	else:
		video.play()
		video.paused = false
	video.visible = true
	%Image.visible = false
	%Play.text = "Play" if video.paused else "Pause"

func restart_video() -> void:
	if not available:
		return
	video.stop()
	video.play()
	video.paused = false
	video.visible = true
	%Image.visible = false
	%Play.text = "Pause"

func _finished() -> void:
	%Play.text = "Play again"
	video.visible = false
	%Image.visible = true

func set_preferences(value: float, mute_value: bool) -> void:
	volume = clampf(value, 0.0, 1.0)
	muted = mute_value
	if not is_node_ready():
		return
	%Volume.set_value_no_signal(volume)
	%Mute.text = "Unmute" if muted else "Mute"
	video.volume_db = -80.0 if muted or volume == 0 else linear_to_db(volume)

func _process(_delta: float) -> void:
	if _is_video and video.is_playing():
		var seconds := int(video.stream_position)
		%Elapsed.text = "%d:%02d" % [seconds / 60, seconds % 60]
		var texture := video.get_video_texture()
		if texture != null and texture.get_height() > 0:
			if texture.get_width() > 1920 or texture.get_height() > 1080:
				_unavailable("Video exceeds the 1920 × 1080 delivery limit.")
			else:
				%Surface.ratio = float(texture.get_width()) / texture.get_height()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and video.is_playing():
		video.paused = true
		%Play.text = "Resume"

func release() -> void:
	if not is_node_ready():
		return
	video.stop()
	video.stream = null
	video.visible = false
	%Image.texture = null
	%Image.visible = true
	%Play.text = "Play"
	%Elapsed.text = "0:00"
	available = false
