extends "res://assets/catalog_display_review/verify_display.gd"
## Actual imported-surface checks; the GPU run produces separate runtime evidence.
const CATALOG_OUT := "res://assets/catalog_perimeter_review/"
const CONFIG_STATION: PackedScene = preload("res://assets/catalog_lectern/configurable_catalog_station.tscn")
const CATALOG_ARC: PackedScene = preload("res://assets/wall_infill_bay/catalog_perimeter.tscn")
const ENTRANCE: PackedScene = preload("res://assets/passage_portal_bay_frame/catalog_entrance_sector.tscn")
const CATALOG_RING: PackedScene = preload("res://assets/wall_infill_bay/library_catalog_perimeter.tscn")
const FLOOR: PackedScene = preload("res://assets/grounded_room_review/library_floor.tscn")
var catalog_station_cases: Array[Dictionary] = []
var perimeter_cases: Array[Dictionary] = []
var catalog_room_cases: Array[Dictionary] = []
var floor_probes: int = 0

func inspect_catalog_station(station: Node3D, label: String, floor_space: Node3D) -> void:
	var left := station.get_node("DisplayLeft") as Node3D
	var right := station.get_node("DisplayRight") as Node3D
	inspect_display(left, int(station.get("left_cassette_size")), label + " left")
	inspect_display(right, int(station.get("right_cassette_size")), label + " right")
	var lectern := station.get_node("Lectern") as Node3D
	var approach: AABB = station.call("get_approach_bounds")
	check(absf(approach.size.z - float(station.get("approach_depth"))) < EPS, label + ": approach depth")
	check(absf(station.get_node("ApproachStart").position.z - approach.position.z) < EPS, label + ": approach start")
	check(absf(station.get_node("ApproachEnd").position.z - approach.end.z) < EPS, label + ": approach end")
	check(absf(station.get_node("UserApproach").position.z - approach.get_center().z) < EPS, label + ": user approach")
	check(absf(left.position.x + float(station.get("display_spacing"))) < EPS, label + ": left spacing")
	check(absf(right.position.x - float(station.get("display_spacing"))) < EPS, label + ": right spacing")
	check(absf(lectern.position.z - float(station.get("lectern_offset"))) < EPS, label + ": lectern offset")
	check(left.get("cassette_yaw_degrees") == station.get("left_cassette_yaw"), label + ": left yaw propagated")
	check(right.get("cassette_yaw_degrees") == station.get("right_cassette_yaw"), label + ": right yaw propagated")
	var marker := lectern.get_node("ScreenCenter") as Marker3D
	var normal := station.global_basis.inverse() * marker.global_basis.y
	check(normal.y > .95 and normal.z > .30, label + ": screen faces approach")
	check(segment_hits(lectern, marker.global_position + marker.global_basis.y * .001,
		marker.global_position - marker.global_basis.y * .001), label + ": screen marker hits insert")
	var objects: Array[Node3D] = [lectern, left, right]
	var min_internal_gap := INF
	var max_floor_error := 0.0
	for index in range(objects.size()):
		var object := objects[index]
		check(object.scale.is_equal_approx(Vector3.ONE), label + ": unscaled independent object")
		var box := local_bounds(object, station)
		check(not approach.intersects(box), label + ": front approach clear of furniture")
		for previous in range(index):
			var other := local_bounds(objects[previous], station)
			check(not box.intersects(other), label + ": furniture clearances")
			var dx := maxf(0.0, maxf(box.position.x - other.end.x, other.position.x - box.end.x))
			var dz := maxf(0.0, maxf(box.position.z - other.end.z, other.position.z - box.end.z))
			min_internal_gap = minf(min_internal_gap, Vector2(dx, dz).length())
		var support_object: Node3D = object if index == 0 else object.get_node("Plinth")
		var foot := part_bounds(support_object, "recessed_floor_foot" if index == 0 else "recessed_foot", support_object)
		for fx in [.2, .5, .8]:
			for fz in [.2, .5, .8]:
				var point := floor_space.to_local(support_object.to_global(Vector3(
					lerpf(foot.position.x, foot.end.x, fx), foot.position.y, lerpf(foot.position.z, foot.end.z, fz))))
				max_floor_error = maxf(max_floor_error, absf(point.y))
				check(floor_supported(point), label + ": actual floor beneath feet")
				floor_probes += 1
	for fx in [.02, .5, .98]:
		for fz in [0.0, .25, .5, .75, 1.0]:
			var point := floor_space.to_local(station.to_global(Vector3(
				lerpf(approach.position.x, approach.end.x, fx), 0, lerpf(approach.position.z, approach.end.z, fz))))
			check(floor_supported(point), label + ": floor through approach")
			floor_probes += 1
	check(max_floor_error < EPS, label + ": floor datum within 0.1 mm")
	catalog_station_cases.append({"case": label, "spacing_m": station.get("display_spacing"),
		"lectern_offset_m": station.get("lectern_offset"), "approach_depth_m": approach.size.z,
		"left_size": station.get("left_cassette_size"), "right_size": station.get("right_cassette_size"),
		"min_internal_gap_m": min_internal_gap, "max_floor_contact_error_m": max_floor_error})

