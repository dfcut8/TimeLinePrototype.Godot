extends "res://assets/catalog_display_review/verify_display.gd"
## Regression scenarios for four existing reusable object scenes.

const EDIT_OUT := "res://assets/assembly_editing_review/"
const EDIT_RAIL: PackedScene = preload("res://assets/timeline_rail_housing/configurable_timeline_rail.tscn")
const EDIT_ALCOVE: PackedScene = preload("res://assets/reading_bench/configurable_reading_alcove.tscn")
const EDIT_STATION: PackedScene = preload("res://assets/catalog_lectern/configurable_catalog_station.tscn")
var workflows: Array[String] = []
var rail_measurements: Array[Dictionary] = []
var aisle_measurements: Array[Dictionary] = []

func disk_copy(object: Node3D, label: String) -> Node3D:
	var packed := PackedScene.new()
	check(packed.pack(object) == OK, "Pack " + label)
	var path := "user://" + label + ".tscn"
	check(ResourceSaver.save(packed, path) == OK, "Save " + label)
	var restored := (load(path) as PackedScene).instantiate() as Node3D
	root.add_child(restored)
	return restored

func addition(parent: Node) -> Marker3D:
	var marker := Marker3D.new()
	marker.name = "UserAddition"
	parent.add_child(marker)
	return marker

func inspect_rail_fit(rail: Node3D, label: String) -> void:
	var count: int = rail.get("module_count")
	var offset: float = -count if rail.get("anchor_mode") == 1 else 0.0
	var previous_housing := AABB()
	var previous_light := AABB()
	var seam_error := 0.0
	for index in range(count):
		var module := rail.get_node("Modules/Module%d" % index) as Node3D
		check(module.owner == null, label + ": module regenerated on load")
		var housing := local_bounds(module.get_node("Housing"), rail)
		var light := local_bounds(module.get_node("Light"), rail)
		check(housing.size.distance_to(Vector3(2, .12, .12)) < EPS, label + ": imported housing scale")
		if index == 0:
			check(absf(housing.position.x - offset) < EPS, label + ": anchor contact")
		else:
			seam_error = maxf(seam_error, absf(housing.position.x - previous_housing.end.x))
			seam_error = maxf(seam_error, absf(light.position.x - previous_light.end.x))
			var joiner := local_bounds(rail.get_node("Joiners/Joiner%d" % index), rail)
			check(absf(joiner.get_center().x - housing.position.x) < EPS, label + ": joiner contact")
		previous_housing = housing
		previous_light = light
	check(seam_error < EPS, label + ": continuous housing and light")
	var start := local_bounds(rail.get_node("StartCap"), rail)
	var end := local_bounds(rail.get_node("EndCap"), rail)
	var cap_error := maxf(absf(start.end.x - offset), absf(end.position.x - previous_housing.end.x))
	check(cap_error < EPS, label + ": both cap contacts")
	check(absf(rail.get_node("EarlierEnd").position.x - offset) < EPS, label + ": earlier marker")
	check(absf(rail.get_node("LaterEnd").position.x - previous_housing.end.x) < EPS, label + ": later marker")
	rail_measurements.append({"case": label, "modules": count, "seam_error_m": seam_error, "cap_error_m": cap_error})

