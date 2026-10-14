extends "res://assets/adaptive_library_review/verify_adaptive.gd"
## Imported geometry checks for both independently populated storage faces.

const ISLAND_OUT := "res://assets/archive_island_review/"
const ISLAND: PackedScene = preload("res://assets/record_stack_end_cap/configurable_archive_island.tscn")
const SMALL_ISLAND: PackedScene = preload("res://assets/archive_record_small/small_archive_island.tscn")
const LARGE_ISLAND: PackedScene = preload("res://assets/archive_record_large/large_archive_island.tscn")
const RECORD_PATHS: Array[String] = ["res://assets/archive_record_small/archive_record_small.tscn",
	"res://assets/archive_record_medium/archive_record_medium.tscn",
	"res://assets/archive_record_large/archive_record_large.tscn"]
var island_cases: Array[Dictionary] = []
var island_room_cases: Array[Dictionary] = []
var closed_back_probes: int = 0
var island_floor_probes: int = 0

func inspect_island(island: Node3D, label: String) -> void:
	var count: int = island.get("bay_count")
	var front := island.get_node("FrontRow") as Node3D
	var back := island.get_node("BackRow") as Node3D
	var front_box := local_bounds(front, island)
	var back_box := local_bounds(back, island)
	var gap: float = front_box.position.z - back_box.end.z
	check(absf(gap - float(island.get("back_gap"))) < EPS, label + ": actual back separation")
	check(not front_box.intersects(back_box), label + ": two row envelopes do not overlap")
	check(front.basis.z.dot(Vector3.BACK) > .999 and back.basis.z.dot(Vector3.FORWARD) > .999, label + ": outward-facing rows")
	var actual_body := front_box.merge(back_box)
	var body: AABB = island.call("get_body_bounds")
	check(body.position.distance_to(actual_body.position) < EPS and body.size.distance_to(actual_body.size) < EPS,
		label + ": layout envelope matches imported geometry")
	var cap_error: float = 0.0
	var seam_error: float = 0.0
	for face in ["Front", "Back"]:
		var row := island.get_node(face + "Row") as Node3D
		var prefix: String = face.to_lower()
		check(row.get_node("Bays").find_children("Bay*", "Node3D", false, false).size() == count, label + ": row count")
		check(row.scene_file_path.ends_with("configurable_shelf_row.tscn") and row.scale.is_equal_approx(Vector3.ONE), label + ": independent row")
		var previous := AABB()
		for index in range(count):
			var bay := row.get_node("Bays/Bay%d" % index) as Node3D
			check(bay.get("cassette_pattern") == island.get(prefix + "_pattern"), label + ": independent pattern")
			check(bay.get("requested_records_per_shelf") == island.get(prefix + "_records_per_shelf"), label + ": independent density")
			check(bay.get("record_gap") == island.get(prefix + "_record_gap"), label + ": independent spacing")
			inspect_packed(bay, label + " " + face + str(index))
			var shelf := bay.get_node("Shelf") as Node3D
			var box := local_bounds(shelf, row)
			check(box.size.distance_to(Vector3(1.6, 2.4, .44)) < EPS and absf(box.position.y) < EPS, label + ": shelf interface")
			if index > 0:
				seam_error = maxf(seam_error, absf(box.position.x - previous.end.x))
			previous = box
			# Short segments only cross the rear slab, away from decks/uprights.
			for x in [-.6, 0.0, .6]:
				for y in [.3, 1.1, 2.2]:
					check(segment_hits(shelf, bay.to_global(Vector3(x, y, -.23)),
						bay.to_global(Vector3(x, y, -.18))), label + ": finished closed back")
					closed_back_probes += 1
		var first := local_bounds(row.get_node("Bays/Bay0/Shelf"), row)
		var last := local_bounds(row.get_node("Bays/Bay%d/Shelf" % (count - 1)), row)
		for side in ["Left", "Right"]:
			var cap := row.get_node("Cap" + side) as Node3D
			var box := local_bounds(cap, row)
			var error := absf(box.end.x - first.position.x) if side == "Left" else absf(box.position.x - last.end.x)
			cap_error = maxf(cap_error, error)
			check(cap.scene_file_path.ends_with("record_stack_end_cap.tscn") and cap.scale.is_equal_approx(Vector3.ONE), label + ": cap without mirroring")
			check(box.size.distance_to(Vector3(.082, 2.4, .44)) < EPS and absf(box.position.y) < EPS, label + ": complete cap coverage")
		var approach: AABB = island.call("get_approach_bounds", face == "Front")
		check(absf(approach.size.x - body.size.x) < EPS and absf(approach.size.z - float(island.get("approach_depth"))) < EPS, label + ": approach envelope")
		var join_error := absf(approach.position.z - actual_body.end.z) if face == "Front" else absf(approach.end.z - actual_body.position.z)
		check(join_error < EPS, label + ": approach beyond actual furniture")
		check(island.get_node(face + "Approach").position.distance_to(approach.get_center() * Vector3(1, 0, 1)) < EPS, label + ": approach marker")
		check(not approach.grow(-EPS).intersects(front_box) and not approach.grow(-EPS).intersects(back_box), label + ": unobstructed approaches")
	check(cap_error < EPS and seam_error < EPS, label + ": cap and bay continuity")
	island_cases.append({"case": label, "bays_per_face": count, "caps": 4,
		"width_m": actual_body.size.x, "depth_m": actual_body.size.z, "back_gap_m": gap,
		"cap_join_error_m": cap_error, "bay_seam_error_m": seam_error})

