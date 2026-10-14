extends "res://assets/library_room_review/verify_room.gd"
## Static imported-mesh evidence and configuration lifecycle checks.

const REVIEW_OUT := "res://assets/adaptive_library_review/"
const RAIL: PackedScene = preload("res://assets/timeline_rail_housing/configurable_timeline_rail.tscn")
const CENTRED: PackedScene = preload("res://assets/timeline_rail_housing/centered_timeline_rail.tscn")
const PACKED_BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/packed_cassette_shelf_bay.tscn")
const SMALL_BAY: PackedScene = preload("res://assets/archive_record_small/dense_shelf_bay.tscn")
const LARGE_BAY: PackedScene = preload("res://assets/archive_record_large/dense_shelf_bay.tscn")
const ALCOVE: PackedScene = preload("res://assets/reading_bench/configurable_reading_alcove.tscn")
const EPS: float = 0.0001
var rail_cases: Array[Dictionary] = []
var shelf_cases: Array[Dictionary] = []
var alcove_cases: Array[Dictionary] = []
var room_cases: Array[Dictionary] = []
var floor_faces := PackedVector3Array()
var actual_widths: Array[float] = []
var support_probes: int = 0
var lifecycle_cases: Array[String] = []

func attach_sentinel(container: Node, object: Node) -> Node:
	var sentinel := Marker3D.new()
	sentinel.name = "UserAttachment"
	container.add_child(sentinel)
	sentinel.owner = object
	return sentinel

func disk_roundtrip(object: Node3D, label: String) -> Node3D:
	var packed := PackedScene.new()
	check(packed.pack(object) == OK, "Pack " + label)
	var path := "user://" + label + ".tscn"
	check(ResourceSaver.save(packed, path) == OK, "Save " + label)
	var restored := (load(path) as PackedScene).instantiate() as Node3D
	root.add_child(restored)
	return restored

func inspect_rail(rail: Node3D, label: String) -> void:
	var count: int = rail.get("module_count")
	var offset: float = -count if rail.get("anchor_mode") == 1 else 0.0
	check(rail.get_node("Modules").find_children("Module*", "Node3D", false, false).size() == count, label + ": module count")
	check(rail.get_node("Joiners").get_child_count() == count - 1, label + ": joiner count")
	var seam_error: float = 0.0
	var previous_housing := AABB()
	var previous_light := AABB()
	for index in range(count):
		var module := rail.get_node("Modules/Module%d" % index) as Node3D
		check(module.scene_file_path.ends_with("illuminated_rail_module.tscn") and module.owner == null, label + ": scene instance")
		check(module.scale.is_equal_approx(Vector3.ONE), label + ": unit scale")
		var housing := local_bounds(module.get_node("Housing"), rail)
		var light := local_bounds(module.get_node("Light"), rail)
		check(housing.size.distance_to(Vector3(2, .12, .12)) < EPS, label + ": housing interface")
		if index == 0:
			check(absf(housing.position.x - offset) < EPS, label + ": first housing anchor")
		else:
			seam_error = maxf(seam_error, absf(housing.position.x - previous_housing.end.x))
			seam_error = maxf(seam_error, absf(light.position.x - previous_light.end.x))
			var joiner := local_bounds(rail.get_node("Joiners/Joiner%d" % index), rail)
			check(absf(joiner.get_center().x - housing.position.x) < EPS, label + ": joiner on seam")
			check(joiner.end.z < -.0199, label + ": joiner clears light")
		previous_housing = housing
		previous_light = light
	var start := local_bounds(rail.get_node("StartCap"), rail)
	var end := local_bounds(rail.get_node("EndCap"), rail)
	var cap_error := maxf(absf(start.end.x - offset), absf(end.position.x - previous_housing.end.x))
	check(cap_error < EPS and seam_error < EPS, label + ": cap and module continuity")
	check(absf(end.position.x - previous_light.end.x) < EPS, label + ": light termination")
	check(rail.get_node("EarlierEnd").position.is_equal_approx(Vector3(offset, 0, 0)), label + ": earlier marker")
	check(rail.get_node("LaterEnd").position.is_equal_approx(Vector3(offset + count * 2, 0, 0)), label + ": later marker")
	rail_cases.append({"case": label, "modules": count, "anchor_mode": rail.get("anchor_mode"),
		"max_seam_error_m": seam_error, "cap_contact_error_m": cap_error})