func verify_rail_edits() -> void:
	var rail := EDIT_RAIL.instantiate() as Node3D
	root.add_child(rail)
	var first := rail.get_node("Modules/Module0") as Node3D
	var join := rail.get_node("Joiners/Joiner1") as Node3D
	var first_id := first.get_instance_id()
	var join_id := join.get_instance_id()
	var note := addition(first)
	first.set_meta("note", "retained module")
	var visual := first.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var override := StandardMaterial3D.new()
	visual.material_override = override
	var modules := rail.get_node("Modules") as Node3D
	var joiners := rail.get_node("Joiners") as Node3D
	var container_addition := addition(modules)
	container_addition.owner = rail
	var start_id := rail.get_node("StartCap").get_instance_id()
	for count in [5, 2, 2, 7]:
		rail.set("module_count", count)
		check(rail.get_node("Modules/Module0").get_instance_id() == first_id, "Rail resize retains surviving module")
		check(rail.get_node("Joiners/Joiner1").get_instance_id() == join_id, "Rail resize retains surviving joiner")
		check(is_instance_valid(note) and not note.is_queued_for_deletion(), "Rail module child state survives resize")
		if is_instance_valid(first) and not first.is_queued_for_deletion():
			check(first.get_meta("note") == "retained module" and visual.material_override == override, "Rail metadata/material retained")
		inspect_rail_fit(rail, "count %d" % count)
	workflows.append("#5 retained modules, joiners, child state and material overrides")
	modules.transform = Transform3D(Basis(Vector3.UP, .43), Vector3(3, 2, -1))
	joiners.transform = Transform3D(Basis(Vector3.UP, -.27), Vector3(-2, .4, 3))
	var modules_transform := modules.transform
	var joiners_transform := joiners.transform
	rail.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	for anchor in [1, 0, 1]:
		rail.set("anchor_mode", anchor)
		inspect_rail_fit(rail, "transformed containers anchor %d" % anchor)
		check(modules.transform == modules_transform and joiners.transform == joiners_transform, "Rail retains supporting container transforms")
		check(is_instance_valid(container_addition) and container_addition.get_parent() == modules, "Rail retains container additions")
	check(rail.get_node("StartCap").get_instance_id() == start_id, "Rail retains caps")
	# Repair a queued module before the deletion flush; repair a freed joiner later.
	rail.get_node("Modules/Module1").queue_free()
	rail.set("module_count", 7)
	check(not rail.get_node("Modules/Module1").is_queued_for_deletion(), "Queued rail module replaced immediately")
	await process_frame
	rail.get_node("Joiners/Joiner2").free()
	rail.set("anchor_mode", 1)
	check(rail.has_node("Joiners/Joiner2"), "Freed rail joiner recreated on anchor refresh")
	if rail.has_node("Joiners/Joiner2"):
		inspect_rail_fit(rail, "slot recovery")
	var detached := rail.get_node("Modules/Module0") as Node3D
	modules.remove_child(detached)
	rail.set("module_count", 7)
	check(detached.get_parent() == modules and detached.get_instance_id() == first_id, "Rail reattaches live slot without replacing state")
	inspect_rail_fit(rail, "reattached rail module")
	var restored := disk_copy(rail, "edited_rail")
	inspect_rail_fit(restored, "rail disk roundtrip")
	check(restored.get_node("Modules").get_child_count() == 8, "Rail disk reload has seven modules and authored addition")
	root.remove_child(restored)
	restored.set("module_count", 1)
	root.add_child(restored)
	inspect_rail_fit(restored, "detached rail edit")
	workflows.append("#5 transformed containers, queued/freed recovery and disk roundtrip")
	rail.queue_free()
	restored.queue_free()
	await process_frame

func verify_station_edits() -> void:
	var station := EDIT_STATION.instantiate() as Node3D
	station.set("left_cassette_size", 2)
	station.set("right_show_cassette", false)
	root.add_child(station)
	var left := station.get_node("DisplayLeft") as Node3D
	var right := station.get_node("DisplayRight") as Node3D
	check(left.get("cassette_size") == 2 and not right.has_node("RecordSlot/Cassette"), "Station pre-ready configuration")
	# Each exported control owns only its corresponding display property.
	left.set("cassette_size", 1)
	left.set("cassette_yaw_degrees", 63.0)
	right.set("cassette_yaw_degrees", -74.0)
	var cassette := left.get_node("RecordSlot/Cassette") as Node3D
	var cassette_id := cassette.get_instance_id()
	var note := addition(cassette)
	var lectern_id := station.get_node("Lectern").get_instance_id()
	for property in ["display_spacing", "lectern_offset", "approach_depth"]:
		station.set(property, 1.0 if property != "approach_depth" else 1.4)
		check(left.get("cassette_size") == 1 and left.get("cassette_yaw_degrees") == 63.0, "Station layout retains local display overrides")
		check(right.get("cassette_yaw_degrees") == -74.0 and not right.has_node("RecordSlot/Cassette"), "Station layout retains empty-side configuration")
		check(left.get_node("RecordSlot/Cassette").get_instance_id() == cassette_id and is_instance_valid(note), "Station layout retains cassette child state")
	station.set("right_cassette_size", 1)
	check(left.get("cassette_size") == 1 and left.get_node("RecordSlot/Cassette").get_instance_id() == cassette_id, "Opposite-side size edit retains left state")
	check(right.get("cassette_yaw_degrees") == -74.0, "Size edit retains same-side yaw override")
	station.set("left_cassette_yaw", 23.0)
	check(left.get("cassette_size") == 1 and left.get("cassette_yaw_degrees") == 23.0, "Explicit station yaw updates only yaw")
	station.set("left_cassette_size", 0)
	check(left.get("cassette_size") == 0, "Explicit station size remains authoritative")
	inspect_display(left, 0, "station independently edited left display")
	left.set("show_cassette", false)
	station.set("right_cassette_yaw", 81.0)
	station.set("approach_depth", 1.4)
	check(not left.has_node("RecordSlot/Cassette"), "Unrelated station controls retain locally hidden display")
	station.set("left_show_cassette", true)
	inspect_display(left, 0, "explicit station visibility restores left display")
	check(station.get_node("Lectern").get_instance_id() == lectern_id, "Station retains imported lectern")
	var approach: AABB = station.call("get_approach_bounds")
	check(absf(approach.size.z - 1.4) < EPS and station.get_node("ApproachEnd").position.z == approach.end.z, "Station approach markers follow layout")
	# Exported station settings, rather than transient child overrides, serialize.
	var restored := disk_copy(station, "edited_station")
	check(restored.get_node("DisplayLeft").get("cassette_size") == 0, "Station exported size survives disk reload")
	check(not restored.get_node("DisplayRight").has_node("RecordSlot/Cassette"), "Station empty side survives disk reload")
	workflows.append("#34 independent layout/left/right controls, retained child overrides and saved station settings")
	station.queue_free()
	restored.queue_free()
	await process_frame

