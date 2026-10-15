extends Node3D
## Coordinates object scenes, content, navigation, and modal input ownership.
const RECORD: PackedScene = preload("res://prototype/event_record.tscn")
const ERA_MARKER: PackedScene = preload("res://prototype/era_marker.tscn")
const DOCUMENT = preload("res://prototype/archive_document.gd")
const MAX_RECORDS: int = 6
const SLOT_PITCH: float = 1.9
const DEMO: String = "res://content/demo/timeline.json"
const SCALE_VALUES: Array[float] = [1.0, 1.25, 1.5, 2.0]

var archive: ArchiveDocument
var current: int = 0
var modal: String = ""
var reader_open: bool = false
var enlarged: bool = false
var records: Array[Node3D] = []
var _first_slot: int = -1
var _hovered: int = -1
var _dragging: bool = false
var _drag_distance: float = 0.0
var _press_position := Vector2.ZERO
var _camera_before_reader: Dictionary = {}
var _opener: Control
var _reader_opener: Control
var _index_map: Array[int] = []
var _theme: Theme
var _text_scale: float = 1.0
var _volume: float = 0.5
var _muted: bool = false
var _low_effects: bool = false
var _last_path: String = DEMO
var _reader_scroll: int = 0

@onready var orbit: Node3D = $OrbitCamera
@onready var hud: Control = $Interface/HUD
@onready var reader: Control = $Interface/Reader
@onready var index_panel: Control = $Interface/Index
@onready var settings: Control = $Interface/Settings
@onready var help_panel: Control = $Interface/Help
@onready var media: VBoxContainer = reader.get_node("%Media")

func _ready() -> void:
	_build_theme()
	_wire_controls()
	_load_preferences()
	load_timeline(DEMO)
	hud.get_node("%ArchiveFocus").grab_focus()
	get_viewport().size_changed.connect(_layout)
	hud.get_node("%Bottom").minimum_size_changed.connect(_layout)
	_layout.call_deferred()

func _wire_controls() -> void:
	_bind(hud, "First", func() -> void: navigate(0))
	_bind(hud, "Last", func() -> void: navigate(archive.events.size() - 1))
	_bind(hud, "Previous", func() -> void: navigate(current - 1))
	_bind(hud, "Next", func() -> void: navigate(current + 1))
	_bind(hud, "Open", open_current)
	_bind(hud, "Choose", func() -> void: $Interface/ChooseTimeline.popup_centered_ratio(0.8))
	_bind(hud, "Reset", func() -> void: orbit.reset_view())
	_bind(hud, "OrbitLeft", func() -> void: orbit.orbit(-0.3))
	_bind(hud, "OrbitRight", func() -> void: orbit.orbit(0.3))
	_bind(hud, "ZoomIn", func() -> void: orbit.zoom(-1.0))
	_bind(hud, "ZoomOut", func() -> void: orbit.zoom(1.0))
	for panel_name: String in ["Index", "Settings", "Help"]:
		_bind(hud, panel_name, open_panel.bind(panel_name))
	hud.get_node("%Overview").value_changed.connect(func(value: float) -> void:
		if not _blocked():
			navigate(int(value)))
	_bind(reader, "Previous", func() -> void: reader_navigate(-1))
	_bind(reader, "Next", func() -> void: reader_navigate(1))
	_bind(reader, "Close", close_top)
	_bind(reader, "Enlarge", toggle_enlarge)
	reader.get_node("%Body").gui_input.connect(_reader_body_input)
	_bind(index_panel, "Close", close_top)
	_bind(index_panel, "Open", _open_index_selection)
	index_panel.get_node("%List").item_clicked.connect(func(row: int, _at: Vector2, _button: int) -> void:
		_open_index_row(row))
	index_panel.get_node("%List").item_activated.connect(_open_index_row)
	_bind(settings, "Close", close_top)
	_bind(settings, "Choose", func() -> void: $Interface/ChooseTimeline.popup_centered_ratio(0.8))
	_bind(settings, "Reload", func() -> void: load_timeline(_last_path))
	settings.get_node("%TextScale").item_selected.connect(func(value: int) -> void:
		_text_scale = SCALE_VALUES[value]
		_apply_preferences()
		_save_preferences())
	settings.get_node("%ReducedMotion").toggled.connect(func(value: bool) -> void:
		orbit.reduced_motion = value
		_save_preferences())
	settings.get_node("%LowEffects").toggled.connect(func(value: bool) -> void:
		_low_effects = value
		_apply_preferences()
		_save_preferences())
	settings.get_node("%Volume").value_changed.connect(func(value: float) -> void:
		_media_preferences(value, _muted))
	settings.get_node("%Mute").toggled.connect(func(value: bool) -> void:
		_media_preferences(_volume, value))
	media.preferences_changed.connect(_media_preferences)
	_bind(help_panel, "Close", close_top)
	$Interface/ChooseTimeline.file_selected.connect(load_timeline)
	$Interface/ChooseTimeline.canceled.connect(func() -> void:
		if settings.visible:
			settings.get_node("%Choose").grab_focus()
		else:
			hud.get_node("%Choose").grab_focus())
	$Interface/LoadError.confirmed.connect(func() -> void:
		if modal == "Settings":
			settings.get_node("%Reload").grab_focus()
		else:
			hud.get_node("%ArchiveFocus").grab_focus())