func record_supported(record: Node3D, shelf: Node3D, space: Node3D) -> bool:
	var box := local_bounds(record, space)
	var point := space.to_global(Vector3(box.get_center().x, box.position.y, box.get_center().z))
	support_probes += 1
	return segment_hits(shelf, point + space.global_basis.y * EPS, point - space.global_basis.y * EPS)

func inspect_packed(bay: Node3D, label: String) -> void:
	var pattern: PackedInt32Array = bay.get("cassette_pattern")
	var slots: int = bay.get("effective_records_per_shelf")
	var requested: int = bay.get("requested_records_per_shelf")
	var gap: float = bay.get("record_gap")
	var records := bay.get_node("Records")
	check(records.find_children("Record_*", "Node3D", false, false).size() == slots * 4, label + ": effective count")
	check(slots <= requested, label + ": no extra records")
	var shelf := bay.get_node("Shelf") as Node3D
	var left := part_bounds(shelf, "upright_left", bay)
	var right := part_bounds(shelf, "upright_right", bay)
	var back := part_bounds(shelf, "closed_back", bay)
	var contact_error: float = 0.0
	var clearance: float = INF
	var light_gap: float = INF
	var neighbor_gap: float = INF
	var span: float = 0.0
	for tier in range(4):
		var deck := part_bounds(shelf, "shelf_%d_deck" % tier, bay)
		var ceiling := part_bounds(shelf, "shelf_%d_rear_web" % (tier + 1), bay)
		var fixture := local_bounds(shelf.get_node("Light%d" % tier), bay)
		var first := AABB()
		var previous := AABB()
		for slot in range(slots):
			var record := records.get_node("Record_%d_%d" % [tier, slot]) as Node3D
			var size: String = ["small", "medium", "large"][pattern[slot % pattern.size()]]
			check(record.scene_file_path.ends_with("archive_record_%s.tscn" % size), label + ": ordered size")
			check(record.owner == null and record.scale.is_equal_approx(Vector3.ONE), label + ": independent unscaled cassette")
			var box := local_bounds(record, bay)
			contact_error = maxf(contact_error, absf(box.position.y - deck.end.y))
			clearance = minf(clearance, minf(minf(box.position.x - left.end.x, right.position.x - box.end.x),
				minf(box.position.z - back.end.z, deck.end.z - box.end.z)))
			clearance = minf(clearance, ceiling.position.y - box.end.y)
			light_gap = minf(light_gap, fixture.position.y - box.end.y)
			check(record_supported(record, shelf, bay), label + ": imported deck support")
			if slot == 0:
				first = box
			else:
				neighbor_gap = minf(neighbor_gap, box.position.x - previous.end.x)
			previous = box
		if slots > 0:
			span = previous.end.x - first.position.x
			check(absf((first.position.x + previous.end.x) * .5) < EPS, label + ": centered occupied span")
			check(span <= 1.44 + EPS, label + ": inside safe shelf width")
	# Actual imported widths prove overflow truncation is maximal for this sequence.
	var next_width: float = actual_widths[pattern[slots % pattern.size()]]
	check(slots == requested or span + next_width + (gap if slots > 0 else 0.0) > 1.44 - EPS, label + ": maximal fitting prefix")
	check(contact_error < EPS, label + ": shelf datum")
	check(slots == 0 or (clearance > .02 and light_gap > .04), label + ": structure and fixture clearances")
	check(slots < 2 or absf(neighbor_gap - gap) < EPS, label + ": requested actual gap")
	shelf_cases.append({"case": label, "pattern": Array(pattern), "requested": requested, "per_shelf": slots,
		"occupied_width_m": span, "contact_error_m": contact_error,
		"minimum_structure_clearance_m": clearance if slots > 0 else null,
		"minimum_light_gap_m": light_gap if slots > 0 else null,
		"minimum_neighbor_gap_m": neighbor_gap if slots > 1 else null})

