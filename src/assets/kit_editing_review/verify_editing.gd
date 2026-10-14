extends "res://assets/catalog_perimeter_review/verify_catalog.gd"
## Import, lifecycle and serialized-configuration evidence for four issue tasks.
const EDIT_OUT := "res://assets/kit_editing_review/"
const EDIT_ARC: PackedScene = preload("res://assets/wall_infill_bay/configurable_bay_arc.tscn")
const SINGLE_STATION: PackedScene = preload("res://assets/catalog_lectern/single_record_catalog_station.tscn")
const EMPTY_DISPLAY: PackedScene = preload("res://assets/archive_display_plinth/empty_archive_display.tscn")
var editing_cases: Array[String] = []
var portal_probe_count: int = 0
var variant_floor_probes: int = 0

func ids(container: Node) -> Array[int]:
	var result: Array[int] = []
	for child in container.get_children():
		if child is Node3D and not child.scene_file_path.is_empty():
			result.append(child.get_instance_id())
	return result

func verify_arc_lifetime() -> void:
	var arc := EDIT_ARC.instantiate() as Node3D
	root.add_child(arc)
	var bay_ids := ids(arc.get_node("Bays"))
	var pier_ids := ids(arc.get_node("Piers"))
	var wall := arc.get_node("Bays/Bay0") as Node3D
	var portal := arc.get_node("Bays/Bay1") as Node3D
	var child_marker := Marker3D.new()
	child_marker.name = "RetainedPortalAddition"
	portal.add_child(child_marker)
	wall.set_meta("review_note", "retain on unrelated edits")
	var persistent := attachment(arc)
	var bay_addition := attachment(arc, "Bays")
	var portal_method_bounds: AABB = portal.call("get_approach_bounds")
	for angle in [-180.0, -37.0, 0.0, 91.0, 180.0]:
		arc.set("start_angle_degrees", angle)
		check(ids(arc.get_node("Bays")) == bay_ids, "Angle preserves every bay identity")
		check(ids(arc.get_node("Piers")) == pier_ids, "Angle preserves every pier identity")
		check(is_instance_valid(child_marker), "Portal additions survive arc rotation")
		check(portal.call("get_approach_bounds") == portal_method_bounds, "Portal local fit bounds survive rotation")
		var portal_in_arc := arc.global_transform.affine_inverse() * portal.global_transform
		var expected_angle := deg_to_rad(angle + 15.0)
		var radius := 24.8 * cos(deg_to_rad(7.5))
		check(portal_in_arc.origin.distance_to(Vector3(radius * sin(expected_angle), 0, -radius * cos(expected_angle))) < EPS, "Retained portal follows grid")
	editing_cases.append("five angle edits retain all bays/piers, metadata and portal additions")
	arc.set("bay_layout", PackedInt32Array([0, 1, 0]))
	check(ids(arc.get_node("Bays")).slice(0, 2) == bay_ids.slice(0, 2), "Unchanged wall and portal retained")
	check(ids(arc.get_node("Bays"))[2] != bay_ids[2], "Changed window replaced by wall")
	check(ids(arc.get_node("Piers")) == pier_ids, "Layout type edit retains all piers")
	check(wall.get_meta("review_note") == "retain on unrelated edits", "Wall override survives neighbor replacement")
	var edited_ids := ids(arc.get_node("Bays"))
	arc.set("bay_layout", PackedInt32Array([0, 1, 0, 2]))
	check(ids(arc.get_node("Bays")).slice(0, 3) == edited_ids, "Growing sector retains shared prefix")
	arc.set("bay_layout", PackedInt32Array([0, 1]))
	check(ids(arc.get_node("Bays")) == bay_ids.slice(0, 2), "Shrinking sector retains surviving prefix")
	check(ids(arc.get_node("Piers")) == pier_ids.slice(0, 3), "Shrinking sector retains surviving piers")
	editing_cases.append("type edits, growth and shrink replace only affected objects")
	# These container edits previously moved bays away from their resolved grid.
	(arc.get_node("Bays") as Node3D).transform = Transform3D(Basis(Vector3.UP, .31), Vector3(3, 2, -1))
	(arc.get_node("Piers") as Node3D).transform = Transform3D(Basis(Vector3.UP, -.43), Vector3(-2, 1, 4))
	arc.set("start_angle_degrees", -15.0)
	var reference := EDIT_ARC.instantiate() as Node3D
	reference.set("bay_layout", PackedInt32Array([0, 1]))
	root.add_child(reference)
	for path in ["Bays/Bay0", "Bays/Bay1", "Piers/Pier0", "Piers/Pier1", "Piers/Pier2"]:
		check((arc.get_node(path) as Node3D).global_transform.is_equal_approx((reference.get_node(path) as Node3D).global_transform), "Edited containers preserve resolved placement " + path)
	check(is_instance_valid(persistent) and is_instance_valid(bay_addition), "Root and container additions survive reconciliation")
	editing_cases.append("transformed containers preserve bay/pier grid and user additions")
	# Full-circle closure has no duplicate final pier; transition both directions.
	var ring_layout := PackedInt32Array()
	ring_layout.resize(24)
	arc.set("bay_layout", ring_layout)
	var ring_piers := ids(arc.get_node("Piers"))
	check(ring_piers.size() == 24, "Closed ring has 24 shared piers")
	ring_layout.resize(23)
	arc.set("bay_layout", ring_layout)
	check(ids(arc.get_node("Piers")) == ring_piers, "Ring to open sector retains all 24 piers")
	ring_layout.resize(24)
	arc.set("bay_layout", ring_layout)
	check(ids(arc.get_node("Piers")) == ring_piers, "Open sector to ring retains all 24 piers")
	var restored := disk_copy(arc, "edited_arc")
	check(ids(restored.get_node("Bays")).size() == 24 and ids(restored.get_node("Piers")).size() == 24, "Disk reload rebuilds ring exactly once")
	check(restored.has_node("Attachments/UserAttachment"), "Arc root attachment serialized")
	check(restored.has_node("Bays/UserAttachment"), "Arc container attachment serialized")
	check(is_instance_valid(persistent), "Original arc independent of disk copy")
	editing_cases.append("23/24 bay closure transitions and disk roundtrip retain correct objects")
	arc.queue_free()
	reference.queue_free()
	restored.queue_free()
	await process_frame