func disk_copy(object: Node3D, filename: String) -> Node3D:
	var packed := PackedScene.new()
	check(packed.pack(object) == OK, "Pack " + filename)
	check(ResourceSaver.save(packed, "user://" + filename + ".tscn") == OK, "Save " + filename)
	var restored := (load("user://" + filename + ".tscn") as PackedScene).instantiate() as Node3D
	root.add_child(restored)
	return restored

func attachment(object: Node3D, path: String = "Attachments") -> Marker3D:
	var marker := Marker3D.new()
	marker.name = "UserAttachment"
	object.get_node(path).add_child(marker)
	marker.owner = object
	return marker

func verify_station_configurations(space: Node3D) -> void:
	var station := CONFIG_STATION.instantiate() as Node3D
	station.set("display_spacing", 1.1)
	station.set("left_cassette_size", 1)
	root.add_child(station)
	inspect_catalog_station(station, "before ready", space)
	var sentinel := attachment(station)
	var fixed_ids := [station.get_node("Lectern").get_instance_id(),
		station.get_node("DisplayLeft/Plinth").get_instance_id(), station.get_node("DisplayRight/Plinth").get_instance_id()]
	for spacing in [.75, .9, 1.25]:
		for offset in [.6, .8, 1.0]:
			for depth in [.8, 1.0, 1.5]:
				station.set("display_spacing", spacing)
				station.set("lectern_offset", offset)
				station.set("approach_depth", depth)
				inspect_catalog_station(station, "geometry %.2f/%.1f/%.1f" % [spacing, offset, depth], space)
	for left_size in range(3):
		for right_size in range(3):
			station.set("left_cassette_size", left_size)
			station.set("right_cassette_size", right_size)
			for yaw in [-180.0, -67.0, 30.0, 180.0]:
				var record_id := station.get_node("DisplayLeft/RecordSlot/Cassette").get_instance_id()
				station.set("left_cassette_yaw", yaw)
				station.set("right_cassette_yaw", -yaw)
				check(station.get_node("DisplayLeft/RecordSlot/Cassette").get_instance_id() == record_id, "Yaw retains cassette identity")
				inspect_catalog_station(station, "records %d/%d yaw %.0f" % [left_size, right_size, yaw], space)
	check(fixed_ids == [station.get_node("Lectern").get_instance_id(), station.get_node("DisplayLeft/Plinth").get_instance_id(),
		station.get_node("DisplayRight/Plinth").get_instance_id()], "Configuration retains lectern and plinths")
	check(is_instance_valid(sentinel), "Station attachment retained")
	for values in [[-8.0, -8.0, -8.0, -8, -8, -900.0], [8.0, 8.0, 8.0, 8, 8, 900.0]]:
		station.set("display_spacing", values[0])
		station.set("lectern_offset", values[1])
		station.set("approach_depth", values[2])
		station.set("left_cassette_size", values[3])
		station.set("right_cassette_size", values[4])
		station.set("left_cassette_yaw", values[5])
		station.set("right_cassette_yaw", values[5])
		check(station.get("display_spacing") == (.75 if values[0] < 0 else 1.25), "Spacing clamp")
		check(station.get("lectern_offset") == (.6 if values[0] < 0 else 1.0), "Offset clamp")
		check(station.get("approach_depth") == (.8 if values[0] < 0 else 1.5), "Approach clamp")
		check(station.get("left_cassette_size") == (0 if values[0] < 0 else 2), "Size clamp")
		check(station.get("left_cassette_yaw") == (-180.0 if values[0] < 0 else 180.0), "Yaw clamp")
		inspect_catalog_station(station, "clamps " + str(values[0]), space)
	station.transform = Transform3D(Basis(Vector3.UP, .71), Vector3(8, 0, -6))
	inspect_catalog_station(station, "transformed station", space)
	var restored := disk_copy(station, "catalog_station")
	inspect_catalog_station(restored, "disk roundtrip", space)
	check(restored.has_node("Attachments/UserAttachment"), "Station persistent attachment roundtrip")
	check(restored.get_node("DisplayLeft/RecordSlot").get_child_count() == 1, "Roundtrip no duplicated cassette")
	restored.set("left_cassette_size", 0)
	check(station.get("left_cassette_size") == 2, "Independent station instances")
	root.remove_child(restored)
	restored.set("lectern_offset", .6)
	restored.set("right_cassette_size", 1)
	root.add_child(restored)
	inspect_catalog_station(restored, "detached configuration", space)
	station.queue_free()
	restored.queue_free()
	await process_frame