func inspect_alcove(alcove: Node3D, label: String) -> void:
	var row := alcove.get_node("ShelfRow") as Node3D
	var bench := alcove.get_node("Bench") as Node3D
	var count: int = alcove.get("bay_count")
	check(row.get("bay_count") == count, label + ": propagated count")
	check(row.get_node("Bays").find_children("Bay*", "Node3D", false, false).size() == count, label + ": row count")
	var row_box := local_bounds(row, alcove)
	var bench_box := local_bounds(bench, alcove)
	var aisle := bench_box.position.z - row_box.end.z
	check(absf(aisle - float(alcove.get("aisle_width"))) < EPS, label + ": measured clear aisle")
	check(absf(bench_box.position.y) < EPS, label + ": bench floor datum")
	check(bench.scale.is_equal_approx(Vector3.ONE), label + ": unscaled bench")
	var first := local_bounds(row.get_node("Bays/Bay0"), row)
	var last := local_bounds(row.get_node("Bays/Bay%d" % (count - 1)), row)
	var cap_error := maxf(absf(local_bounds(row.get_node("CapLeft"), row).end.x - first.position.x),
		absf(local_bounds(row.get_node("CapRight"), row).position.x - last.end.x))
	check(cap_error < EPS, label + ": end caps follow count")
	check(absf(row_box.size.x - (1.6 * count + .164)) < EPS, label + ": row interface width")
	check(absf(alcove.get_node("AisleCentre").position.z - (row_box.end.z + aisle * .5)) < EPS, label + ": aisle marker")
	for bay in row.get_node("Bays").get_children():
		if bay.scene_file_path != PACKED_BAY.resource_path:
			continue
		check(bay.get("cassette_pattern") == alcove.get("cassette_pattern"), label + ": propagated pattern")
		check(bay.get("requested_records_per_shelf") == alcove.get("requested_records_per_shelf"), label + ": propagated density")
		check(bay.get("record_gap") == alcove.get("record_gap"), label + ": propagated gap")
		inspect_packed(bay, label + " " + str(bay.name))
	alcove_cases.append({"case": label, "bays": count, "width_m": row_box.size.x,
		"aisle_m": aisle, "cap_join_error_m": cap_error})