func _bind(panel: Control, name: String, callback: Callable) -> void:
	panel.get_node("%" + name).pressed.connect(callback)

func load_timeline(path: String) -> void:
	var candidate: ArchiveDocument = DOCUMENT.new()
	if not candidate.load_file(path):
		if archive == null:
			for button_name: String in ["First", "Last", "Previous", "Next", "Open", "Index"]:
				hud.get_node("%" + button_name).disabled = true
			hud.get_node("%Current").text = "Choose a valid timeline to begin."
			hud.get_node("%Choose").show()
		$Interface/LoadError.dialog_text = candidate.error + "\n\nThe previous valid archive has been kept. Choose another file or fix it and Reload."
		$Interface/LoadError.popup_centered()
		return
	var selected_id := ""
	if archive != null and not archive.events.is_empty():
		selected_id = archive.events[current].id
	if reader_open:
		close_reader()
	archive = candidate
	_last_path = path
	current = 0
	for i: int in range(archive.events.size()):
		if archive.events[i].id == selected_id:
			current = i
	_first_slot = -1
	hud.get_node("%Title").text = archive.document.timeline.title
	settings.get_node("%Source").text = "Content: " + path + "\n" + archive.document.timeline.description
	settings.get_node("%Diagnostics").text = "\n".join(archive.diagnostics)
	_build_index()
	navigate(current)
	if archive.events.is_empty():
		hud.get_node("%Current").text = "This archive is empty. Choose a timeline in Settings."
		hud.get_node("%Era").text = "Empty archive"
		hud.get_node("%Settings").grab_focus()

func navigate(position_index: int) -> void:
	if archive == null:
		return
	current = clampi(position_index, 0, maxi(archive.events.size() - 1, 0))
	_refresh_records()
	var empty := archive.events.is_empty()
	hud.get_node("%Choose").visible = empty
	hud.get_node("%Index").disabled = empty
	for button_name: String in ["First", "Last", "Previous", "Next", "Open"]:
		hud.get_node("%" + button_name).disabled = empty
	hud.get_node("%First").disabled = empty or current == 0
	hud.get_node("%Previous").disabled = empty or current == 0
	hud.get_node("%Last").disabled = empty or current == archive.events.size() - 1
	hud.get_node("%Next").disabled = empty or current == archive.events.size() - 1
	hud.get_node("%Overview").max_value = maxi(archive.events.size() - 1, 1)
	hud.get_node("%Overview").editable = not empty
	hud.get_node("%Overview").set_value_no_signal(current)
	if not empty:
		var item: Dictionary = archive.events[current]
		hud.get_node("%Era").text = archive.era_title(item)
		hud.get_node("%Current").text = "%02d / %02d   ·   %s   ·   %s" % [current + 1, archive.events.size(), item.date.label, item.title]
		orbit.target.x = 0.0
	_update_emphasis()