func inspect_perimeter(perimeter: Node3D, expected: PackedInt32Array, label: String, floor_space: Node3D) -> void:
	check(perimeter.get("active_station_bays") == expected, label + ": effective station indices")
	var station_nodes: Array[Node] = []
	for child in perimeter.get_node("Stations").get_children():
		if child.scene_file_path == CONFIG_STATION.resource_path:
			station_nodes.append(child)
	check(station_nodes.size() == expected.size(), label + ": exactly requested eligible stations")
	var architecture := perimeter.get_node("Architecture") as Node3D
	var layout: PackedInt32Array = perimeter.get("bay_layout")
	check(architecture.get_node("Bays").get_child_count() == layout.size(), label + ": bay count")
	check(architecture.get_node("Piers").get_child_count() == (24 if layout.size() == 24 else layout.size() + 1), label + ": shared pier count")
	var min_wall_gap := INF
	var min_clear_radius := INF
	var max_alignment_error := 0.0
	for index in expected:
		var station := perimeter.get_node("Stations/Station%d" % index) as Node3D
		var wall := architecture.get_node("Bays/Bay%d" % index) as Node3D
		check(layout[index] == 0 and station.owner == null, label + ": generated scene on solid wall")
		check(station.scale.is_equal_approx(Vector3.ONE), label + ": unscaled station")
		var relative := wall.global_transform.affine_inverse() * station.global_transform
		max_alignment_error = maxf(max_alignment_error, relative.origin.distance_to(Vector3(0, 0, 2.3)))
		check(relative.basis.is_equal_approx(Basis.IDENTITY), label + ": station faces same direction as bay")
		var box := local_bounds(station, wall)
		min_wall_gap = minf(min_wall_gap, box.position.z - local_bounds(wall, wall).end.z)
		for obstacle in architecture.get_node("Bays").get_children() + architecture.get_node("Piers").get_children():
			check(not local_bounds(station, station).intersects(local_bounds(obstacle, station)), label + ": furniture clears architecture")
			check(not (station.call("get_approach_bounds") as AABB).intersects(local_bounds(obstacle, station)), label + ": approach clears architecture")
		for portal_index in range(layout.size()):
			if layout[portal_index] != 1:
				continue
			var portal := architecture.get_node("Bays/Bay%d" % portal_index) as Node3D
			var reserved := AABB(Vector3(-1.5, 0, -1), Vector3(3, 3.4, 6))
			check(not local_bounds(station, portal).intersects(reserved), label + ": complete portal approach clear")
			var approach_in_portal: AABB = (portal.global_transform.affine_inverse() * station.global_transform) * (station.call("get_approach_bounds") as AABB)
			check(not approach_in_portal.intersects(reserved), label + ": user approach clears portal approach")
		for other in station_nodes:
			if other == station:
				continue
			check(not local_bounds(station, station).intersects(local_bounds(other, station)), label + ": neighboring stations clear")
			check(not (station.call("get_approach_bounds") as AABB).intersects(local_bounds(other, station)), label + ": approach clears neighboring furniture")
		var in_perimeter := local_bounds(station, perimeter)
		min_clear_radius = minf(min_clear_radius, Vector2(clampf(0, in_perimeter.position.x, in_perimeter.end.x),
			clampf(0, in_perimeter.position.z, in_perimeter.end.z)).length())
		inspect_catalog_station(station, label + " station%d" % index, floor_space)
	check(max_alignment_error < EPS, label + ": bay interface error below 0.1 mm")
	check(expected.is_empty() or min_wall_gap > 1.6, label + ": station wall setback")
	check(expected.is_empty() or min_clear_radius > 20, label + ": central 40 m clear diameter")
	perimeter_cases.append({"case": label, "bays": layout.size(), "stations": Array(expected),
		"max_alignment_error_m": max_alignment_error, "min_wall_gap_m": min_wall_gap if not expected.is_empty() else null,
		"min_central_radius_m": min_clear_radius if not expected.is_empty() else null})

