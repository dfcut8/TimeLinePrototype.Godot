class_name ArchiveDocument
extends RefCounted
## Content-only V1 loader. A failed replacement never mutates the active document.

const MAX_BYTES: int = 10 * 1024 * 1024
var document: Dictionary = {}
var events: Array[Dictionary] = []
var eras: Dictionary = {}
var package_dir: String = ""
var source_path: String = ""
var error: String = ""
var diagnostics: PackedStringArray = []

func load_file(path: String) -> bool:
	error = ""
	diagnostics.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("Cannot open timeline: " + path.get_file())
	if file.get_length() > MAX_BYTES:
		return _fail("Timeline exceeds the 10 MiB limit.")
	var text := file.get_as_text()
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return _fail("JSON line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
	if _has_duplicate_keys(text):
		return _fail("Duplicate JSON property. Each object must use unique field names.")
	var previous_package := package_dir
	package_dir = path.get_base_dir()
	if not validate(parser.data):
		package_dir = previous_package
		return false
	source_path = path
	package_dir = path.get_base_dir()
	return true

func validate(value: Variant) -> bool:
	if not value is Dictionary:
		return _fail("Document must be a JSON object.")
	var data: Dictionary = value
	if not _integer(data.get("schema_version")) or data.get("schema_version") != 1:
		return _fail("schema_version must be 1.")
	if not data.get("timeline") is Dictionary or not data.get("eras") is Array or not data.get("events") is Array:
		return _fail("timeline, eras and events are required with object/array/array types.")
	var info: Dictionary = data.timeline
	for field: String in ["id", "title", "description", "language"]:
		if not _string(info, field, field != "description"):
			return _fail("timeline.%s must be a %sstring." % [field, "nonempty " if field != "description" else ""])
	if not _id(info.id) or info.title.length() > 200:
		return _fail("timeline.id is invalid or title exceeds 200 characters.")
	if not info.get("time_axis") is Dictionary:
		return _fail("timeline.time_axis is required.")
	for field: String in ["id", "label", "unit"]:
		if not _string(info.time_axis, field, true):
			return _fail("timeline.time_axis.%s is required." % field)
	_unknown(info, ["id", "title", "description", "language", "time_axis"], "timeline")
	_unknown(info.time_axis, ["id", "label", "unit"], "timeline.time_axis")
	var next_eras: Dictionary = {}
	for era: Variant in data.eras:
		if not era is Dictionary or not _string(era, "id", true) or not _string(era, "title", true):
			return _fail("Every era needs an id and title.")
		if not _id(era.id) or next_eras.has(era.id):
			return _fail("Invalid or duplicate era id: " + str(era.id))
		if era.has("description") and not era.description is String:
			return _fail("era.description must be text.")
		next_eras[era.id] = era
		_unknown(era, ["id", "title", "description"], "eras." + era.id)
	if data.events.size() > 10000:
		return _fail("Timeline exceeds 10,000 events.")
	var next_events: Array[Dictionary] = []
	var ids: Dictionary = {}
	for i: int in range(data.events.size()):
		var item: Variant = data.events[i]
		var location := "events[%d]" % i
		if not item is Dictionary:
			return _fail(location + " must be an object.")
		for field: String in ["id", "kind", "title", "summary", "body"]:
			if not _string(item, field, field in ["id", "kind", "title"]):
				return _fail(location + "." + field + " must be text.")
		location += " (" + item.id + ")"
		if not _id(item.id) or ids.has(item.id):
			return _fail(location + ": invalid or duplicate id.")
		ids[item.id] = true
		if item.kind not in ["image_text", "video_text"]:
			return _fail(location + ".kind must be image_text or video_text.")
		if item.title.length() > 200 or item.summary.length() > 1000 or item.body.length() > 100000:
			return _fail(location + ": title/summary/body exceeds the content limits.")
		if not _integer(item.get("sequence")) or item.sequence < 0:
			return _fail(location + ".sequence must be a nonnegative integer.")
		if not _date(item.get("date")):
			return _fail(location + ".date is invalid (check precision, start, end and label).")
		_unknown(item.date, ["start", "end", "label", "precision"], location + ".date")
		if item.has("era_id") and (not item.era_id is String or not next_eras.has(item.era_id)):
			return _fail(location + ".era_id does not resolve.")
		if not _media(item.get("media"), item.kind == "video_text"):
			return _fail(location + ".media is invalid; use package-relative PNG/JPEG or .ogv paths, description and credit, plus a video transcript.")
		if item.has("sources"):
			if not item.sources is Array:
				return _fail(location + ".sources must be an array.")
			for source: Variant in item.sources:
				if not source is Dictionary or not _string(source, "title", true):
					return _fail(location + ": source title is required.")
				if source.has("locator") and not source.locator is String:
					return _fail(location + ": source locator must be text.")
				if source.has("url") and (not source.url is String or not source.url.begins_with("https://")):
					return _fail(location + ": source URL must use HTTPS.")
				_unknown(source, ["title", "locator", "url"], location + ".sources")
		_unknown(item, ["id", "kind", "title", "summary", "body", "date", "sequence", "era_id", "media", "sources"], location)
		next_events.append(item)
	next_events.sort_custom(_before)
	var closed_groups: Dictionary = {}
	var active_group := ""
	for item: Dictionary in next_events:
		var group: String = str(item.get("era_id", "_unassigned"))
		# Unassigned dated/undated sections are independent. Named eras may not cross.
		if group == "_unassigned" and item.date.start == null:
			group = "_undated"
		if group != active_group:
			if closed_groups.has(group):
				return _fail("Era membership must be contiguous: " + group)
			closed_groups[active_group] = true
			active_group = group
	for era_id: String in next_eras:
		var sections: Dictionary = {}
		for item: Dictionary in next_events:
			if item.get("era_id", "") == era_id:
				sections[item.date.start == null] = true
		if sections.size() > 1:
			return _fail("Era spans dated and undated records: " + era_id)
	_unknown(data, ["schema_version", "timeline", "eras", "events"], "document")
	document = data
	events = next_events
	eras = next_eras
	return true

func resolve_media(relative_path: String) -> String:
	if not safe_path(relative_path) or not _inside_package(relative_path):
		return ""
	return package_dir.path_join(relative_path).simplify_path()

static func safe_path(path: String) -> bool:
	return not path.is_empty() and not path.is_absolute_path() and not ":" in path \
		and not "\\" in path and not ".." in path.split("/") and not path.begins_with("/")

func _inside_package(path: String) -> bool:
	if package_dir.is_empty() or package_dir.begins_with("res://"):
		return true
	var base := _canonical_path(ProjectSettings.globalize_path(package_dir))
	var target := _canonical_path(ProjectSettings.globalize_path(package_dir.path_join(path)))
	if OS.get_name() == "Windows":
		base = base.to_lower()
		target = target.to_lower()
	return not base.is_empty() and not target.is_empty() and target.begins_with(base.trim_suffix("/") + "/")

static func _canonical_path(path: String, depth: int = 0) -> String:
	if depth > 32:
		return ""
	var fs := DirAccess.open(ProjectSettings.globalize_path("user://"))
	if fs == null:
		return ""
	var parts := path.replace("\\", "/").simplify_path().split("/", false)
	var prefix := "/" if path.begins_with("/") else ""
	for i: int in range(parts.size()):
		prefix = prefix.path_join(parts[i])
		if prefix.ends_with(":"):
			prefix += "/"
		if fs.is_link(prefix):
			var target := fs.read_link(prefix).replace("\\", "/")
			if not target.is_absolute_path():
				target = prefix.get_base_dir().path_join(target)
			for remainder: int in range(i + 1, parts.size()):
				target = target.path_join(parts[remainder])
			return _canonical_path(target, depth + 1)
	return prefix.simplify_path()

func era_title(event: Dictionary) -> String:
	if event.date.start == null:
		return "Undated records"
	return str(eras.get(event.get("era_id", ""), {}).get("title", "Archive records"))

func _media(value: Variant, video: bool) -> bool:
	if not value is Dictionary:
		return false
	if not _string(value, "path", true) or not safe_path(value.path) or not _inside_package(value.path) or not _string(value, "description", true) or not _credit(value.get("credit")):
		return false
	var extension: String = value.path.get_extension().to_lower()
	if video:
		if extension != "ogv" or not _string(value, "transcript", true) or value.transcript.length() > 100000:
			return false
		if value.has("poster") and not _media(value.poster, false):
			return false
	elif extension not in ["png", "jpg", "jpeg"]:
		return false
	_unknown(value, ["path", "description", "credit", "poster", "transcript"] if video else ["path", "description", "credit"], "media")
	return true

func _credit(value: Variant) -> bool:
	if not value is Dictionary or not _string(value, "text", false):
		return false
	for field: String in ["license", "source_url"]:
		if value.has(field) and not value[field] is String:
			return false
	if value.has("source_url") and not value.source_url.begins_with("https://"):
		return false
	_unknown(value, ["text", "source_url", "license"], "media.credit")
	return true

func _date(value: Variant) -> bool:
	if not value is Dictionary or not _string(value, "label", true) or not value.has("start"):
		return false
	var precision: Variant = value.get("precision")
	if precision == "unknown":
		return value.start == null and not value.has("end")
	if precision not in ["exact", "approximate", "range"] or not _number(value.start):
		return false
	if precision == "range":
		return _number(value.get("end")) and value.end >= value.start
	return not value.has("end")

static func _before(a: Dictionary, b: Dictionary) -> bool:
	var x: Variant = a.date.start
	var y: Variant = b.date.start
	if (x == null) != (y == null):
		return x != null
	if x != null and x != y:
		return x < y
	if a.sequence != b.sequence:
		return a.sequence < b.sequence
	return a.id < b.id

static func _string(d: Dictionary, key: String, nonempty: bool) -> bool:
	return d.get(key) is String and (not nonempty or not d[key].strip_edges().is_empty())

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and absf(float(value)) <= 9007199254740991.0

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floorf(float(value))

static func _id(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[a-z][a-z0-9_-]*$")
	return regex.search(value) != null

func _fail(message: String) -> bool:
	error = message
	return false

func _unknown(d: Dictionary, known: Array, location: String) -> void:
	for key: String in d:
		if key not in known:
			diagnostics.append(location + "." + key + " ignored (unknown V1 field).")

static func _has_duplicate_keys(text: String) -> bool:
	# Parse has already established syntax. Track object scopes and decoded key strings.
	var stack: Array[Dictionary] = []
	var i: int = 0
	while i < text.length():
		var c := text[i]
		if c == "{" or c == "[":
			stack.append({"object": c == "{", "keys": {}})
		elif c == "}" or c == "]":
			stack.pop_back()
		elif c == "\"":
			var start: int = i
			i += 1
			while i < text.length():
				if text[i] == "\\":
					i += 2
					continue
				if text[i] == "\"":
					break
				i += 1
			var j := i + 1
			while j < text.length() and text[j] in [" ", "\t", "\n", "\r"]:
				j += 1
			if j < text.length() and text[j] == ":" and not stack.is_empty() and stack.back().object:
				var key: String = JSON.parse_string(text.substr(start, i - start + 1))
				if stack.back().keys.has(key):
					return true
				stack.back().keys[key] = true
		i += 1
	return false
