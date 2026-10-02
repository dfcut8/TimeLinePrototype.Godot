extends "res://assets/wall_portal_review/verify_godot.gd"
## Reuse imported-triangle probes; all fit measurements use the object's frame.
const ROOM_OUT := "res://assets/library_room_review/"
var stats: Dictionary = {}

func local_bounds(node: Node3D, space: Node3D) -> AABB:
	return bounds_in(node, space.global_transform.affine_inverse())

func part_bounds(node: Node3D, suffix: String, space: Node3D) -> AABB:
	var matches := node.find_children("*" + suffix, "MeshInstance3D", true, false)
	check(matches.size() == 1, "Unique support mesh " + suffix)
	if matches.size() != 1:
		return AABB()
	var mesh := matches[0] as MeshInstance3D
	return (space.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()

func inspect_room(room: Node3D) -> void:
	var perimeter := room.get_node("Perimeter")
	check(perimeter.get_child_count() == 48, "24 bays and 24 shared piers, including wraparound")
	var min_join := INF
	var max_join := 0.0
	var probes := 0
	for i in range(24):
		var bay := perimeter.get_node("Bay%d" % i) as Node3D
		var box := local_bounds(bay, bay)
		check(bay.scale.is_equal_approx(Vector3.ONE), "Unscaled bay")
		check(absf(box.position.y) < .0001 and absf(box.end.y - 4.75) < .0001, "Bay floor/header")
		for side in range(2):
			var pier := perimeter.get_node("Pier%d" % ((i + side) % 24)) as Node3D
			var pier_box := local_bounds(pier, bay)
			var gap := box.position.x - pier_box.end.x if side == 0 else pier_box.position.x - box.end.x
			min_join = minf(min_join, gap)
			max_join = maxf(max_join, gap)
			check(gap > .008 and gap < .010, "Bay/pier interface %d/%d" % [i, side])
		if i in [6, 18]:
			continue
		for x in [-1.501, -1.499, 0.0, 1.499, 1.501]:
			for y in [.001, 1.7, 3.399, 3.401]:
				var expected: bool = i not in [0, 12] or absf(x) > 1.5 or y > 3.4
				check(segment_hits(bay, bay.to_global(Vector3(x,y,1)), bay.to_global(Vector3(x,y,-1))) == expected, "Wall/portal triangle probe")
				probes += 1
	var min_clear_radius := INF
	# A conservative radial lower bound for every imported mesh's room-space AABB.
	for group in [room.get_node("Perimeter"), room.get_node("Shelves")]:
		for child in group.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			var box: AABB = (room.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()
			var nearest := Vector2(clampf(0, box.position.x, box.end.x), clampf(0, box.position.z, box.end.z))
			min_clear_radius = minf(min_clear_radius, nearest.length())
	check(min_clear_radius > 20, "Architecture and furnishings leave 40 m central diameter clear")
	var counts := {"small": 0, "large": 0}
	var max_contact := 0.0
	var min_clearance := INF
	var min_light := INF
	for j in range(8):
		var populated := room.get_node("Shelves/Shelf%d" % j) as Node3D
		var shelf := populated.get_node("Shelf") as Node3D
		var small: bool = j % 2 == 0
		var expected_path := "res://assets/archive_record_%s/shelf_assembly.tscn" % ("small" if small else "large")
		check(populated.scene_file_path == expected_path, "Reusable populated shelf scene")
		var left := part_bounds(shelf, "upright_left", populated)
		var right := part_bounds(shelf, "upright_right", populated)
		var back := part_bounds(shelf, "closed_back", populated)
		var boxes: Array[AABB] = []
		var count := 0
		for child in populated.get_children():
			if not str(child.name).begins_with("Record_"):
				continue
			var record := child as Node3D
			var tier := int(str(record.name).split("_")[1])
			var box := local_bounds(record, populated)
			var deck := part_bounds(shelf, "shelf_%d_deck" % tier, populated)
			var ceiling := part_bounds(shelf, "shelf_%d_rear_web" % (tier+1), populated)
			var light := local_bounds(shelf.get_node("Light%d" % tier), populated)
			check(record.scale.is_equal_approx(Vector3.ONE), "Unscaled cassette")
			max_contact = maxf(max_contact, absf(box.position.y - deck.end.y))
			min_clearance = minf(min_clearance, minf(minf(box.position.x-left.end.x, right.position.x-box.end.x), minf(box.position.z-back.end.z, deck.end.z-box.end.z)))
			min_clearance = minf(min_clearance, ceiling.position.y-box.end.y)
			min_light = minf(min_light, light.position.y-box.end.y)
			for previous in boxes:
				check(not box.intersects(previous), "No cassette overlap")
			boxes.append(box)
			count += 1
		check(count == (68 if small else 44), "Populated record count")
		counts["small" if small else "large"] += count
		# Test shelf setback against its corresponding wall in the wall's own frame.
		var bay_index: int = [2,4,8,10,14,16,20,22][j]
		var wall := perimeter.get_node("Bay%d" % bay_index) as Node3D
		var wall_box := local_bounds(wall, wall)
		var shelf_box := local_bounds(populated, wall)
		check(shelf_box.position.z - wall_box.end.z > 1.2, "Shelf/wall setback exceeds 1.2 m")
		# Keep the entire 3 m doorway approach free, from the wall to clear volume.
		for portal_index in [0,12]:
			var portal := perimeter.get_node("Bay%d" % portal_index) as Node3D
			var in_portal := local_bounds(populated, portal)
			check(not in_portal.intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))), "Clear portal approach")
	check(max_contact < .0001, "Cassette support contact under all room rotations")
	check(min_clearance > .001 and min_light > .04, "Cassette structure and light clearance")
	stats = {"bay_count":24,"shared_piers":24,"wall_bays":20,"portals":2,"windows":2,
		"join_min_m":min_join,"join_max_m":max_join,"triangle_probes_per_placement":probes,
		"conservative_clear_radius_m":min_clear_radius,"cassettes":counts,
		"max_support_error_m":max_contact,"min_shelf_clearance_m":min_clearance,"min_light_clearance_m":min_light}