func verify_island_configuration() -> void:
	var island := ISLAND.instantiate() as Node3D
	island.set("bay_count", 1)
	island.set("front_records_per_shelf", 5)
	island.set("back_pattern", PackedInt32Array([2, 1]))
	root.add_child(island)
	attach_sentinel(island.get_node("Attachments"), island)
	inspect_island(island, "pre-ready configuration")
	var cap_id := island.get_node("BackRow/CapLeft").get_instance_id()
	for count in [1, 2, 4, 0, 99]:
		island.set("bay_count", count)
		check(island.get("bay_count") == clampi(count, 1, 4), "Island count clamp")
		for gap in [.04, .3]:
			var record_id := island.get_node("FrontRow/Bays/Bay0/Records/Record_0_0").get_instance_id()
			island.set("back_gap", gap)
			island.set("approach_depth", 2.0 if gap == .3 else 1.2)
			check(island.get_node("FrontRow/Bays/Bay0/Records/Record_0_0").get_instance_id() == record_id, "Gap preserves records")
			inspect_island(island, "count %d gap %.2f" % [count, gap])
		check(island.has_node("Attachments/UserAttachment"), "Count preserves attachments")
	check(island.get_node("BackRow/CapLeft").get_instance_id() == cap_id, "Resize preserves cap")
	island.set("bay_count", 1)
	for pattern in [PackedInt32Array([0]), PackedInt32Array([1]), PackedInt32Array([2]), PackedInt32Array([2, 0, 1])]:
		for face in ["front", "back"]:
			var other: String = "Back" if face == "front" else "Front"
			var other_id := island.get_node(other + "Row/Bays/Bay0/Records/Record_0_0").get_instance_id()
			island.set(face + "_pattern", pattern)
			island.set(face + "_record_gap", .15 if face == "back" else .02)
			island.set(face + "_records_per_shelf", 32)
			check(island.get_node(other + "Row/Bays/Bay0/Records/Record_0_0").get_instance_id() == other_id, "Population preserves opposite records")
			inspect_island(island, face + " pattern " + str(Array(pattern)))
	for face in ["front", "back"]:
		for request in [0, 1, -9, 99]:
			island.set(face + "_records_per_shelf", request)
			check(island.get(face + "_records_per_shelf") == clampi(request, 0, 32), "Density clamp")
			inspect_island(island, face + " request " + str(request))
		island.set(face + "_pattern", PackedInt32Array())
		check(island.get(face + "_pattern") == PackedInt32Array([0]), "Empty pattern fallback")
		island.set(face + "_pattern", PackedInt32Array([-99, 99, 1, 0, 1, 2, 0, 1, 2, 1]))
		var pattern: PackedInt32Array = island.get(face + "_pattern")
		check(pattern == PackedInt32Array([0, 2, 1, 0, 1, 2, 0, 1, 2]), "Pattern codes and length clamp")
		pattern[0] = 2
		check(island.get(face + "_pattern")[0] == 0, "Pattern getter copies")
		island.set(face + "_pattern", pattern)
		pattern[0] = 0
		check(island.get(face + "_pattern")[0] == 2, "Pattern setter copies")
		for gap in [-1.0, 3.0]:
			island.set(face + "_record_gap", gap)
			check(is_equal_approx(island.get(face + "_record_gap"), clampf(gap, .02, .15)), "Record gap clamp")
	for value in [-1.0, 9.0]:
		island.set("back_gap", value)
		island.set("approach_depth", value)
		check(is_equal_approx(island.get("back_gap"), clampf(value, .04, .3)), "Back gap clamp")
		check(is_equal_approx(island.get("approach_depth"), clampf(value, 1.2, 2.0)), "Approach clamp")
	island.set("bay_count", 3)
	island.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	inspect_island(island, "translated rotated island")
	var restored := disk_roundtrip(island, "archive_island")
	inspect_island(restored, "island disk roundtrip")
	check(restored.has_node("Attachments/UserAttachment"), "Island attachment serialized")
	root.remove_child(restored)
	restored.set("bay_count", 2)
	restored.set("back_gap", .04)
	restored.set("back_pattern", PackedInt32Array([0]))
	root.add_child(restored)
	inspect_island(restored, "island detached edit")
	check(island.get("bay_count") == 3 and island.get("back_pattern")[0] == 2, "Independent instances")
	island.free()
	restored.free()
	for scene in [ISLAND, SMALL_ISLAND, LARGE_ISLAND]:
		var saved := scene.instantiate() as Node3D
		root.add_child(saved)
		inspect_island(saved, "saved " + str(saved.name))
		for face in ["Front", "Back"]:
			var expected: int = 16 if scene == SMALL_ISLAND or (scene == ISLAND and face == "Front") else 11
			check(saved.get_node(face + "Row/Bays/Bay0").get("effective_records_per_shelf") == expected, "Saved capacity")
		saved.free()
	await process_frame