func inspect_portal_interface(portal: Node3D, space: Node3D) -> void:
	var opening: AABB = portal.call("get_opening_bounds")
	var approach: AABB = portal.call("get_approach_bounds")
	check(opening == AABB(Vector3(-1.5, 0, -.123), Vector3(3, 3.4, .246)), "Resolved local opening interface")
	check(approach.position.z == portal.get_node("OutsideApproach").position.z and approach.end.z == portal.get_node("InsideApproach").position.z, "Approach bounds agree with existing end markers")
	check(opening.get_center().distance_to(portal.get_node("OpeningCentre").position) < EPS, "Opening centre marker agrees")
	for fx in [.01, .5, .99]:
		for fy in [.001, .5, .999]:
			var x := lerpf(opening.position.x, opening.end.x, fx)
			var y := lerpf(opening.position.y, opening.end.y, fy)
			check(not segment_hits(portal, portal.to_global(Vector3(x, y, approach.position.z)), portal.to_global(Vector3(x, y, approach.end.z))), "Imported opening is unobstructed")
			portal_probe_count += 1
	# Boundary controls hit solid jambs/header instead of just trusting AABBs.
	for point in [Vector2(-1.501, 1.7), Vector2(1.501, 1.7), Vector2(0, 3.401)]:
		check(segment_hits(portal, portal.to_global(Vector3(point.x, point.y, -1)), portal.to_global(Vector3(point.x, point.y, 1))), "Imported jamb/header outside opening")
		portal_probe_count += 1
	for x in [-1.49, 0.0, 1.49]:
		for fraction in [0.0, .25, .5, .75, 1.0]:
			var point := space.to_local(portal.to_global(Vector3(x, 0, lerpf(approach.position.z, approach.end.z, fraction))))
			check(floor_supported(point), "Full portal approach supported by imported floor")
			variant_floor_probes += 1