func _refresh_records() -> void:
	var count := mini(MAX_RECORDS, archive.events.size())
	var first := clampi(current - count / 2, 0, maxi(archive.events.size() - count, 0))
	if first == _first_slot:
		return
	_first_slot = first
	for record: Node3D in records:
		record.get_parent().remove_child(record)
		record.queue_free()
	records.clear()
	for child: Node in $EraMarkers.get_children():
		$EraMarkers.remove_child(child)
		child.queue_free()
	# The rail length follows the bounded neighborhood, never total record count.
	$Timeline.module_count = maxi(1, ceili(float(count) * SLOT_PITCH / 2.0))
	$Timeline.visible = count > 0
	for slot: int in range(count):
		var event_index := first + slot
		var item: Dictionary = archive.events[event_index]
		var record := RECORD.instantiate() as Node3D
		$Records.add_child(record)
		record.position = Vector3((slot - float(count - 1) / 2.0) * SLOT_PITCH, 1.8, 0)
		var same_date: bool = event_index > 0 and item.date.start != null and archive.events[event_index - 1].date.start == item.date.start
		record.configure(item, event_index, same_date)
		records.append(record)
		if slot == 0 or item.get("era_id", "") != archive.events[event_index - 1].get("era_id", ""):
			var marker := ERA_MARKER.instantiate() as Node3D
			$EraMarkers.add_child(marker)
			marker.position = Vector3(record.position.x, 1.05, -0.05)
			marker.get_node("Label").text = archive.era_title(item).left(50)

func _process(_delta: float) -> void:
	for record: Node3D in records:
		record.face_camera(orbit.camera)
	if archive == null or archive.events.is_empty():
		return
	var direction := "Earlier ←   → Later"
	if absf(cos(orbit.azimuth)) < 0.25:
		direction = "End-on view · Use Index or Reset view"
	elif cos(orbit.azimuth) < 0:
		direction = "Later ←   → Earlier · Rear view"
	if archive.events[current].date.start == null:
		direction = "Undated records · No chronological position"
	hud.get_node("%Status").text = direction + " · Spacing is not to scale · Drag to orbit · Wheel to browse"

func open_current() -> void:
	if archive == null or archive.events.is_empty():
		return
	if not reader_open:
		_reader_opener = get_viewport().gui_get_focus_owner()
		_camera_before_reader = orbit.snapshot()
		orbit.reset_view()
		orbit.held = true
		reader_open = true
		reader.show()
		_set_hud_enabled(false)
	var item: Dictionary = archive.events[current]
	reader.get_node("%Title").text = item.title
	reader.get_node("%ContextStrip").text = "EARLIER   ←     %s  ·  %s     →   LATER" % [item.date.label, item.title] \
		if item.date.start != null else "UNDATED RECORDS   ·   " + item.title
	reader.get_node("%Date").text = archive.era_title(item) + "  ·  " + item.date.label + "  ·  %d / %d" % [current + 1, archive.events.size()]
	var text: String = item.title + "\n" + item.date.label + "\n\n" + item.summary + "\n\n" + item.body + "\n\nMEDIA DESCRIPTION\n" + item.media.description
	if item.kind == "video_text":
		text += "\n\nTRANSCRIPT\n" + item.media.transcript
	text += "\n\nMEDIA CREDIT\n" + item.media.credit.text
	for field: String in ["license", "source_url"]:
		if item.media.credit.has(field):
			text += "\n" + item.media.credit[field]
	if item.media.has("poster"):
		text += "\nPoster: " + item.media.poster.credit.text
	for source: Dictionary in item.get("sources", []):
		text += "\n\nSOURCE\n" + source.title
		for field: String in ["locator", "url"]:
			if source.has(field):
				text += "\n" + source[field]
	reader.get_node("%Body").text = text
	reader.get_node("%ContentScroll").scroll_vertical = 0
	reader.get_node("%Previous").disabled = current == 0
	reader.get_node("%Next").disabled = current == archive.events.size() - 1
	media.show_event(item, archive)
	media.set_preferences(_volume, _muted)
	reader.get_node("%Close").grab_focus()
	_update_emphasis()
	_layout()

func reader_navigate(direction: int) -> void:
	if enlarged:
		toggle_enlarge()
	navigate(current + direction)
	open_current()

func toggle_enlarge() -> void:
	if not enlarged:
		_reader_scroll = reader.get_node("%ContentScroll").scroll_vertical
	enlarged = not enlarged
	reader.get_node("%Body").visible = not enlarged
	reader.get_node("%Enlarge").text = "Return to reader" if enlarged else "Enlarge media"
	reader.get_node("%Previous").visible = not enlarged
	reader.get_node("%Next").visible = not enlarged
	reader.get_node("%Close").visible = not enlarged
	reader.get_node("%Enlarge").grab_focus()
	_layout()
	if not enlarged:
		_restore_reader_scroll()