func inspect_aisle(alcove: Node3D, label: String) -> void:
	var row := alcove.get_node("ShelfRow") as Node3D
	var bench := alcove.get_node("Bench") as Node3D
	var row_box := local_bounds(row, row)
	var bench_box := local_bounds(bench, row)
	var aisle := bench_box.position.z - row_box.end.z
	check(absf(aisle - float(alcove.get("aisle_width"))) < EPS, label + ": imported clear aisle")
	check(absf(bench_box.position.y) < EPS and absf(bench_box.get_center().x) < EPS, label + ": bench centred on row floor")
	check(bench.global_basis.is_equal_approx(row.global_basis), label + ": bench follows row orientation")
	var centre := row.to_local((alcove.get_node("AisleCentre") as Node3D).global_position)
	check(centre.distance_to(Vector3(0, 0, row_box.end.z + aisle * .5)) < EPS, label + ": aisle marker in row frame")
	check(bench_box.size.distance_to(Vector3(1.6, .45, .48)) < EPS, label + ": imported bench unit scale")
	aisle_measurements.append({"case": label, "aisle_m": aisle, "bench_floor_error_m": absf(bench_box.position.y)})

func verify_alcove_edits() -> void:
	var alcove := EDIT_ALCOVE.instantiate() as Node3D
	alcove.set("requested_records_per_shelf", 2)
	var row := alcove.get_node("ShelfRow") as Node3D
	row.transform = Transform3D(Basis(Vector3.UP, .61), Vector3(2, .3, -3))
	root.add_child(alcove)
	var bench_id := alcove.get_node("Bench").get_instance_id()
	var bay_id := row.get_node("Bays/Bay0").get_instance_id()
	var note := addition(alcove.get_node("Bench"))
	inspect_aisle(alcove, "row edited before ready")
	alcove.transform = Transform3D(Basis(Vector3.UP, -.7), Vector3(-5, 2, 6))
	for yaw in [-150.0, -37.0, 0.0, 91.0, 180.0]:
		row.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(2, .3, -3))
		for width in [1.2, 1.54, 2.0]:
			alcove.set("aisle_width", width)
			inspect_aisle(alcove, "yaw %.0f aisle %.2f" % [yaw, width])
	row.position.x += 1
	alcove.set("bay_count", 4)
	inspect_aisle(alcove, "resized moved row")
	check(alcove.get_node("Bench").get_instance_id() == bench_id and is_instance_valid(note), "Alcove edits retain bench and child state")
	check(row.get_node("Bays/Bay0").get_instance_id() == bay_id, "Alcove resize retains surviving shelf")
	var restored := disk_copy(alcove, "edited_alcove")
	inspect_aisle(restored, "alcove disk roundtrip")
	workflows.append("#35 translated/rotated shelf frame, aisle limits, count refresh and disk roundtrip")
	alcove.queue_free()
	restored.queue_free()
	await process_frame

