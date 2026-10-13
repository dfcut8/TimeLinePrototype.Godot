extends "res://assets/roofed_room_review/verify_roofed.gd"
## Measure reusable mixed shelves and perspective rail visibility in the room.
const REVIEW_OUT := "res://assets/rail_shelf_room_review/"

func inspect_mixed(mixed: Node3D) -> Dictionary:
	var shelf := mixed.get_node("Shelf") as Node3D
	var left := part_bounds(shelf, "upright_left", mixed)
	var right := part_bounds(shelf, "upright_right", mixed)
	var back := part_bounds(shelf, "closed_back", mixed)
	var contacts := 0.0
	var clearance := INF
	var light_gap := INF
	var neighbor_gap := INF
	var counts := {"small":0,"medium":0,"large":0}
	for tier in range(4):
		var deck := part_bounds(shelf, "shelf_%d_deck" % tier, mixed)
		var ceiling := part_bounds(shelf, "shelf_%d_rear_web" % (tier+1), mixed)
		var light := local_bounds(shelf.get_node("Light%d" % tier), mixed)
		var previous := AABB()
		for slot in range(9):
			var record := mixed.get_node("Record_%d_%d" % [tier,slot]) as Node3D
			var size: String = ["small","medium","large"][slot%3]
			counts[size] += 1
			check(record.scene_file_path == "res://assets/archive_record_%s/archive_record_%s.tscn" % [size,size], "Independent reusable cassette")
			check(record.scale.is_equal_approx(Vector3.ONE), "Unscaled cassette")
			var box := local_bounds(record, mixed)
			contacts = maxf(contacts, absf(box.position.y-deck.end.y))
			clearance = minf(clearance, minf(minf(box.position.x-left.end.x,right.position.x-box.end.x), minf(box.position.z-back.end.z,deck.end.z-box.end.z)))
			clearance = minf(clearance,ceiling.position.y-box.end.y)
			light_gap = minf(light_gap,light.position.y-box.end.y)
			if slot > 0:
				neighbor_gap = minf(neighbor_gap,box.position.x-previous.end.x)
			previous = box
	check(contacts < .0001, "Mixed cassette shelf contact")
	check(clearance > .02 and light_gap > .04 and neighbor_gap > .05, "Mixed cassette shelf/light/neighbor clearance")
	return {"counts":counts,"max_contact_error_m":contacts,"minimum_structure_clearance_m":clearance,
		"minimum_light_gap_m":light_gap,"minimum_neighbor_gap_m":neighbor_gap}

func save_view(camera: Camera3D, name: String, position: Vector3, target: Vector3) -> void:
	camera.global_position = position
	camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW_OUT+"godot_"+name+".png") == OK, "GPU capture")

