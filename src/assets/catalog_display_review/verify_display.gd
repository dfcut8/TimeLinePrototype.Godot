extends "res://assets/grounded_room_review/verify_grounded.gd"
## Standalone engine evidence for reusable cassette displays and catalog stations.
const DISPLAY_OUT := "res://assets/catalog_display_review/"
const DISPLAY: PackedScene = preload("res://assets/archive_display_plinth/configurable_archive_display.tscn")
const SMALL_DISPLAY: PackedScene = preload("res://assets/archive_record_small/plinth_display.tscn")
const LARGE_DISPLAY: PackedScene = preload("res://assets/archive_record_large/plinth_display.tscn")
const STATION: PackedScene = preload("res://assets/catalog_lectern/catalog_comparison_station.tscn")
const RECORD_PATHS: Array[String] = [
	"res://assets/archive_record_small/archive_record_small.tscn",
	"res://assets/archive_record_medium/archive_record_medium.tscn",
	"res://assets/archive_record_large/archive_record_large.tscn",
]
const EPS: float = .0001
var display_cases: Array[Dictionary] = []
var station_cases: Array[Dictionary] = []
var lifecycle_cases: Array[String] = []
var contact_probe_count: int = 0

func floor_supported(point: Vector3) -> bool:
	var offset := Vector3(.00001, 0, .00001)
	return supported(point) or (supported(point + offset) and supported(point - offset))

func record_supported(display: Node3D) -> bool:
	var record := display.get_node("RecordSlot/Cassette") as Node3D
	var plinth := display.get_node("Plinth") as Node3D
	var bottom := local_bounds(record, record).position.y
	contact_probe_count = 0
	# The GLB merges authoring parts. Probe every flat bottom triangle's centroid
	# from actual imported vertices, independent of Blender component names.
	for child in record.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var to_record := record.global_transform.affine_inverse() * mesh.global_transform
		var faces := mesh.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var a := to_record * faces[i]
			var b := to_record * faces[i + 1]
			var c := to_record * faces[i + 2]
			if maxf(maxf(absf(a.y - bottom), absf(b.y - bottom)), absf(c.y - bottom)) > .00001:
				continue
			if absf((b - a).cross(c - a).normalized().y) < .999:
				continue
			var point := record.to_global((a + b + c) / 3.0)
			contact_probe_count += 1
			if not segment_hits(plinth, point + Vector3(0, EPS, 0), point - Vector3(0, EPS, 0)):
				return false
	return contact_probe_count >= 2

func inspect_display(display: Node3D, size: int, label: String) -> void:
	var slot := display.get_node("RecordSlot")
	var records := 0
	for child in slot.get_children():
		if child is Node3D and child.scene_file_path in RECORD_PATHS:
			records += 1
	check(records == 1, label + ": exactly one independent cassette")
	var record := slot.get_node("Cassette") as Node3D
	check(record.scene_file_path == RECORD_PATHS[size], label + ": requested size scene")
	check(record.owner == null, label + ": generated cassette is rebuilt on load")
	check(record.scale.is_equal_approx(Vector3.ONE), label + ": unit cassette scale")
	var plinth := display.get_node("Plinth") as Node3D
	var marker := plinth.get_node("TopContact") as Marker3D
	check(record.global_position.distance_to(marker.global_position) < EPS, label + ": contact marker interface")
	var top := part_bounds(plinth, "display_top", plinth)
	var box := local_bounds(record, plinth)
	var error := absf(box.position.y - top.end.y)
	var margin := minf(minf(box.position.x - top.position.x, top.end.x - box.end.x),
		minf(box.position.z - top.position.z, top.end.z - box.end.z))
	check(error < EPS, label + ": bottom/top contact within 0.1 mm")
	check(margin > .008, label + ": cassette footprint inside flat top")
	check(record_supported(display), label + ": actual bottom-face triangle probes")
	var expected := display.global_basis.inverse() * marker.global_basis \
		* Basis(Vector3.UP, deg_to_rad(float(display.get("cassette_yaw_degrees"))))
	var actual := display.global_basis.inverse() * record.global_basis
	check(actual.is_equal_approx(expected), label + ": yaw relative to contact frame")
	display_cases.append({"case": label, "size": size, "yaw_degrees": display.get("cassette_yaw_degrees"),
		"contact_error_m": error, "flat_top_edge_margin_m": margin, "bottom_face_probes": contact_probe_count})