func horizontal_separation(a: AABB, b: AABB) -> float:
	var dx := maxf(0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dz := maxf(0, maxf(a.position.z - b.end.z, b.position.z - a.end.z))
	return Vector2(dx, dz).length()

func inspect_island_room(room: Node3D, label: String) -> void:
	cache_floor(room.get_node("Floor"), room)
	check(floor_supported(Vector3(2, 0, 2)), "Floor positive control")
	check(not floor_supported(Vector3(2, .01, 2)) and not floor_supported(Vector3(33, 0, 0)), "Floor negative controls")
	var probes: int = 0
	var central_radius: float = INF
	var architecture_gap: float = INF
	for name in ["IslandEast", "IslandWest"]:
		var island := room.get_node(name) as Node3D
		inspect_island(island, label + " " + name)
		var body := local_bounds(island, island)
		var envelopes: Array[AABB] = [body, island.call("get_approach_bounds", true), island.call("get_approach_bounds", false)]
		for box in envelopes:
			var in_room: AABB = (room.global_transform.affine_inverse() * island.global_transform) * box
			central_radius = minf(central_radius, Vector2(clampf(0, in_room.position.x, in_room.end.x), clampf(0, in_room.position.z, in_room.end.z)).length())
			for obstacle in room.get_node("Perimeter/Bays").get_children() + room.get_node("Perimeter/Piers").get_children():
				var other := local_bounds(obstacle, island)
				check(not box.intersects(other), label + ": body and approaches clear architecture")
				architecture_gap = minf(architecture_gap, horizontal_separation(box, other))
			for index in [0, 12]:
				var portal := room.get_node("Perimeter/Bays/Bay%d" % index) as Node3D
				var in_portal: AABB = (portal.global_transform.affine_inverse() * island.global_transform) * box
				check(not in_portal.intersects(AABB(Vector3(-1.5, 0, -1), Vector3(3, 3.4, 6))), label + ": portal approach clear")
		for face in ["Front", "Back"]:
			var row := island.get_node(face + "Row") as Node3D
			var supports: Array[Node3D] = [row.get_node("CapLeft"), row.get_node("CapRight")]
			for bay in row.get_node("Bays").get_children():
				if bay.scene_file_path == PACKED_BAY.resource_path:
					supports.append(bay.get_node("Shelf"))
			for object in supports:
				var box := local_bounds(object, object)
				for fx in [.2, .5, .8]:
					for fz in [.2, .5, .8]:
						var point := room.to_local(object.to_global(Vector3(lerpf(box.position.x, box.end.x, fx), box.position.y, lerpf(box.position.z, box.end.z, fz))))
						check(absf(point.y) < EPS and floor_supported(point), label + ": floor supports shelves and caps")
						probes += 1
			var approach: AABB = island.call("get_approach_bounds", face == "Front")
			for x_step in range(5):
				for z_step in range(3):
					var point := Vector3(lerpf(approach.position.x, approach.end.x, .05 + x_step * .225), 0,
						lerpf(approach.position.z, approach.end.z, .1 + z_step * .4))
					check(floor_supported(room.to_local(island.to_global(point))), label + ": both approach floors")
					check(not segment_hits(island, island.to_global(point + Vector3(0, .01, 0)), island.to_global(point + Vector3(0, 1.99, 0))), label + ": approach headroom")
					probes += 1
	check(central_radius > 20.0 and architecture_gap > .1, label + ": approach and body room fit")
	island_floor_probes += probes
	island_room_cases.append({"case": label, "floor_probes": probes, "central_clear_radius_m": central_radius,
		"minimum_architecture_separation_m": architecture_gap})

func island_view(camera: Camera3D, label: String, position: Vector3, target: Vector3, span: float) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.global_position = position
	camera.look_at(target)
	camera.size = span
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(ISLAND_OUT + "godot_" + label + ".png") == OK, "Save island GPU view")