func verify_configuration() -> void:
	var rail := RAIL.instantiate() as Node3D
	rail.set("module_count", 7)
	rail.set("anchor_mode", 1)
	root.add_child(rail)
	attach_sentinel(rail.get_node("Modules"), rail)
	inspect_rail(rail, "pre-ready centered")
	for count in [1, 3, 7, 64, 0, 99]:
		rail.set("module_count", count)
		check(rail.get("module_count") == clampi(count, 1, 64), "Rail count clamp")
		for mode in [0, 1, -9, 99]:
			var module_id := rail.get_node("Modules/Module0").get_instance_id()
			rail.set("anchor_mode", mode)
			check(rail.get("anchor_mode") == clampi(mode, 0, 1), "Rail anchor clamp")
			check(rail.get_node("Modules/Module0").get_instance_id() == module_id, "Anchor edits preserve module")
			inspect_rail(rail, "count %d mode %d" % [count, mode])
		check(rail.has_node("Modules/UserAttachment"), "Rail attachment survives resize")
		rail.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	rail.set("module_count", 7)
	rail.set("anchor_mode", 1)
	var restored := disk_roundtrip(rail, "rail")
	inspect_rail(restored, "rail disk roundtrip")
	check(restored.has_node("Modules/UserAttachment"), "Rail attachment serialized")
	root.remove_child(restored)
	restored.set("module_count", 3)
	root.add_child(restored)
	inspect_rail(restored, "rail detached edit")
	check(rail.get("module_count") == 7, "Independent rail instances")
	rail.free()
	restored.free()
	var centred := CENTRED.instantiate() as Node3D
	root.add_child(centred)
	inspect_rail(centred, "saved centered variant")
	bounds(centred.get_node("Modules/Module0/Housing"), true)
	centred.free()
	await process_frame
	var bay := PACKED_BAY.instantiate() as Node3D
	bay.set("cassette_pattern", PackedInt32Array([2, 0, 1]))
	bay.set("requested_records_per_shelf", 5)
	root.add_child(bay)
	attach_sentinel(bay.get_node("Records"), bay)
	inspect_packed(bay, "pre-ready packed bay")
	for pattern in [PackedInt32Array([0]), PackedInt32Array([1]), PackedInt32Array([2]),
		PackedInt32Array([0, 1, 2]), PackedInt32Array([2, 0, 2, 1]), PackedInt32Array(), PackedInt32Array([-9, 99])]:
		bay.set("cassette_pattern", pattern)
		for gap in [.02, .15]:
			bay.set("record_gap", gap)
			for request in [0, 1, 32]:
				bay.set("requested_records_per_shelf", request)
				inspect_packed(bay, "pattern %s gap %.2f request %d" % [str(Array(pattern)), gap, request])
		check(bay.has_node("Records/UserAttachment"), "Bay attachment survives rebuild")
	bay.set("cassette_pattern", PackedInt32Array([-9, 99]))
	check(bay.get("cassette_pattern") == PackedInt32Array([0, 2]), "Cassette codes clamp")
	bay.set("cassette_pattern", PackedInt32Array())
	check(bay.get("cassette_pattern") == PackedInt32Array([0]), "Empty pattern fallback")
	var pattern := PackedInt32Array([0, 1, 2, 0, 1, 2, 0, 1, 2, 0])
	bay.set("cassette_pattern", pattern)
	pattern[0] = 2
	var copy: PackedInt32Array = bay.get("cassette_pattern")
	copy[0] = 2
	check(bay.get("cassette_pattern").size() == 9 and bay.get("cassette_pattern")[0] == 0, "Pattern copied and bounded")
	for request in [-9, 99]:
		bay.set("requested_records_per_shelf", request)
		check(bay.get("requested_records_per_shelf") == clampi(request, 0, 32), "Density clamp")
	for gap in [-1.0, 1.0]:
		bay.set("record_gap", gap)
		check(is_equal_approx(bay.get("record_gap"), clampf(gap, .02, .15)), "Gap clamp")
	bay.set("record_gap", .02)
	bay.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	inspect_packed(bay, "transformed packed bay")
	restored = disk_roundtrip(bay, "packed_bay")
	inspect_packed(restored, "packed bay disk roundtrip")
	check(restored.has_node("Records/UserAttachment"), "Bay attachment serialized")
	root.remove_child(restored)
	restored.set("requested_records_per_shelf", 1)
	root.add_child(restored)
	inspect_packed(restored, "packed bay detached edit")
	check(bay.get("requested_records_per_shelf") == 32, "Independent packed bay instances")
	var record := restored.get_node("Records/Record_0_0") as Node3D
	var seated := record.position
	record.position.y += .01
	check(not record_supported(record, restored.get_node("Shelf"), restored), "Floating cassette control")
	record.position = seated + Vector3(3, 0, 0)
	check(not record_supported(record, restored.get_node("Shelf"), restored), "Outside shelf control")
	bay.free()
	restored.free()
	for scene in [SMALL_BAY, LARGE_BAY]:
		var variant := scene.instantiate() as Node3D
		root.add_child(variant)
		inspect_packed(variant, "saved " + str(variant.name))
		check(variant.get("effective_records_per_shelf") == (16 if scene == SMALL_BAY else 11), "Saved family density")
		variant.free()
	await process_frame
	var alcove := ALCOVE.instantiate() as Node3D
	alcove.set("bay_count", 1)
	alcove.set("cassette_pattern", PackedInt32Array([2]))
	alcove.set("requested_records_per_shelf", 3)
	root.add_child(alcove)
	attach_sentinel(alcove.get_node("Attachments"), alcove)
	inspect_alcove(alcove, "pre-ready alcove")
	for count in [1, 2, 3, 4]:
		alcove.set("bay_count", count)
		for aisle in [1.2, 1.54, 2.0]:
			var bench_id := alcove.get_node("Bench").get_instance_id()
			var bay_id := alcove.get_node("ShelfRow/Bays/Bay0").get_instance_id()
			alcove.set("aisle_width", aisle)
			check(alcove.get_node("Bench").get_instance_id() == bench_id, "Aisle edit retains bench")
			check(alcove.get_node("ShelfRow/Bays/Bay0").get_instance_id() == bay_id, "Aisle edit retains row")
			inspect_alcove(alcove, "alcove count %d aisle %.2f" % [count, aisle])
		check(alcove.has_node("Attachments/UserAttachment"), "Alcove count retains persistent attachments")
	var bay_id := alcove.get_node("ShelfRow/Bays/Bay0").get_instance_id()
	alcove.set("cassette_pattern", PackedInt32Array([0, 2]))
	alcove.set("requested_records_per_shelf", 32)
	alcove.set("record_gap", .04)
	check(alcove.get_node("ShelfRow/Bays/Bay0").get_instance_id() == bay_id, "Population retains bays")
	alcove.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	inspect_alcove(alcove, "transformed populated alcove")
	restored = disk_roundtrip(alcove, "alcove")
	inspect_alcove(restored, "alcove disk roundtrip")
	check(restored.has_node("Attachments/UserAttachment"), "Alcove attachment serialized")
	root.remove_child(restored)
	restored.set("bay_count", 2)
	restored.set("aisle_width", 1.2)
	root.add_child(restored)
	inspect_alcove(restored, "alcove detached edit")
	check(alcove.get("bay_count") == 4, "Independent alcove instances")
	for requested in [-9, 99]:
		restored.set("bay_count", requested)
		check(restored.get("bay_count") == clampi(requested, 1, 4), "Alcove count clamp")
	for requested in [-1.0, 8.0]:
		restored.set("aisle_width", requested)
		check(is_equal_approx(restored.get("aisle_width"), clampf(requested, 1.2, 2.0)), "Aisle clamp")
	alcove.free()
	restored.free()
	lifecycle_cases.assign(["pre-ready configuration", "clamps", "array copies", "attachment preservation",
		"disk serialization", "detached edits", "independent instances", "anchor and aisle retain models", "population retains bays"])
	await process_frame