func verify_display_recovery() -> void:
	var display := DISPLAY.instantiate() as Node3D
	root.add_child(display)
	var plinth_id := display.get_node("Plinth").get_instance_id()
	var slot := display.get_node("RecordSlot") as Node3D
	var sentinel := addition(slot)
	for size in range(3):
		display.set("cassette_size", size)
		var original := slot.get_node("Cassette") as Node3D
		var original_id := original.get_instance_id()
		original.queue_free()
		display.set("cassette_yaw_degrees", 42.0)
		check(slot.has_node("Cassette") and not slot.get_node("Cassette").is_queued_for_deletion(), "Display replaces queued record before frame flush")
		if slot.has_node("Cassette"):
			check(slot.get_node("Cassette").get_instance_id() != original_id, "Display queued record gets fresh identity")
		await process_frame
		check(slot.has_node("Cassette"), "Display remains populated after deletion flush")
		# A subsequent property refresh also recovers an already-freed record.
		display.set("cassette_size", size)
		if slot.has_node("Cassette"):
			slot.get_node("Cassette").free()
		display.set("cassette_size", size)
		inspect_display(display, size, "freed display size %d" % size)
	# Reattach a live generated record to its owning slot, preserving its state.
	var record := slot.get_node("Cassette") as Node3D
	var note := addition(record)
	slot.remove_child(record)
	display.set("cassette_yaw_degrees", -37.0)
	check(record.get_parent() == slot and is_instance_valid(note), "Display reattaches detached live record with child state")
	if record.get_parent() == null:
		slot.add_child(record) # keep baseline failures isolated from later scenarios
	record.reparent(display)
	display.set("cassette_yaw_degrees", 17.0)
	check(record.get_parent() == slot, "Display restores reparented generated record")
	if record.get_parent() != slot:
		record.reparent(slot)
	display.set("cassette_yaw_degrees", 17.0)
	inspect_display(display, 2, "reattached display")
	(slot as Node3D).transform = Transform3D(Basis(Vector3.UP, .31), Vector3(-1, .4, 2))
	display.set("cassette_yaw_degrees", 72.0)
	inspect_display(display, 2, "transformed record slot")
	slot.get_node("Cassette").queue_free()
	display.set("show_cassette", false)
	check(not slot.has_node("Cassette") and is_instance_valid(sentinel), "Hiding queued record preserves slot additions")
	display.set("show_cassette", true)
	inspect_display(display, 2, "repopulated display")
	var detached := slot.get_node("Cassette") as Node3D
	slot.remove_child(detached)
	display.set("show_cassette", false)
	check(detached.is_queued_for_deletion() and not slot.has_node("Cassette"), "Hiding detached record releases it without a parent")
	display.set("show_cassette", true)
	inspect_display(display, 2, "display restored after hiding detached record")
	check(display.get_node("Plinth").get_instance_id() == plinth_id, "Display recovery retains plinth")
	workflows.append("#36 queued/freed/detached/reparented recovery for three sizes and transformed contact frame")
	display.queue_free()
	await process_frame

func verify() -> void:
	root.size = Vector2i(1100, 760)
	await verify_rail_edits()
	await verify_station_edits()
	await verify_alcove_edits()
	await verify_display_recovery()
	if DisplayServer.get_name() != "headless":
		var review := (load(EDIT_OUT + "review_objects.tscn") as PackedScene).instantiate() as Node3D
		root.add_child(review)
		current_scene = review
		var row := review.get_node("Alcove/ShelfRow") as Node3D
		row.rotation_degrees.y = 25
		review.get_node("Alcove").set("aisle_width", 1.54)
		var rail := review.get_node("Rail") as Node3D
		(rail.get_node("Modules") as Node3D).rotation_degrees.y = 35
		rail.set("module_count", 5)
		var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
		for view in [["front", Vector3(8, 6, 12)], ["rear", Vector3(-8, 5, -12)]]:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = 45.0
			camera.global_position = view[1]
			camera.look_at(Vector3(0, 1.3, -.8))
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(EDIT_OUT + "godot_" + view[0] + ".png") == OK, "Capture edited reusable objects")
	var report := {"passed": failures.is_empty(), "failures": failures, "issues": [5, 34, 35, 36],
		"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"workflows": workflows, "rail_measurements": rail_measurements, "aisle_measurements": aisle_measurements,
		"display_cases": display_cases, "mcp": "Blender status/scene and Godot get_state unavailable; standalone Godot fallback"}
	FileAccess.open(EDIT_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Assembly editing: %d workflows, %d failures" % [workflows.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