func _restore_reader_scroll() -> void:
	# Wait for the restored text column to negotiate its height with the container.
	await get_tree().process_frame
	await get_tree().process_frame
	if reader_open and not enlarged:
		reader.get_node("%ContentScroll").scroll_vertical = _reader_scroll

func _reader_body_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.alt_pressed:
		return
	var scroll: ScrollContainer = reader.get_node("%ContentScroll")
	match event.keycode:
		KEY_DOWN: scroll.scroll_vertical += 48
		KEY_UP: scroll.scroll_vertical -= 48
		KEY_PAGEDOWN: scroll.scroll_vertical += int(scroll.size.y * 0.85)
		KEY_PAGEUP: scroll.scroll_vertical -= int(scroll.size.y * 0.85)
		KEY_HOME: scroll.scroll_vertical = 0
		KEY_END: scroll.scroll_vertical = int(reader.get_node("%Columns").size.y)
		_: return
	reader.get_node("%Body").accept_event()

func close_reader() -> void:
	if enlarged:
		toggle_enlarge()
	media.release()
	reader.hide()
	reader_open = false
	orbit.held = false
	orbit.restore(_camera_before_reader)
	_set_hud_enabled(true)
	_restore_focus(_reader_opener)
	_update_emphasis()

func open_panel(panel_name: String) -> void:
	if _blocked():
		return
	_opener = get_viewport().gui_get_focus_owner()
	modal = panel_name
	_set_hud_enabled(false)
	var panel: Control = get_node("Interface/" + panel_name)
	panel.show()
	if panel_name == "Index":
		var row := _index_map.find(current)
		if row >= 0:
			index_panel.get_node("%List").select(row)
			index_panel.get_node("%List").ensure_current_is_visible()
		index_panel.get_node("%List").grab_focus()
	else:
		panel.get_node("%Close").grab_focus()

func close_top() -> void:
	if $Interface/ChooseTimeline.visible or $Interface/LoadError.visible:
		return
	if not modal.is_empty():
		get_node("Interface/" + modal).hide()
		modal = ""
		_set_hud_enabled(true)
		_restore_focus(_opener)
	elif enlarged:
		toggle_enlarge()
	elif reader_open:
		close_reader()

func _restore_focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_visible_in_tree() and (not control is BaseButton or not control.disabled):
		control.grab_focus()
	else:
		hud.get_node("%ArchiveFocus").grab_focus()

func _set_hud_enabled(enabled: bool) -> void:
	# Hidden controls cannot remain in the modal's Tab cycle.
	hud.get_node("Bottom").visible = enabled
	hud.get_node("Top").visible = enabled
	hud.get_node("%ArchiveFocus").focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE

func _build_index() -> void:
	var list: ItemList = index_panel.get_node("%List")
	list.clear()
	_index_map.clear()
	for child: Node in index_panel.get_node("%EraRow").get_children():
		child.queue_free()
	var previous_group := ""
	for i: int in range(archive.events.size()):
		var item: Dictionary = archive.events[i]
		var group := archive.era_title(item)
		if group != previous_group:
			list.add_item(group.to_upper())
			list.set_item_selectable(list.item_count - 1, false)
			list.set_item_custom_fg_color(list.item_count - 1, Color("68dae8"))
			_index_map.append(-1)
			# UI rows are reusable controls, not game-object hierarchies.
			var era_button := preload("res://prototype/era_jump.tscn").instantiate() as Button
			era_button.text = group
			era_button.pressed.connect(_jump_era.bind(i))
			index_panel.get_node("%EraRow").add_child(era_button)
			previous_group = group
		list.add_item("%02d   %s   ·   %s   [%s]" % [i + 1, item.date.label, item.title, "video" if item.kind == "video_text" else "image"])
		_index_map.append(i)
	for era_id: String in archive.eras:
		var has_events := false
		for item: Dictionary in archive.events:
			if item.get("era_id", "") == era_id:
				has_events = true
		if not has_events:
			list.add_item(archive.eras[era_id].title + " · Empty era")
			list.set_item_selectable(list.item_count - 1, false)
			_index_map.append(-1)