func cache_floor(floor_node: Node3D, space: Node3D) -> void:
	floor_faces.clear()
	for child in floor_node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var frame := space.global_transform.affine_inverse() * mesh.global_transform
		for vertex in mesh.mesh.get_faces():
			floor_faces.append(frame * vertex)

func floor_supported(point: Vector3) -> bool:
	for offset in [Vector3.ZERO, Vector3(.00001, 0, .00001), Vector3(-.00001, 0, -.00001)]:
		var hit := false
		for index in range(0, floor_faces.size(), 3):
			if Geometry3D.segment_intersects_triangle(point + offset + Vector3(0, EPS, 0),
				point + offset - Vector3(0, .0021, 0), floor_faces[index], floor_faces[index + 1], floor_faces[index + 2]) != null:
				hit = true
				break
		if offset == Vector3.ZERO and hit:
			return true
		if offset != Vector3.ZERO and not hit:
			return false
	return true

func inspect_room_fit(room: Node3D, label: String) -> void:
	cache_floor(room.get_node("Floor"), room)
	check(floor_supported(Vector3(2, 0, 2)), "Floor positive control")
	check(not floor_supported(Vector3(2, .01, 2)) and not floor_supported(Vector3(33, 0, 0)), "Floor negative controls")
	var probes: int = 0
	var minimum_radius: float = INF
	var wall_separation: float = INF
	for name in ["AlcoveEast", "AlcoveWest"]:
		var alcove := room.get_node(name) as Node3D
		inspect_alcove(alcove, label + " " + name)
		var row := alcove.get_node("ShelfRow") as Node3D
		var bench := alcove.get_node("Bench") as Node3D
		var supports: Array[Node3D] = [row.get_node("CapLeft"), row.get_node("CapRight")]
		for bay in row.get_node("Bays").get_children():
			if bay.scene_file_path == PACKED_BAY.resource_path:
				supports.append(bay.get_node("Shelf"))
		for object in supports:
			var box := local_bounds(object, object)
			for fx in [.2, .8]:
				for fz in [.2, .8]:
					var point := room.to_local(object.to_global(Vector3(lerpf(box.position.x, box.end.x, fx), box.position.y,
						lerpf(box.position.z, box.end.z, fz))))
					check(absf(point.y) < EPS and floor_supported(point), label + ": supported row bases")
					probes += 1
		for side in ["left", "right"]:
			var pad := part_bounds(bench, "floor_pad_" + side, bench)
			for fx in [.2, .5, .8]:
				for fz in [.2, .5, .8]:
					var point := room.to_local(bench.to_global(Vector3(lerpf(pad.position.x, pad.end.x, fx), pad.position.y,
						lerpf(pad.position.z, pad.end.z, fz))))
					check(absf(point.y) < EPS and floor_supported(point), label + ": supported bench pads")
					probes += 1
		var box := local_bounds(alcove, room)
		minimum_radius = minf(minimum_radius, Vector2(clampf(0, box.position.x, box.end.x), clampf(0, box.position.z, box.end.z)).length())
		for obstacle in room.get_node("Perimeter/Bays").get_children() + room.get_node("Perimeter/Piers").get_children():
			var other := local_bounds(obstacle, alcove)
			var local_box := local_bounds(alcove, alcove)
			check(not local_box.intersects(other), label + ": alcove clears perimeter")
			var dx := maxf(0, maxf(local_box.position.x - other.end.x, other.position.x - local_box.end.x))
			var dz := maxf(0, maxf(local_box.position.z - other.end.z, other.position.z - local_box.end.z))
			wall_separation = minf(wall_separation, Vector2(dx, dz).length())
		for index in [0, 12]:
			var portal := room.get_node("Perimeter/Bays/Bay%d" % index) as Node3D
			check(not local_bounds(alcove, portal).intersects(AABB(Vector3(-1.5, 0, -1), Vector3(3, 3.4, 6))), label + ": portal approach clear")
		# Sample the walking aisle at seat height and along its full bench width.
		var aisle_z: float = alcove.get_node("AisleCentre").position.z
		for x in [-.7, 0.0, .7]:
			check(floor_supported(room.to_local(alcove.to_global(Vector3(x, 0, aisle_z)))), label + ": aisle floor")
			check(not segment_hits(alcove, alcove.to_global(Vector3(x, .5, aisle_z)), alcove.to_global(Vector3(x, 2.0, aisle_z))), label + ": aisle vertical clearance")
			probes += 1
	check(minimum_radius > 20.0 and wall_separation > .1, label + ": central volume and perimeter setback")
	var rail := room.get_node("Timeline") as Node3D
	inspect_rail(rail, label + " rail")
	var box := local_bounds(rail, room)
	check(box.position.y > 1.4 and maxf(absf(box.position.x), absf(box.end.x)) < 20, label + ": rail inside central volume")
	for step in range(29):
		check(floor_supported(Vector3(-7 + .5 * step, 0, 0)), label + ": floor beneath centered rail")
		probes += 1
	room_cases.append({"case": label, "floor_probes": probes, "minimum_clear_radius_m": minimum_radius,
		"perimeter_setback_m": wall_separation, "rail_floor_clearance_m": box.position.y})