func inspect_empty(display: Node3D) -> void:
	check(not bool(display.get("show_cassette")), "Empty display configured")
	check(not display.has_node("RecordSlot/Cassette"), "Empty display has no cassette")
	check(display.has_node("Plinth/TopContact"), "Empty display retains plinth contact interface")
	check(local_bounds(display.get_node("Plinth"), display).size.distance_to(Vector3(.7, .6, .55)) < .001, "Empty plinth keeps imported dimensions")

func verify_empty_display() -> void:
	var display := EMPTY_DISPLAY.instantiate() as Node3D
	root.add_child(display)
	inspect_empty(display)
	var sentinel := attachment(display, "RecordSlot")
	var plinth_id := display.get_node("Plinth").get_instance_id()
	for size in range(3):
		display.set("cassette_size", size)
		display.set("cassette_yaw_degrees", 67.0)
		inspect_empty(display)
		display.set("show_cassette", true)
		inspect_display(display, size, "empty to occupied %d" % size)
		display.set("show_cassette", true)
		check(display.get_node("RecordSlot").get_child_count() == 2, "Repeated enable creates no duplicate")
		display.set("show_cassette", false)
		inspect_empty(display)
		check(display.get_node("RecordSlot").get_child_count() == 1 and is_instance_valid(sentinel), "Emptying preserves slot attachment only")
		check(display.get_node("Plinth").get_instance_id() == plinth_id, "Toggling preserves plinth identity")
	editing_cases.append("empty plinth toggles all three cassette sizes with imported top support")
	root.remove_child(display)
	display.set("cassette_size", 1)
	display.set("cassette_yaw_degrees", -83.0)
	root.add_child(display)
	var restored := disk_copy(display, "empty_display")
	inspect_empty(restored)
	check(restored.has_node("RecordSlot/UserAttachment"), "Empty display serializes attachment")
	restored.set("show_cassette", true)
	inspect_display(restored, 1, "empty disk copy restored occupation")
	check(not display.get("show_cassette"), "Restored occupancy independent of source")
	editing_cases.append("empty state, saved size/yaw and attachments survive detachment and disk reload")
	display.queue_free()
	restored.queue_free()
	await process_frame

func inspect_single_station(station: Node3D, space: Node3D) -> void:
	check(is_equal_approx(float(station.get("display_spacing")), 1.1) and is_equal_approx(float(station.get("lectern_offset")), .7), "Saved furniture spacing retained")
	check(station.get("left_cassette_size") == 1 and station.get("left_cassette_yaw") == -45.0, "Saved cassette variant retained")
	inspect_display(station.get_node("DisplayLeft"), 1, "single record station")
	inspect_empty(station.get_node("DisplayRight"))
	var approach: AABB = station.call("get_approach_bounds")
	for path in ["Lectern", "DisplayLeft/Plinth", "DisplayRight/Plinth"]:
		var object := station.get_node(path) as Node3D
		var box := local_bounds(object, object)
		var in_station := local_bounds(object, station)
		check(not approach.intersects(in_station), "Saved variant user approach clear")
		for x in [-.1, 0.0, .1]:
			var point := space.to_local(object.to_global(Vector3(x, box.position.y, 0)))
			check(floor_supported(point), "Variant furniture on actual floor")
			variant_floor_probes += 1