func _jump_era(event_index: int) -> void:
	close_top()
	navigate(event_index)

func _open_index_selection() -> void:
	var selected: PackedInt32Array = index_panel.get_node("%List").get_selected_items()
	if not selected.is_empty():
		_open_index_row(selected[0])

func _open_index_row(row: int) -> void:
	if row < 0 or row >= _index_map.size() or _index_map[row] < 0:
		return
	var target: int = _index_map[row]
	close_top()
	navigate(target)
	open_current()

func _blocked() -> bool:
	return reader_open or not modal.is_empty() or $Interface/ChooseTimeline.visible or $Interface/LoadError.visible

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_top()
			get_viewport().set_input_as_handled()
			return
		if reader_open:
			if event.alt_pressed and event.keycode in [KEY_LEFT, KEY_RIGHT] and not enlarged:
				reader_navigate(-1 if event.keycode == KEY_LEFT else 1)
				get_viewport().set_input_as_handled()
			return
		if _blocked():
			return
		# Toolbar and slider arrows retain their standard UI behavior.
		var focus := get_viewport().gui_get_focus_owner()
		if focus != hud.get_node("%ArchiveFocus") and focus != null and event.keycode != KEY_F1:
			return
		match event.keycode:
			KEY_LEFT, KEY_UP: navigate(current - 1)
			KEY_RIGHT, KEY_DOWN: navigate(current + 1)
			KEY_PAGEUP: navigate(current - 5)
			KEY_PAGEDOWN: navigate(current + 5)
			KEY_HOME: navigate(0)
			KEY_END: navigate(archive.events.size() - 1)
			KEY_ENTER, KEY_KP_ENTER: open_current()
			KEY_I: open_panel("Index")
			KEY_F1: open_panel("Help")
			KEY_R: orbit.reset_view()
			KEY_Q: orbit.orbit(-0.15)
			KEY_E: orbit.orbit(0.15)
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: orbit.zoom(-0.6)
			KEY_MINUS, KEY_KP_SUBTRACT: orbit.zoom(0.6)
			_: return
		get_viewport().set_input_as_handled()
	elif not _blocked() and event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var amount := -1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1
			if event.ctrl_pressed:
				orbit.zoom(amount * 0.6)
			else:
				navigate(current + amount)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_distance = 0.0
				_press_position = event.position
				hud.get_node("%ArchiveFocus").grab_focus()
			else:
				if _dragging and _drag_distance <= 6.0:
					var record_index := _pick(event.position)
					if record_index >= 0:
						navigate(record_index)
						open_current()
				_dragging = false
	elif not _blocked() and event is InputEventMouseMotion:
		if _dragging:
			_drag_distance = maxf(_drag_distance, event.position.distance_to(_press_position))
			if _drag_distance > 6.0:
				orbit.orbit(-event.relative.x * 0.006, event.relative.y * 0.003)
		else:
			var hit := _pick(event.position)
			if hit != _hovered:
				_hovered = hit
				_update_emphasis()

func _input(event: InputEvent) -> void:
	# Archive arrows run before Control's automatic directional focus navigation.
	if event is InputEventKey and event.pressed and not event.echo \
			and not $Interface/ChooseTimeline.visible and not $Interface/LoadError.visible:
		var focus := get_viewport().gui_get_focus_owner()
		if focus == hud.get_node("%ArchiveFocus") or event.keycode == KEY_ESCAPE \
				or event.keycode == KEY_F1 or (reader_open and event.alt_pressed):
			_unhandled_input(event)
	# Release over a toolbar must still end an archive drag, without activating a card.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		call_deferred("_finish_drag")

func _finish_drag() -> void:
	_dragging = false

func _pick(screen_position: Vector2) -> int:
	var from: Vector3 = orbit.camera.project_ray_origin(screen_position)
	var to: Vector3 = from + orbit.camera.project_ray_normal(screen_position) * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 16 | 32 | 64)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -1
	var node: Node = hit.collider
	while node != null and not node.is_in_group("archive_records"):
		node = node.get_parent()
	return int(node.event_index) if node != null else -1