func verify_perimeter_configurations(space: Node3D) -> void:
	var perimeter := CATALOG_ARC.instantiate() as Node3D
	perimeter.set("station_bays", PackedInt32Array([2, 0, 2, -1, 24, 1]))
	root.add_child(perimeter)
	check(perimeter.get("station_bays") == PackedInt32Array([0, 1, 2]), "Indices sanitized and sorted")
	inspect_perimeter(perimeter, PackedInt32Array([0, 2]), "before ready and portal request", space)
	var sentinel := attachment(perimeter)
	var slot_sentinel := attachment(perimeter, "Stations")
	var station_id := perimeter.get_node("Stations/Station0").get_instance_id()
	for angle in [-180.0, -45.0, 0.0, 37.0, 180.0]:
		perimeter.set("start_angle_degrees", angle)
		inspect_perimeter(perimeter, PackedInt32Array([0, 2]), "rotated grid %.0f" % angle, space)
		check(perimeter.get_node("Stations/Station0").get_instance_id() == station_id, "Angle changes retain station")
	var copy: PackedInt32Array = perimeter.get("bay_layout")
	copy[0] = 2
	check(perimeter.get("bay_layout")[0] == 0, "Layout getter is independent")
	copy = perimeter.get("station_bays")
	copy.clear()
	check(perimeter.get("station_bays").size() == 3, "Station index getter is independent")
	perimeter.set("bay_layout", PackedInt32Array([1, 2, 0]))
	inspect_perimeter(perimeter, PackedInt32Array([2]), "wall becomes portal", space)
	perimeter.set("bay_layout", PackedInt32Array([1, 2, 1]))
	inspect_perimeter(perimeter, PackedInt32Array(), "no eligible walls", space)
	perimeter.set("bay_layout", PackedInt32Array([0, 0, 0]))
	inspect_perimeter(perimeter, PackedInt32Array([0, 1, 2]), "dormant requests become walls", space)
	perimeter.set("station_bays", PackedInt32Array())
	inspect_perimeter(perimeter, PackedInt32Array(), "empty station selection", space)
	perimeter.set("station_bays", PackedInt32Array([0, 1, 2]))
	perimeter.set("bay_layout", PackedInt32Array())
	inspect_perimeter(perimeter, PackedInt32Array([0]), "empty layout wall fallback", space)
	perimeter.set("bay_layout", PackedInt32Array([-9, 9, 1]))
	check(perimeter.get("bay_layout") == PackedInt32Array([0, 2, 1]), "Bay type clamp")
	inspect_perimeter(perimeter, PackedInt32Array([0]), "invalid bay types", space)
	perimeter.set("start_angle_degrees", -900.0)
	check(perimeter.get("start_angle_degrees") == -180.0, "Lower angle clamp")
	perimeter.set("start_angle_degrees", 900.0)
	check(perimeter.get("start_angle_degrees") == 180.0, "Upper angle clamp")
	perimeter.set("bay_layout", PackedInt32Array([0, 1, 0]))
	perimeter.set("start_angle_degrees", -15.0)
	(perimeter.get_node("Stations") as Node3D).transform = Transform3D(Basis(Vector3.UP, .3), Vector3(1, 0, 2))
	perimeter.set("station_bays", perimeter.get("station_bays"))
	inspect_perimeter(perimeter, PackedInt32Array([0, 2]), "edited station container", space)
	(perimeter.get_node("Stations") as Node3D).transform = Transform3D.IDENTITY
	perimeter.set("station_bays", perimeter.get("station_bays"))
	check(is_instance_valid(sentinel) and is_instance_valid(slot_sentinel), "Persistent perimeter additions retained")
	var restored := disk_copy(perimeter, "catalog_perimeter")
	inspect_perimeter(restored, PackedInt32Array([0, 2]), "disk roundtrip", space)
	check(restored.has_node("Attachments/UserAttachment") and restored.has_node("Stations/UserAttachment"), "Perimeter additions serialize")
	restored.set("station_bays", PackedInt32Array([2]))
	check(perimeter.get("active_station_bays") == PackedInt32Array([0, 2]), "Independent perimeter instances")
	root.remove_child(restored)
	restored.set("bay_layout", PackedInt32Array([0, 0, 0]))
	restored.set("station_bays", PackedInt32Array([1]))
	root.add_child(restored)
	inspect_perimeter(restored, PackedInt32Array([1]), "detached configuration", space)
	for variant in [ENTRANCE, CATALOG_RING]:
		var saved := variant.instantiate() as Node3D
		root.add_child(saved)
		inspect_perimeter(saved, PackedInt32Array([0, 2]) if variant == ENTRANCE else PackedInt32Array([1, 11, 13, 23]), "saved variant " + variant.resource_path, space)
		if variant == CATALOG_RING:
			var indices := PackedInt32Array()
			for i in range(30):
				indices.append(i)
			saved.set("station_bays", indices)
			var expected := PackedInt32Array()
			for i in range(24):
				if i not in [0, 6, 12, 18]:
					expected.append(i)
			inspect_perimeter(saved, expected, "all twenty wall bays", space)
			var layout: PackedInt32Array = saved.get("bay_layout")
			layout.append(0)
			saved.set("bay_layout", layout)
			check(saved.get("bay_layout").size() == 24, "Layout maximum 24")
			inspect_perimeter(saved, expected, "oversized ring clamped", space)
			saved.set("start_angle_degrees", 37.0)
			inspect_perimeter(saved, expected, "rotated full ring", space)
		saved.queue_free()
	perimeter.queue_free()
	restored.queue_free()
	await process_frame