func verify() -> void:
	root.size = Vector2i(1100, 760)
	for path in RECORD_PATHS:
		var cassette := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(cassette)
		actual_widths.append(local_bounds(cassette, cassette).size.x)
		bounds(cassette, true)
		cassette.free()
	await verify_island_configuration()
	var review := (load("res://assets/archive_island_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	for object in [room.get_node("IslandEast/FrontRow/Bays/Bay0/Shelf"), room.get_node("IslandEast/FrontRow/CapLeft")]:
		bounds(object, true)
	inspect_island_room(room, "saved room")
	room.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))
	inspect_island_room(room, "translated rotated room")
	room.transform = Transform3D.IDENTITY
	var restored := disk_roundtrip(room, "island_room")
	inspect_island_room(restored, "room disk roundtrip")
	restored.free()
	for count in [1, 4]:
		for gap in [.04, .3]:
			for name in ["IslandEast", "IslandWest"]:
				room.get_node(name).set("bay_count", count)
				room.get_node(name).set("back_gap", gap)
			inspect_island_room(room, "room count %d gap %.2f" % [count, gap])
	for name in ["IslandEast", "IslandWest"]:
		room.get_node(name).set("bay_count", 2 if name == "IslandEast" else 3)
		room.get_node(name).set("back_gap", .04)
	var boxes: Array[AABB] = []
	for node in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		boxes.append((room.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb())
	var camera_clearance: float = INF
	var samples: int = 0
	for radius in [12.0, 16.0, 19.0]:
		for height in [1.8, 4.0, 8.0]:
			for degrees in range(0, 360, 5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius * sin(angle), height, -radius * cos(angle))
				for box in boxes:
					var nearest := Vector3(clampf(point.x, box.position.x, box.end.x), clampf(point.y, box.position.y, box.end.y), clampf(point.z, box.position.z, box.end.z))
					camera_clearance = minf(camera_clearance, point.distance_to(nearest) - .3)
				samples += 1
	check(camera_clearance > 0, "Camera samples clear all imported room meshes")
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await island_view(camera, "room", Vector3(32, 34, 40), Vector3(0, 1.5, 0), 59.0)
	var island := room.get_node("IslandEast") as Node3D
	var target := island.to_global(Vector3(0, 1.1, 0))
	await island_view(camera, "front_room", island.to_global(Vector3(2.6, 2.8, 5)), target, 5.0)
	await island_view(camera, "back_room", island.to_global(Vector3(0, 1.2, -1.4)),
		island.to_global(Vector3(0, 1.2, -.4)), 4.4)
	for name in ["Floor", "Perimeter", "Timeline", "IslandWest"]:
		room.get_node(name).hide()
	for view in [["front", Vector3(.45, .3, 1)], ["back", Vector3(-.45, .3, -1)],
		["end", Vector3(1, .05, .12)], ["underside", Vector3(.4, -.65, 1)], ["back_gap", Vector3(1, .7, 0)]]:
		await island_view(camera, view[0], target + island.global_basis * view[1] * 5, target, 4.4)
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"passed": failures.is_empty(), "failures": failures, "issues": [28, 29, 31, 33],
		"island_cases": island_cases, "shelf_cases": shelf_cases, "room_cases": island_room_cases,
		"cassette_support_probes": support_probes, "closed_back_probes": closed_back_probes,
		"floor_probes": island_floor_probes, "actual_cassette_widths_m": actual_widths, "validated_meshes": meshes,
		"camera": {"samples": samples, "envelope_radius_m": .3, "minimum_clearance_m": camera_clearance},
		"mcp": "Blender status/scene and Godot get_state disconnected; standalone Godot fallback. Existing sources reused.",
		"scope": "Static geometry, support, two-sided fit, serialization and captures. No physics, navigation, continuous camera or performance acceptance."}
	FileAccess.open(ISLAND_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Archive island: %d island, %d shelf, %d room cases; passed=%s" % [island_cases.size(), shelf_cases.size(), island_room_cases.size(), str(failures.is_empty())])
	quit(0 if failures.is_empty() else 1)