func verify_configuration() -> void:
	var display := DISPLAY.instantiate() as Node3D
	display.set("cassette_size", 0)
	display.set("cassette_yaw_degrees", -30.0)
	root.add_child(display)
	inspect_display(display, 0, "configured before ready")
	var sentinel := Marker3D.new()
	sentinel.name = "UserAttachment"
	display.get_node("RecordSlot").add_child(sentinel)
	sentinel.owner = display
	for size in range(3):
		display.set("cassette_size", size)
		bounds(display.get_node("RecordSlot/Cassette"), true)
		for yaw in [-180.0, -90.0, -30.0, 0.0, 30.0, 90.0, 135.0, 180.0]:
			var record_id := display.get_node("RecordSlot/Cassette").get_instance_id()
			display.set("cassette_yaw_degrees", yaw)
			check(display.get_node("RecordSlot/Cassette").get_instance_id() == record_id, "Yaw preserves cassette instance")
			inspect_display(display, size, "size %d yaw %.0f" % [size, yaw])
			check(display.get_node("RecordSlot").get_child_count() == 2, "No accumulated generated records")
			check(is_instance_valid(sentinel) and sentinel.get_parent() == display.get_node("RecordSlot"), "User slot attachment preserved")
	# The diagonal XZ bound proves all yaw angles fit within the inset top rectangle.
	var record := display.get_node("RecordSlot/Cassette") as Node3D
	var record_box := local_bounds(record, record)
	var radius := Vector2(maxf(absf(record_box.position.x), absf(record_box.end.x)),
		maxf(absf(record_box.position.z), absf(record_box.end.z))).length()
	var top := part_bounds(display.get_node("Plinth"), "display_top", display)
	check(radius < minf(top.size.x, top.size.z) * .5 - .008, "Largest cassette footprint fits every yaw angle")
	lifecycle_cases.append("all three sizes and all-angle footprint bound")
	display.set("cassette_size", -7)
	display.set("cassette_yaw_degrees", -400.0)
	check(display.get("cassette_size") == 0 and display.get("cassette_yaw_degrees") == -180.0, "Lower configuration clamp")
	inspect_display(display, 0, "lower clamps")
	display.set("cassette_size", 99)
	display.set("cassette_yaw_degrees", 400.0)
	check(display.get("cassette_size") == 2 and display.get("cassette_yaw_degrees") == 180.0, "Upper configuration clamp")
	inspect_display(display, 2, "upper clamps")
	lifecycle_cases.append("invalid size/yaw clamps")
	# Different slot/plinth transforms rule out hard-coded world placement.
	(display.get_node("Plinth") as Node3D).position = Vector3(.08, .12, -.04)
	(display.get_node("RecordSlot") as Node3D).transform = Transform3D(Basis(Vector3.UP, .4), Vector3(-.2, .1, .1))
	display.set("cassette_yaw_degrees", 37.0)
	inspect_display(display, 2, "edited support and slot transforms")
	lifecycle_cases.append("contact and slot transform composition")
	(display.get_node("Plinth") as Node3D).transform = Transform3D.IDENTITY
	(display.get_node("RecordSlot") as Node3D).transform = Transform3D.IDENTITY
	display.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	display.set("cassette_size", 1)
	display.set("cassette_yaw_degrees", 67.0)
	inspect_display(display, 1, "transformed parent")
	var packed := PackedScene.new()
	check(packed.pack(display) == OK, "Pack display")
	check(ResourceSaver.save(packed, "user://display.tscn") == OK, "Save display")
	var restored := (load("user://display.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(restored)
	inspect_display(restored, 1, "disk roundtrip")
	check(restored.has_node("RecordSlot/UserAttachment") and restored.get_node("RecordSlot").get_child_count() == 2, "Roundtrip preserves attachment without duplicate record")
	restored.set("cassette_size", 0)
	inspect_display(restored, 0, "independent restored instance")
	check(display.get("cassette_size") == 1, "Original instance remains medium")
	lifecycle_cases.append("disk roundtrip and independent instances")
	root.remove_child(restored)
	restored.set("cassette_size", 2)
	restored.set("cassette_yaw_degrees", -45.0)
	root.add_child(restored)
	inspect_display(restored, 2, "detached update and reentry")
	lifecycle_cases.append("detached update and reentry")
	var restored_record := restored.get_node("RecordSlot/Cassette") as Node3D
	var seated := restored_record.transform
	restored_record.position.y += .01
	check(not record_supported(restored), "Floating cassette is rejected by surface support")
	restored_record.transform = seated
	restored_record.position.x += 1.0
	check(not record_supported(restored), "Cassette beyond plinth is rejected by surface support")
	restored_record.transform = seated
	lifecycle_cases.append("floating and unsupported negative controls")
	for scene in [SMALL_DISPLAY, LARGE_DISPLAY]:
		var variant := scene.instantiate() as Node3D
		root.add_child(variant)
		inspect_display(variant, 0 if scene == SMALL_DISPLAY else 2, "saved variant")
		variant.queue_free()
	bounds(display.get_node("Plinth"), true)
	display.queue_free()
	restored.queue_free()
	await process_frame

func inspect_station(station: Node3D, room: Node3D, obstacles: Array[Node]) -> void:
	inspect_display(station.get_node("SmallDisplay"), 0, str(station.name) + " small")
	inspect_display(station.get_node("LargeDisplay"), 2, str(station.name) + " large")
	var lectern := station.get_node("Lectern") as Node3D
	var marker := lectern.get_node("ScreenCenter") as Marker3D
	var normal := station.global_basis.inverse() * marker.global_basis.y
	check(normal.y > .95 and normal.z > .30, "Screen faces the station's user approach")
	check(segment_hits(lectern, marker.global_position + marker.global_basis.y * .001,
		marker.global_position - marker.global_basis.y * .001), "Screen marker lies on imported insert surface")
	var objects: Array[Node3D] = [lectern, station.get_node("SmallDisplay"), station.get_node("LargeDisplay")]
	var probes := 0
	var max_contact := 0.0
	for i in range(objects.size()):
		var object := objects[i]
		check(object.scale.is_equal_approx(Vector3.ONE), "Station object uses unit scale")
		var support_object: Node3D = object if i == 0 else object.get_node("Plinth")
		var foot := part_bounds(support_object, "recessed_floor_foot" if i == 0 else "recessed_foot", support_object)
		for fx in [.2, .5, .8]:
			for fz in [.2, .5, .8]:
				var point := room.to_local(support_object.to_global(Vector3(lerpf(foot.position.x, foot.end.x, fx),
					foot.position.y, lerpf(foot.position.z, foot.end.z, fz))))
				max_contact = maxf(max_contact, absf(point.y))
				check(floor_supported(point), "Actual floor below all station feet")
				probes += 1
		for j in range(i):
			check(not local_bounds(object, station).intersects(local_bounds(objects[j], station)), "Station furniture envelopes do not overlap")
	check(max_contact < EPS, "All three feet on floor datum within 0.1 mm")
	var box := local_bounds(station, station)
	var approach := AABB(Vector3(box.position.x, 0, box.end.z + .01), Vector3(box.size.x, 1.8, 1.0))
	var min_gap := INF
	for obstacle in obstacles:
		var other := local_bounds(obstacle as Node3D, station)
		check(not box.intersects(other), "Station clears existing room objects")
		check(not approach.intersects(other), "One-metre front user approach clears existing room objects")
		var dx := maxf(0, maxf(box.position.x - other.end.x, other.position.x - box.end.x))
		var dz := maxf(0, maxf(box.position.z - other.end.z, other.position.z - box.end.z))
		min_gap = minf(min_gap, Vector2(dx, dz).length())
	check(min_gap > 1.0, "Station stays more than one metre from existing furnishings and walls")
	for x in [box.position.x + .02, 0.0, box.end.x - .02]:
		for step in range(9):
			var point := room.to_local(station.to_global(Vector3(x, 0, approach.position.z + step * .125)))
			check(floor_supported(point), "Floor through user approach")
			probes += 1
	var in_room := local_bounds(station, room)
	var clear_radius := Vector2(clampf(0, in_room.position.x, in_room.end.x), clampf(0, in_room.position.z, in_room.end.z)).length()
	check(clear_radius > 20, "Station outside central 40 m clear diameter")
	station_cases.append({"station": str(station.name), "floor_probes": probes,
		"max_floor_contact_error_m": max_contact, "min_existing_object_gap_m": min_gap,
		"front_user_approach_depth_m": approach.size.z, "conservative_clear_radius_m": clear_radius,
		"envelope_m": [box.size.x, box.size.y, box.size.z]})

func save_view(camera: Camera3D, label: String, position: Vector3, target: Vector3, span: float = 0.0) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if span > 0 else Camera3D.PROJECTION_PERSPECTIVE
	camera.size = span if span > 0 else 5.0
	camera.fov = 60
	camera.global_position = position
	camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(DISPLAY_OUT + "godot_" + label + ".png") == OK, "GPU capture")

func verify() -> void:
	root.size = Vector2i(1280, 800)
	await verify_configuration()
	var review := (load("res://assets/catalog_display_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	var existing := room.get_node("Library") as Node3D
	var grounded := existing.get_node("Library") as Node3D
	var furnished := grounded.get_node("Furnishings") as Node3D
	var base := furnished.get_node("BaseRoom") as Node3D
	var obstacles: Array[Node] = base.get_node("Perimeter").get_children() + base.get_node("Shelves").get_children()
	for i in range(4):
		obstacles.append(furnished.get_node("Station%d" % i))
	for name in ["AlcoveEast", "AlcoveWest"]:
		obstacles.append(existing.get_node(name))
	for placement in [Transform3D.IDENTITY, Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))]:
		room.transform = placement
		cache_floor(grounded.get_node("Floor"), room)
		for name in ["StationNorth", "StationSouth"]:
			var station := room.get_node(name) as Node3D
			inspect_station(station, room, obstacles)
			for index in [0, 12]:
				var portal := base.get_node("Perimeter/Bay%d" % index) as Node3D
				check(not local_bounds(station, portal).intersects(AABB(Vector3(-1.5, 0, -1), Vector3(3, 3.4, 6))), "Station clears both portal approaches")
		check(not local_bounds(room.get_node("StationNorth"), room).intersects(local_bounds(room.get_node("StationSouth"), room)), "Stations clear each other")
	room.transform = Transform3D.IDENTITY
	cache_floor(grounded.get_node("Floor"), room)
	check(floor_supported(Vector3(2, 0, 2)), "Floor support positive control")
	check(not floor_supported(Vector3(2, .01, 2)), "Floating floor contact negative control")
	check(not floor_supported(Vector3(2, -.01, 2)), "Buried floor contact negative control")
	check(not floor_supported(Vector3(33, 0, 0)), "Absent floor negative control")
	bounds(room.get_node("StationNorth/Lectern"), true)
	var boxes: Array[AABB] = []
	for child in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		boxes.append(mesh.global_transform * mesh.mesh.get_aabb())
	var camera_min := INF
	var camera_samples := 0
	for radius in [12.0, 16.0, 19.0]:
		for height in [1.8, 4.0, 8.0]:
			for degrees in range(0, 360, 5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius * sin(angle), height, radius * cos(angle))
				for box in boxes:
					var nearest := Vector3(clampf(point.x, box.position.x, box.end.x), clampf(point.y, box.position.y, box.end.y), clampf(point.z, box.position.z, box.end.z))
					camera_min = minf(camera_min, point.distance_to(nearest) - .3)
				camera_samples += 1
	check(camera_min > 0, "All sampled camera envelopes clear complete room")
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	var north := room.get_node("StationNorth") as Node3D
	await save_view(camera, "overview", Vector3(38, 42, 45), Vector3.ZERO, 70)
	await save_view(camera, "station_front", north.to_global(Vector3(0, 2.1, 4.5)), north.to_global(Vector3(0, .55, .1)))
	await save_view(camera, "floor_contact", north.to_global(Vector3(2, .25, 2.0)), north.to_global(Vector3(0, .1, 0)))
	room.hide()
	var isolated := STATION.instantiate() as Node3D
	root.add_child(isolated)
	await save_view(camera, "isolated_rear", Vector3(-3, 2.4, -5), Vector3(0, .55, .1))
	await save_view(camera, "isolated_end", Vector3(5, 1.5, .5), Vector3(0, .55, .1))
	await save_view(camera, "isolated_underside", Vector3(2, -2, 3.5), Vector3(0, .5, .1))
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"passed": failures.is_empty(), "failures": failures, "issues": [31, 33, 34, 36],
		"display_cases": display_cases, "lifecycle_cases": lifecycle_cases, "station_placements": station_cases,
		"camera_samples": camera_samples, "camera_envelope_radius_m": .3, "min_camera_clearance_m": camera_min,
		"validated_imported_surfaces": meshes,
		"mcp": "Blender status/scene and Godot get_state failed; standalone Godot fallback",
		"limits": "Static imported fit; live MCP, art approval, interaction, physics and performance acceptance remain pending."}
	FileAccess.open(DISPLAY_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