func inspect_catalog_room(room: Node3D, label: String) -> void:
	cache_floor(room.get_node("Floor"), room)
	var perimeter := room.get_node("Perimeter") as Node3D
	inspect_perimeter(perimeter, PackedInt32Array([1, 11, 13, 23]), label, room)
	var architecture := perimeter.get_node("Architecture") as Node3D
	var portal_floor_probes := 0
	for index in [0, 12]:
		var portal := architecture.get_node("Bays/Bay%d" % index) as Node3D
		for x in [-1.49, -.75, 0, .75, 1.49]:
			for step in range(25):
				var point := room.to_local(portal.to_global(Vector3(x, 0, -1.0 + .25 * step)))
				check(floor_supported(point), label + ": continuous portal floor")
				portal_floor_probes += 1
			for y in [.001, 1.7, 3.399]:
				check(not segment_hits(portal, portal.to_global(Vector3(x, y, -1)), portal.to_global(Vector3(x, y, 1))), label + ": no blocked opening")
	var min_alcove_gap := INF
	for index in [1, 11, 13, 23]:
		var station := perimeter.get_node("Stations/Station%d" % index) as Node3D
		var box := local_bounds(station, station)
		var approach: AABB = station.call("get_approach_bounds")
		for name in ["AlcoveEast", "AlcoveWest"]:
			var alcove := room.get_node(name) as Node3D
			var other := local_bounds(alcove, station)
			check(not box.intersects(other) and not approach.intersects(other), label + ": alcoves and approaches clear")
			var dx := maxf(0.0, maxf(box.position.x - other.end.x, other.position.x - box.end.x))
			var dz := maxf(0.0, maxf(box.position.z - other.end.z, other.position.z - box.end.z))
			min_alcove_gap = minf(min_alcove_gap, Vector2(dx, dz).length())
	catalog_room_cases.append({"case": label, "portal_floor_probes": portal_floor_probes, "min_alcove_gap_m": min_alcove_gap})

func catalog_capture(camera: Camera3D, label: String, position: Vector3, target: Vector3, span: float = 0.0) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if span > 0 else Camera3D.PROJECTION_PERSPECTIVE
	camera.size = span if span > 0 else 5.0
	camera.fov = 60.0
	camera.global_position = position
	camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(CATALOG_OUT + "godot_" + label + ".png") == OK, "GPU capture")