func verify() -> void:
	root.size = Vector2i(1280,720)
	var review := (load("res://assets/rail_shelf_room_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	var mixed := room.get_node("MixedShelf") as Node3D
	var library := room.get_node("Library") as Node3D
	var base := library.get_node("GroundedRoom/Furnishings/BaseRoom") as Node3D
	var rail := base.get_node("Timeline") as Node3D
	var shelf_reports: Array[Dictionary] = []
	for placement in [Transform3D.IDENTITY, Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))]:
		room.transform = placement
		shelf_reports.append(inspect_mixed(mixed))
		var mixed_box := local_bounds(mixed,room)
		check(absf(mixed_box.position.y) < .0001, "Mixed bay floor contact")
		var nearest := Vector2(clampf(0,mixed_box.position.x,mixed_box.end.x),clampf(0,mixed_box.position.z,mixed_box.end.z))
		check(nearest.length() > 20, "Mixed bay outside central 40 m diameter")
		# Exact object frames avoid falsely overlapping the rotated wall AABBs.
		for group in [base.get_node("Perimeter"),base.get_node("Shelves"),library.get_node("RoofFrame")]:
			for other in group.get_children():
				check(not local_bounds(other,mixed).intersects(local_bounds(mixed,mixed)), "Mixed bay clears existing room objects")
		for index in [0,12]:
			var portal := base.get_node("Perimeter/Bay%d" % index) as Node3D
			check(not local_bounds(mixed,portal).intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))), "Mixed bay clears doorway approach")
		cache_floor(library.get_node("GroundedRoom/Floor"),room)
		# Avoid probing exactly along shared floor triangle edges at world Z=0.
		for x in [-.7,.1,.7]:
			for z in [-.15,.15]:
				check(supported(room.to_local(mixed.to_global(Vector3(x,0,z)))), "Mixed bay has actual floor support")
	room.transform = Transform3D.IDENTITY
	for slot in range(3):
		bounds(mixed.get_node("Record_0_%d" % slot),true)
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 65
	var orbit_reports: Array[Dictionary] = []
	for count in [1,3,7]:
		rail.set("module_count",count)
		rail.position.x = -float(count)
		var boxes: Array[AABB] = []
		for child in room.find_children("*","MeshInstance3D",true,false):
			var mesh := child as MeshInstance3D
			boxes.append(mesh.global_transform * mesh.mesh.get_aabb())
		var min_clearance := INF
		var min_span := INF
		var max_span := 0.0
		var min_front_height := INF
		var clipped_samples := 0
		var front_samples := 0
		# Measure the flat front face from the imported insert, excluding bevels.
		var light := rail.get_node("Modules/Module0/Light") as Node3D
		var light_vertices := vertices_in(light,light)
		var front_z := -INF
		for vertex in light_vertices:
			front_z = maxf(front_z,vertex.z)
		var face_top := -INF
		var face_bottom := INF
		for vertex in light_vertices:
			if absf(vertex.z-front_z) < .00001:
				face_top = maxf(face_top,vertex.y)
				face_bottom = minf(face_bottom,vertex.y)
		# Rear views deliberately see the finished housing, not its one-sided insert.
		for degrees in range(0,360,5):
			var angle := deg_to_rad(float(degrees))
			camera.position = Vector3(12*sin(angle),1.8,12*cos(angle))
			camera.look_at(Vector3(0,1.5,0))
			min_clearance = minf(min_clearance,envelope_clearance(camera.position,boxes))
			var earlier := rail.get_node("EarlierEnd") as Node3D
			var later := rail.get_node("LaterEnd") as Node3D
			var span := camera.unproject_position(earlier.global_position).distance_to(camera.unproject_position(later.global_position))
			min_span = minf(min_span,span)
			max_span = maxf(max_span,span)
			var clipped := false
			for vertex in vertices_in(rail,room):
				var world := room.to_global(vertex)
				if camera.is_position_behind(world) or not Rect2(Vector2.ZERO,Vector2(root.size)).has_point(camera.unproject_position(world)):
					clipped = true
			if clipped:
				clipped_samples += 1
			if cos(angle) >= .5:
				front_samples += 1
				var top := camera.unproject_position(base.to_global(Vector3(0,rail.position.y+face_top,front_z)))
				var bottom := camera.unproject_position(base.to_global(Vector3(0,rail.position.y+face_bottom,front_z)))
				min_front_height = minf(min_front_height,top.distance_to(bottom))
		check(min_clearance > 0, "Orbit clears entire room at rail count %d" % count)
		check(clipped_samples == 0, "Rail fits perspective frustum at every sample")
		# Provisional geometry diagnostic, not approval of event-text readability.
		check(min_front_height > .5, "Front insert exceeds half a pixel at 720p")
		orbit_reports.append({"module_count":count,"housing_length_m":2*count,"samples":72,"radius_m":12,
			"camera_height_m":1.8,"minimum_camera_clearance_m":min_clearance,"clipped_samples":clipped_samples,
			"minimum_endpoint_span_px":min_span,"maximum_endpoint_span_px":max_span,
			"front_sector_samples":front_samples,"minimum_front_insert_height_px":min_front_height})
		await save_view(camera,"rail_%dm_front" % (2*count),Vector3(0,1.8,12),Vector3(0,1.5,0))
	check(envelope_clearance(Vector3(22,1,0),[local_bounds(mixed,room)]) < 0,"Camera collision negative control")
	await save_view(camera,"rail_14m_end",Vector3(12,1.8,0),Vector3(0,1.5,0))
	await save_view(camera,"rail_14m_rear",Vector3(0,1.8,-12),Vector3(0,1.5,0))
	await save_view(camera,"mixed_shelf",mixed.to_global(Vector3(1.5,1.6,3.3)),mixed.to_global(Vector3(0,1.2,0)))
	# Standalone four-side capture keeps the closed back/underside inspectable.
	var isolated := (load("res://assets/record_stack_shelf_bay/mixed_cassette_shelf_bay.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(isolated)
	room.hide()
	for view in [["front",Vector3(.6,1.7,3.5)],["rear",Vector3(-.6,1.7,-3.5)],["side",Vector3(3,1.7,.6)],["underside",Vector3(1,-2,3)]]:
		await save_view(camera,"mixed_"+view[0],view[1],Vector3(0,1.2,0))
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"issues":[5,28],"mixed_shelf_placements":shelf_reports,
		"rail_orbits":orbit_reports,"viewport_px":[1280,720],"vertical_fov_degrees":65,"validated_meshes":meshes,
		"mcp":"Blender status/scene and Godot state disconnected; standalone Godot fallback",
		"limits":"Sampled static geometry, not continuous camera collision, event readability, interactive orbit, art approval or performance acceptance. Rear/end views intentionally expose the one-sided rail's visibility limitations."}
	FileAccess.open(REVIEW_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