func save_view(camera: Camera3D, label: String, position: Vector3, target: Vector3, span: float = 0.0) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if span > 0 else Camera3D.PROJECTION_PERSPECTIVE
	camera.global_position = position
	camera.look_at(target)
	if span > 0:
		camera.size = span
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW_OUT + "godot_" + label + ".png") == OK, "Save GPU view")

func verify() -> void:
	root.size = Vector2i(1100, 760)
	# Measure the independently imported three-size family before capacity tests.
	for path in ["res://assets/archive_record_small/archive_record_small.tscn",
		"res://assets/archive_record_medium/archive_record_medium.tscn",
		"res://assets/archive_record_large/archive_record_large.tscn"]:
		var record := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(record)
		actual_widths.append(local_bounds(record, record).size.x)
		bounds(record, true)
		record.free()
	await verify_configuration()
	var review := (load("res://assets/adaptive_library_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	for object in [room.get_node("AlcoveEast/Bench"), room.get_node("AlcoveEast/ShelfRow/Bays/Bay0/Shelf"),
		room.get_node("AlcoveEast/ShelfRow/CapLeft"), room.get_node("AlcoveEast/ShelfRow/CapRight")]:
		bounds(object, true)
	inspect_room_fit(room, "saved room")
	room.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	inspect_room_fit(room, "transformed room")
	room.transform = Transform3D.IDENTITY
	# Check the widest row and both aisle limits against the same real perimeter.
	for aisle in [1.2, 2.0]:
		for name in ["AlcoveEast", "AlcoveWest"]:
			room.get_node(name).set("bay_count", 4)
			room.get_node(name).set("aisle_width", aisle)
		inspect_room_fit(room, "maximum rows aisle %.2f" % aisle)
	room.get_node("AlcoveEast").set("bay_count", 2)
	room.get_node("AlcoveWest").set("bay_count", 3)
	for name in ["AlcoveEast", "AlcoveWest"]:
		room.get_node(name).set("aisle_width", 1.54)
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await save_view(camera, "room", Vector3(31, 32, 39), Vector3(0, 1.8, 0), 59.0)
	await save_view(camera, "alcove", Vector3(15.5, 3.3, 4.1), Vector3(22.2, 1.2, 0))
	await save_view(camera, "mixed", Vector3(-15.8, 2.7, -4.2), Vector3(-22.2, 1.2, 0))
	await save_view(camera, "rail", Vector3(3, 3, 15), Vector3(0, 1.5, 0), 15.5)
	# Isolate the assembly to inspect finished rear/end/underside faces.
	for name in ["Floor", "Perimeter", "Timeline", "AlcoveWest"]:
		room.get_node(name).hide()
	var alcove := room.get_node("AlcoveEast") as Node3D
	var target := alcove.to_global(Vector3(0, 1.2, -.7))
	for view in [["rear", Vector3(-.5, .3, -1)], ["end", Vector3(1, .1, .2)], ["underside", Vector3(.4, -.65, 1)]]:
		await save_view(camera, view[0], target + alcove.global_basis * view[1] * 5.0, target, 5.0)
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"passed": failures.is_empty(), "failures": failures, "rail_cases": rail_cases, "shelf_cases": shelf_cases,
		"alcove_cases": alcove_cases, "room_cases": room_cases, "lifecycle_cases": lifecycle_cases,
		"actual_cassette_widths_m": actual_widths, "cassette_support_probes": support_probes, "validated_meshes": meshes,
		"mcp": "Blender and Godot disconnected; standalone Godot 4.7.2 fallback. Existing models reused.",
		"scope": "Static imported geometry, fit, support, lifecycle, and GPU captures. No collision, animation, continuous camera, text readability or performance approval."}
	FileAccess.open(REVIEW_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Adaptive library: %d rail, %d shelf, %d alcove, %d room cases; passed=%s" % [rail_cases.size(), shelf_cases.size(), alcove_cases.size(), room_cases.size(), str(failures.is_empty())])
	quit(0 if failures.is_empty() else 1)