func verify() -> void:
	root.size = Vector2i(1100, 760)
	var floor_node := FLOOR.instantiate() as Node3D
	root.add_child(floor_node)
	cache_floor(floor_node, floor_node)
	check(floor_supported(Vector3(2, 0, 2)), "Floor positive control")
	check(not floor_supported(Vector3(2, .01, 2)), "Floating contact rejected")
	check(not floor_supported(Vector3(2, -.01, 2)), "Buried contact rejected")
	check(not floor_supported(Vector3(33, 0, 0)), "Absent floor rejected")
	await verify_station_configurations(floor_node)
	await verify_perimeter_configurations(floor_node)
	floor_node.queue_free()
	await process_frame
	var review := (load(CATALOG_OUT + "review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	for placement in [Transform3D.IDENTITY, Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))]:
		room.transform = placement
		inspect_catalog_room(room, "room " + str(placement.origin))
	var restored_room := disk_copy(room, "catalog_room")
	inspect_catalog_room(restored_room, "complete room disk roundtrip")
	restored_room.queue_free()
	await process_frame
	room.transform = Transform3D.IDENTITY
	var station := room.get_node("Perimeter/Stations/Station1") as Node3D
	for object in [station.get_node("Lectern"), station.get_node("DisplayLeft"), station.get_node("DisplayRight"),
		room.get_node("Perimeter/Architecture/Bays/Bay1"), room.get_node("Perimeter/Architecture/Bays/Bay0")]:
		bounds(object, true)
	var boxes: Array[AABB] = []
	for child in room.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		boxes.append(mesh.global_transform * mesh.mesh.get_aabb())
	var min_camera := INF
	var camera_samples := 0
	for radius in [12.0, 16.0, 19.0]:
		for height in [1.8, 4.0, 8.0]:
			for degrees in range(0, 360, 5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius * sin(angle), height, radius * cos(angle))
				for box in boxes:
					var nearest := Vector3(clampf(point.x, box.position.x, box.end.x), clampf(point.y, box.position.y, box.end.y), clampf(point.z, box.position.z, box.end.z))
					min_camera = minf(min_camera, point.distance_to(nearest) - .3)
				camera_samples += 1
	check(min_camera > 0, "Sampled camera envelopes clear full room")
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await catalog_capture(camera, "room", Vector3(38, 42, 45), Vector3.ZERO, 70)
	await catalog_capture(camera, "entrance", Vector3(0, 3.5, -15), Vector3(0, 1.5, -24.6))
	await catalog_capture(camera, "station", station.to_global(Vector3(0, 2.1, 4.5)), station.to_global(Vector3(0, .55, .1)))
	await catalog_capture(camera, "floor", station.to_global(Vector3(2, .25, 2)), station.to_global(Vector3(0, .1, 0)))
	room.hide()
	var isolated := CONFIG_STATION.instantiate() as Node3D
	isolated.set("left_cassette_size", 1)
	root.add_child(isolated)
	bounds(isolated.get_node("DisplayLeft"), true)
	await catalog_capture(camera, "rear", Vector3(-3, 2.4, -5), Vector3(0, .55, .1))
	await catalog_capture(camera, "end", Vector3(5, 1.5, .5), Vector3(0, .55, .1))
	await catalog_capture(camera, "underside", Vector3(2, -2, 3.5), Vector3(0, .5, .1))
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"passed": failures.is_empty(), "failures": failures, "issues": [24, 25, 34, 36],
		"catalog_station_cases": catalog_station_cases, "display_cases": display_cases,
		"perimeter_cases": perimeter_cases, "catalog_room_cases": catalog_room_cases, "floor_probes": floor_probes,
		"camera_samples": camera_samples, "camera_envelope_radius_m": .3, "min_camera_clearance_m": min_camera,
		"validated_imported_surfaces": meshes, "mcp": "Blender status/scene and Godot get_state failed; standalone Godot fallback",
		"limits": "Static assembly fit; live MCP, art approval, roof, interaction, physics and performance remain pending."}
	FileAccess.open(CATALOG_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Catalog checks: %d stations, %d perimeters, %d rooms; failures=%d" % [catalog_station_cases.size(), perimeter_cases.size(), catalog_room_cases.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