func _update_emphasis() -> void:
	for record: Node3D in records:
		record.set_emphasis(record.event_index == current, record.event_index == _hovered, reader_open and record.event_index == current)

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var stack: bool = viewport_size.x < 1050.0 * _text_scale or enlarged
	reader.get_node("%Columns").vertical = stack
	media.custom_minimum_size.y = 250.0 if stack else 300.0
	reader.get_node("%Body").custom_minimum_size.x = 0.0 if stack else 260.0
	reader.get_node("%Body").custom_minimum_size.y = 240.0
	reader.get_node("Panel").offset_top = 60.0 if enlarged else 90.0
	hud.get_node("%Bottom").offset_top = -maxf(184.0, hud.get_node("%Bottom").get_combined_minimum_size().y)

func _media_preferences(value: float, muted: bool) -> void:
	_volume = value
	_muted = muted
	settings.get_node("%Volume").set_value_no_signal(value)
	settings.get_node("%Mute").set_pressed_no_signal(muted)
	media.set_preferences(value, muted)
	_save_preferences()

func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load("user://archive_settings.cfg") == OK:
		_text_scale = clampf(float(config.get_value("accessibility", "text_scale", 1.0)), 1.0, 2.0)
		orbit.reduced_motion = bool(config.get_value("accessibility", "reduced_motion", false))
		_low_effects = bool(config.get_value("accessibility", "low_effects", false))
		_volume = clampf(float(config.get_value("audio", "volume", 0.5)), 0.0, 1.0)
		_muted = bool(config.get_value("audio", "muted", false))
	settings.get_node("%ReducedMotion").set_pressed_no_signal(orbit.reduced_motion)
	settings.get_node("%LowEffects").set_pressed_no_signal(_low_effects)
	settings.get_node("%Mute").set_pressed_no_signal(_muted)
	settings.get_node("%Volume").set_value_no_signal(_volume)
	settings.get_node("%TextScale").select(maxi(SCALE_VALUES.find(_text_scale), 0))
	_apply_preferences()

func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("accessibility", "text_scale", _text_scale)
	config.set_value("accessibility", "reduced_motion", orbit.reduced_motion)
	config.set_value("accessibility", "low_effects", _low_effects)
	config.set_value("audio", "volume", _volume)
	config.set_value("audio", "muted", _muted)
	config.save("user://archive_settings.cfg")

func _apply_preferences() -> void:
	_theme.default_font_size = int(17.0 * _text_scale)
	for panel: Control in [hud, reader, index_panel, settings, help_panel]:
		for title: Node in panel.find_children("Title", "Label", true, false):
			title.add_theme_font_size_override("font_size", int(24 * _text_scale))
	var environment: Environment = $Atmosphere/WorldEnvironment.environment
	environment.glow_enabled = not _low_effects
	environment.fog_enabled = not _low_effects
	media.set_preferences(_volume, _muted)
	_layout()

func _build_theme() -> void:
	_theme = Theme.new()
	_theme.default_font_size = 17
	for type: String in ["Label", "Button", "RichTextLabel", "CheckButton", "OptionButton", "ItemList"]:
		_theme.set_color("font_color", type, Color("edf2f7"))
		_theme.set_color("font_focus_color", type, Color.WHITE)
		_theme.set_color("font_hover_color", type, Color.WHITE)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("101a29")
	panel.border_color = Color("304a5b")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(8)
	_theme.set_stylebox("panel", "PanelContainer", panel)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("192c3b")
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("294959")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("176277")
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = Color("68dae8")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	for type: String in ["Button", "OptionButton"]:
		_theme.set_stylebox("normal", type, normal)
		_theme.set_stylebox("hover", type, hover)
		_theme.set_stylebox("pressed", type, pressed)
		_theme.set_stylebox("focus", type, focus)
	_theme.set_stylebox("focus", "ItemList", focus)
	for panel_node: Control in [hud, reader, index_panel, settings, help_panel]:
		panel_node.theme = _theme

func get_prototype_state() -> Dictionary:
	return {"event_count": archive.events.size() if archive != null else 0, "current": current,
		"event_id": archive.events[current].id if archive != null and not archive.events.is_empty() else "",
		"record_count": records.size(), "first_slot": _first_slot, "modal": modal,
		"reader_open": reader_open, "enlarged": enlarged, "camera": orbit.snapshot(),
		"media_available": media.available, "video_playing": media.video.is_playing(),
		"video_paused": media.video.paused, "text_scale": _text_scale}