func verify_template() -> void:
	var review := (load(EDIT_OUT + "review_entrance.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var entrance := review.get_node("Entrance") as Node3D
	cache_floor(review.get_node("Floor"), review)
	var wall_id := entrance.get_node("Architecture/Bays/Bay0").get_instance_id()
	for placement in [Transform3D.IDENTITY, Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))]:
		review.transform = placement
		for index in [0, 2]:
			var station := entrance.get_node("Stations/Station%d" % index) as Node3D
			check(station.scene_file_path == SINGLE_STATION.resource_path, "Perimeter instances authored scene variant")
			inspect_single_station(station, review)
		inspect_portal_interface(entrance.get_node("Architecture/Bays/Bay1"), review)
	editing_cases.append("saved template and portal bounds fit imported surfaces under two parent transforms")
	var station_id := entrance.get_node("Stations/Station0").get_instance_id()
	entrance.set("start_angle_degrees", 31.0)
	check(entrance.get_node("Stations/Station0").get_instance_id() == station_id, "Angle retains authored station identity")
	entrance.set("bay_layout", PackedInt32Array([1, 1, 0]))
	check(not entrance.has_node("Stations/Station0"), "Portal exclusion still removes station")
	entrance.set("bay_layout", PackedInt32Array([0, 1, 0]))
	check(entrance.get_node("Stations/Station0").scene_file_path == SINGLE_STATION.resource_path, "Dormant station restores authored variant")
	entrance.set("station_scene", null)
	check(entrance.get_node("Stations/Station0").scene_file_path == CONFIG_STATION.resource_path, "Null template restores default station")
	check(bool(entrance.get_node("Stations/Station0").get("right_show_cassette")), "Default populated state restored")
	var unaffected_wall_id := entrance.get_node("Architecture/Bays/Bay2").get_instance_id()
	entrance.set("station_scene", EDIT_ARC)
	check(entrance.get_node("Stations/Station0").scene_file_path == CONFIG_STATION.resource_path, "Incompatible scene uses valid default station")
	check(not (entrance.call("_get_configuration_warnings") as PackedStringArray).is_empty(), "Incompatible template has Inspector explanation")
	entrance.set("station_scene", SINGLE_STATION)
	check((entrance.call("_get_configuration_warnings") as PackedStringArray).is_empty(), "Valid template clears Inspector explanation")
	check(entrance.get_node("Architecture/Bays/Bay2").get_instance_id() == unaffected_wall_id, "Template switch retains architecture")
	check(wall_id != entrance.get_node("Architecture/Bays/Bay0").get_instance_id(), "Changed wall type actually replaced")
	entrance.set("start_angle_degrees", -15.0)
	var restored := disk_copy(entrance, "single_record_entrance")
	check(restored.get("station_scene") == SINGLE_STATION, "Station template serialized")
	check(restored.get_node("Stations").get_child_count() == 2, "Template disk reload creates exactly two stations")
	check(not restored.get_node("Stations/Station0/DisplayRight").has_node("RecordSlot/Cassette"), "Empty template side serialized through perimeter")
	root.remove_child(restored)
	restored.set("bay_layout", PackedInt32Array([0, 0]))
	restored.set("station_bays", PackedInt32Array([1]))
	root.add_child(restored)
	check(restored.get_node("Stations").get_child_count() == 1 and restored.has_node("Stations/Station1"), "Detached template reconfiguration has correct stations")
	editing_cases.append("template persists through portal exclusion, reset, disk reload and detached edits")
	restored.queue_free()
	review.transform = Transform3D.IDENTITY
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await editing_capture(camera, "entrance", Vector3(0, 4, -15), Vector3(0, 1.7, -24.6))
	var station := entrance.get_node("Stations/Station0") as Node3D
	await editing_capture(camera, "station", station.to_global(Vector3(0, 2.1, 4.5)), station.to_global(Vector3(0, .55, 0)))
	await editing_capture(camera, "rear", station.to_global(Vector3(-3, 2, -2)), station.to_global(Vector3(0, .55, 0)))
	for path in ["Architecture/Bays/Bay0", "Architecture/Bays/Bay1", "Stations/Station0/Lectern", "Stations/Station0/DisplayLeft", "Stations/Station0/DisplayRight"]:
		bounds(entrance.get_node(path), true)
	review.queue_free()
	await process_frame

func editing_capture(camera: Camera3D, label: String, position: Vector3, target: Vector3) -> void:
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 60.0
	camera.global_position = position
	camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(EDIT_OUT + "godot_" + label + ".png") == OK, "Editing GPU capture")

func verify() -> void:
	root.size = Vector2i(1100, 760)
	await verify_arc_lifetime()
	await verify_empty_display()
	await verify_template()
	var report := {"passed": failures.is_empty(), "failures": failures, "issues": [24, 25, 34, 36],
		"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"editing_cases": editing_cases, "portal_triangle_probes": portal_probe_count,
		"variant_floor_probes": variant_floor_probes, "display_cases": display_cases,
		"imported_meshes": meshes, "mcp": "Blender status/scene and Godot get_state unavailable; standalone Godot fallback",
		"limits": "Static model fit and configuration. Live MCP, final art approval, gameplay and performance remain pending."}
	FileAccess.open(EDIT_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Kit editing: %d cases; failures=%d" % [editing_cases.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