func verify() -> void:
	root.size = Vector2i(1280, 900)
	var review := (load(ROOM_OUT + "review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	inspect_room(room)
	room.transform = Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))
	inspect_room(room)
	room.transform = Transform3D.IDENTITY
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	var rail_box := local_bounds(room.get_node("Timeline"), room)
	var orbit_min_clearance := INF
	var orbit_samples := 0
	# 0.3 m camera envelope: sampled orbits, not a gameplay collision system.
	for radius in [12.0, 16.0, 19.0]:
		for height in [1.8, 4.0, 8.0]:
			for degrees in range(0,360,5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius*sin(angle),height,-radius*cos(angle))
				var nearest := Vector3(clampf(point.x,rail_box.position.x,rail_box.end.x),clampf(point.y,rail_box.position.y,rail_box.end.y),clampf(point.z,rail_box.position.z,rail_box.end.z))
				var clearance := minf(point.distance_to(nearest), float(stats.conservative_clear_radius_m)-radius) - .3
				orbit_min_clearance = minf(orbit_min_clearance,clearance)
				check(clearance > 0, "Camera sample clears rail, architecture and furnishings")
				orbit_samples += 1
	stats["camera_samples"] = orbit_samples
	stats["camera_envelope_radius_m"] = .3
	stats["min_camera_clearance_m"] = orbit_min_clearance
	for view in [["overview",Vector3(38,42,45),Vector3(0,0,0),60.0],
		["portal",Vector3(0,3,-16),Vector3(0,2,-24.6),12.0],
		["small_shelf",Vector3(9,3,-15),Vector3(11.5,1.2,-19.9186),5.0],
		["large_shelf",Vector3(15,3,-9),Vector3(19.9186,1.2,-11.5),5.0]]:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(ROOM_OUT + "godot_room_" + view[0] + ".png") == OK, "Room GPU capture")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"room":stats,"placements_tested":2,
		"mcp":"Blender status/scene and Godot get_state disconnected; standalone Godot fallback",
		"scope":"Static perimeter and cassette fit. No floor/roof, physics, live text, interactive orbit or performance acceptance."}
	FileAccess.open(ROOM_OUT + "godot_room_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
