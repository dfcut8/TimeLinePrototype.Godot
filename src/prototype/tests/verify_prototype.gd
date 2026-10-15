extends SceneTree
## Integration checks in the real engine, using an isolated APPDATA for user preferences.
const DOCUMENT = preload("res://prototype/archive_document.gd")
const MAIN = preload("res://prototype/galactic_archive.tscn")
var failures: PackedStringArray = []
var checks: int = 0
var app: Node3D

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		printerr("FAIL: " + description)

func tick(frames: int = 3) -> void:
	for frame: int in range(frames):
		await process_frame

func key(code: Key, alt: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.alt_pressed = alt
	root.push_input(event)
	await tick(1)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
	await tick(1)

func _fixture(data: Variant, name: String = "test-timeline.json") -> String:
	var path := "user://" + name
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	return path

func _run() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	var loader: ArchiveDocument = DOCUMENT.new()
	check(loader.load_file("res://content/demo/timeline.json"), "Demo validates: " + loader.error)
	check(loader.events.size() == 20, "20 demo records")
	check(loader.events[0].id == "record-01" and loader.events[-1].date.start == null, "Earliest first, undated last")
	var original: Dictionary = loader.document.duplicate(true)
	var data: Dictionary = original.duplicate(true)
	data.events.reverse()
	check(loader.load_file(_fixture(data)), "Array order has no chronological meaning")
	check(loader.events[2].id == "record-03" and loader.events[3].id == "record-04", "Equal dates respect editorial tie order")
	data = original.duplicate(true)
	data.events[3].sequence = data.events[2].sequence
	data.events.reverse()
	check(loader.load_file(_fixture(data)) and loader.events[2].id == "record-03", "Equal sequence uses stable ASCII id")
	for path: String in ["../escape.png", "/absolute.png", "C:/file.png", "res://file.png", "https://a/b.png", "media/../../escape.png", "media\\file.png"]:
		check(not ArchiveDocument.safe_path(path), "Reject unsafe media path: " + path)
	check(ArchiveDocument.safe_path("media/portrait.png"), "Allow package-relative media")
	for mutation: String in ["version", "duplicate_id", "date", "era", "path", "kind", "sequence", "body", "transcript", "noncontiguous", "era_sections"]:
		data = original.duplicate(true)
		match mutation:
			"version": data.schema_version = 2
			"duplicate_id": data.events[1].id = data.events[0].id
			"date": data.events[0].date = {"start": 10, "end": 0, "precision": "range", "label": "invalid"}
			"era": data.events[0].era_id = "absent"
			"path": data.events[0].media.path = "../escape.png"
			"kind": data.events[0].kind = "text_only"
			"sequence": data.events[0].sequence = 0.5
			"body": data.events[0].body = "x".repeat(100001)
			"transcript": data.events[2].media.erase("transcript")
			"noncontiguous": data.events[1].era_id = "renewal"
			"era_sections": data.events[18].era_id = "renewal"
		check(not loader.load_file(_fixture(data)), "Reject invalid " + mutation)
	var duplicate := FileAccess.open("user://duplicate.json", FileAccess.WRITE)
	duplicate.store_string('{"schema_version":1,"schema_version":1}')
	duplicate.close()
	check(not loader.load_file("user://duplicate.json") and loader.error.contains("Duplicate"), "Detect duplicate JSON properties before semantic validation")
	check(ArchiveDocument._has_duplicate_keys('{"a":1,"\\u0061":2}'), "Detect escaped duplicate properties")
	data = original.duplicate(true)
	data.events[0]["scene_path"] = "ignored"
	check(loader.load_file(_fixture(data)) and not loader.diagnostics.is_empty(), "Unknown fields are ignored with diagnostics")
	data = original.duplicate(true)
	data.events.clear()
	check(loader.load_file(_fixture(data)) and loader.events.is_empty(), "Empty document is valid")
	var imported_image: Texture2D = load("res://content/demo/media/library.png")
	imported_image.get_image().save_png("user://external-image.png")
	var external_video := FileAccess.open("user://external-video.ogv", FileAccess.WRITE)
	external_video.store_buffer(FileAccess.get_file_as_bytes("res://content/demo/media/calibration.ogv"))
	external_video.close()

	app = MAIN.instantiate()
	root.add_child(app)
	current_scene = app
	await tick(8)
	check(app.archive.events.size() == 20 and app.current == 0, "Fresh launch selects earliest")
	check(app.records.size() == 6, "Only six physical records are resident")
	await physics_frame
	for record: Node3D in app.records:
		var point: Vector2 = app.orbit.camera.unproject_position(record.get_node("Panel").global_position)
		check(app._pick(point) == record.event_index, "Mouse ray picks physical record " + str(record.event_index))
		var panel_position: Vector3 = record.get_node("Panel").global_position
		var left: Vector2 = app.orbit.camera.unproject_position(panel_position - app.orbit.camera.global_basis.x * 0.78)
		var right: Vector2 = app.orbit.camera.unproject_position(panel_position + app.orbit.camera.global_basis.x * 0.78)
		check(left.x >= 0 and right.x <= 1440, "Default framing contains complete record " + str(record.event_index))
	var click_point: Vector2 = app.orbit.camera.unproject_position(app.records[1].get_node("Panel").global_position)
	var click := InputEventMouseButton.new()
	click.position = click_point
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	var release := click.duplicate() as InputEventMouseButton
	release.pressed = false
	root.push_input(release, true)
	check(app.reader_open and app.current == 1, "Real pointer click opens a physical record")
	app.close_reader()
	app.navigate(0)
	var bottom: Control = app.hud.get_node("%Bottom")
	check(bottom.position.y >= 0 and bottom.size.y < root.size.y * 0.6, "HUD initial layout stays in viewport")
	app.hud.get_node("%ArchiveFocus").grab_focus()
	await key(KEY_RIGHT)
	check(app.current == 1, "Real keyboard Right navigates the archive")
	await key(KEY_END)
	check(app.current == 19, "Keyboard End reaches undated records")
	await key(KEY_HOME)
	await key(KEY_ENTER)
	check(app.reader_open and app.media.available, "Keyboard Enter opens an image reader")
	check(not app.media.video.is_playing(), "No autoplay")
	var current_before: int = app.current
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	app._unhandled_input(wheel)
	check(app.current == current_before, "Reader wheel cannot navigate the archive")
	app.toggle_enlarge()
	check(app.enlarged, "Media enlarges")
	await key(KEY_ESCAPE)
	check(not app.enlarged and app.reader_open, "First Escape returns from enlarged media")
	await key(KEY_ESCAPE)
	check(not app.reader_open, "Second Escape closes reader")
	app.orbit.azimuth = 2.4
	app.orbit.distance = 11.0
	app.orbit.elevation = 0.3
	var orbit_before: Dictionary = app.orbit.snapshot()
	app.open_current()
	check(app.orbit.azimuth == 0.0 and app.orbit.held, "Reader settles broadside and holds camera")
	app.reader_navigate(1)
	app.close_reader()
	check(app.current == 1 and app.orbit.snapshot() == orbit_before, "Closing restores orbit/zoom and newly read event")
	app.open_panel("Index")
	check(app.modal == "Index" and not bottom.visible, "Index owns focus and hides browse controls")
	app._open_index_row(app._index_map.find(2))
	check(app.reader_open and app.current == 2 and app.modal.is_empty(), "Index opens video record")
	check(app.media.available and not app.media.video.is_playing(), "Video ready without autoplay")
	app.media.toggle_play()
	await tick(5)
	check(app.media.video.is_playing() and not app.media.video.paused, "Theora playback starts")
	app.media.toggle_play()
	check(app.media.video.paused, "Video pauses")
	var stream: VideoStream = app.media.video.stream
	app.toggle_enlarge()
	check(app.media.video.stream == stream and app.media.video.paused, "Enlarge shares the same paused decoder")
	app.toggle_enlarge()
	app.media.set_preferences(0.25, true)
	check(app.media.video.volume_db == -80.0, "Video mute")
	app.media.restart_video()
	check(app.media.video.is_playing() and not app.media.video.paused, "Video restart")
	app.media._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(app.media.video.paused, "Application focus loss pauses video")
	app.close_reader()
	check(app.media.video.stream == null and app.media.get_node("%Image").texture == null, "Close releases media and decoder")
	app.navigate(8)
	app.open_current()
	check(not app.media.available and app.reader.get_node("%Body").text.contains("intentionally absent"), "Missing media preserves readable record")
	app.media.retry()
	check(not app.media.available and app.media.get_node("%Retry").visible, "Retry remains usable for missing media")
	app.close_reader()
	data = original.duplicate(true)
	data.events = [data.events[0]]
	data.events[0].media.path = "external-image.png"
	app.load_timeline(_fixture(data))
	app.open_current()
	check(app.media.available, "Runtime PNG loads from an external content package")
	app.close_reader()
	data.events = [original.events[2].duplicate(true)]
	data.events[0].media.path = "external-video.ogv"
	app.load_timeline(_fixture(data))
	app.open_current()
	app.media.toggle_play()
	await tick(4)
	check(app.media.available and app.media.video.is_playing(), "Runtime Theora plays from an external content package")
	app.close_reader()
	app.load_timeline("res://content/demo/timeline.json")
	app.navigate(5)
	var good: ArchiveDocument = app.archive
	data = original.duplicate(true)
	data.schema_version = 999
	app.load_timeline(_fixture(data))
	check(app.archive == good and app.current == 5, "Invalid reload retains previous document and selection")
	app.get_node("Interface/LoadError").hide()
	data = original.duplicate(true)
	data.events.reverse()
	app.load_timeline(_fixture(data))
	check(app.archive.events[app.current].id == "record-06", "Valid reload preserves stable event identity")
	# Use bundled media after testing external package replacement metadata.
	app.load_timeline("res://content/demo/timeline.json")
	for scale: float in [1.5, 2.0]:
		root.size = Vector2i(1280, 720)
		root.content_scale_size = Vector2i(1280, 720)
		app._text_scale = scale
		app._apply_preferences()
		app.open_current()
		await tick(8)
		var panel: Control = app.reader.get_node("Panel")
		check(panel.position.x >= 0 and panel.position.y >= 0 and panel.get_global_rect().end.x <= 1281 and panel.get_global_rect().end.y <= 721, "Reader fits at 1280x720, text scale " + str(scale))
		check(app.reader.get_node("%Columns").vertical, "Reader stacks at larger text scale")
		var close_button: Control = app.reader.get_node("%Close")
		check(close_button.get_global_rect().end.x <= 1280 and close_button.get_global_rect().end.y <= 720, "Close remains reachable at scale " + str(scale))
		app.reader.get_node("%Body").grab_focus()
		await key(KEY_PAGEDOWN)
		await tick(3)
		var scroll: ScrollContainer = app.reader.get_node("%ContentScroll")
		check(scroll.scroll_vertical > 0, "Keyboard scrolls body at scale " + str(scale))
		var saved_scroll: int = scroll.scroll_vertical
		app.toggle_enlarge()
		await tick(4)
		app.toggle_enlarge()
		await tick(8)
		check(scroll.scroll_vertical == saved_scroll, "Enlarge restores text scroll at scale " + str(scale))
		app.close_reader()
		await tick(4)
		check(bottom.get_global_rect().end.y <= 721 and bottom.position.y >= 0, "Browse toolbar reachable at scale " + str(scale))
	data = original.duplicate(true)
	data.events = [data.events[0]]
	data.events[0].title = "A very long record title ".repeat(8).left(200)
	data.events[0].date.label = "An uncertain date with a deliberately lengthy explanation ".repeat(12)
	data.timeline.title = "A very long archive title ".repeat(8).left(200)
	app.load_timeline(_fixture(data))
	app.open_current()
	await tick(8)
	check(app.reader.get_node("Panel").get_global_rect().end.y <= 721, "Long titles and dates fit the reader at 200%")
	check(app.reader.get_node("%ContentScroll").size.y > 80, "Long headings retain usable reading space")
	check(app.reader.get_node("%Body").text.contains(data.events[0].title), "Full title survives abbreviated presentation")
	app.close_reader()
	app._text_scale = 1.0
	app._apply_preferences()
	root.content_scale_size = Vector2i(1440, 900)
	for amount: int in [100, 1000]:
		data = original.duplicate(true)
		data.events.clear()
		data.eras = [original.eras[0]]
		for i: int in range(amount):
			var item: Dictionary = original.events[0].duplicate(true)
			item.id = "stress-%04d" % i
			item.date.start = i * 1000000
			data.events.append(item)
		app.load_timeline(_fixture(data, "stress.json"))
		for target: int in [0, amount - 1, amount / 2, 1, amount - 2]:
			app.navigate(target)
			await tick(2)
			check(app.records.size() == 6 and app.get_node("Records").get_child_count() == 6, "Bounded records during " + str(amount) + " event jumps")
			check(app.media.video.stream == null, "Stress browse allocates no decoders")
		check(app.records[0].position.length() < 10, "Large dates do not create large coordinates")
	data.events.clear()
	app.load_timeline(_fixture(data))
	check(app.archive.events.is_empty() and app.records.is_empty() and not app.get_node("Timeline").visible, "Empty archive clears physical records")
	print(JSON.stringify({"checks": checks, "failures": failures, "passed": failures.is_empty()}))
	app.queue_free()
	await tick(3)
	quit(0 if failures.is_empty() else 1)
