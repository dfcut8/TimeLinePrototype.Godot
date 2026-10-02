extends "res://assets/library_room_review/verify_room.gd"
## Measurements are in assembly coordinates, including after parent rotation.
const FURNISHED_OUT := "res://assets/furnished_room_review/"
var furnishing_stats: Dictionary = {}

func inspect_furnishings(room: Node3D) -> void:
	var base := room.get_node("BaseRoom") as Node3D
	inspect_room(base)
	var max_cap_error := 0.0
	var cap_count := 0
	var new_objects: Array[Node3D] = []
	for j in range(8):
		var shelf := base.get_node("Shelves/Shelf%d" % j) as Node3D
		var shelf_box := local_bounds(shelf.get_node("Shelf"), shelf)
		var pair := room.get_node("Caps%d" % j) as Node3D
		for side in ["Left", "Right"]:
			var cap := pair.get_node(side) as Node3D
			var box := local_bounds(cap, shelf)
			var error := absf(box.end.x-shelf_box.position.x) if side == "Left" else absf(box.position.x-shelf_box.end.x)
			max_cap_error = maxf(max_cap_error, error)
			check(error < .0001, "Room shelf/cap contact")
			check(absf(box.position.y) < .0001 and absf(box.end.y-shelf_box.end.y) < .0001, "Cap floor/header alignment")
			check(absf(box.position.z-shelf_box.position.z) < .0001 and absf(box.end.z-shelf_box.end.z) < .0001, "Cap depth coverage")
			check(cap.scale.is_equal_approx(Vector3.ONE), "Cap unit scale")
			new_objects.append(cap)
			cap_count += 1
	var max_contact := 0.0
	var min_display_margin := INF
	for j in range(4):
		var station := room.get_node("Station%d" % j) as Node3D
		for name in ["Bench", "Lectern", "Display"]:
			var object := station.get_node(name) as Node3D
			var box := local_bounds(object, station)
			check(absf(box.position.y) < .0001, "Furniture floor datum: " + name)
			check(object.scale.is_equal_approx(Vector3.ONE), "Furniture unit scale")
			new_objects.append(object)
		var bench := station.get_node("Bench") as Node3D
		for side in ["left", "right"]:
			var foot := part_bounds(bench, "floor_pad_" + side, station)
			check(absf(foot.position.y) < .0001, "Both bench feet on room floor datum")
		var display := station.get_node("Display") as Node3D
		var plinth := local_bounds(display.get_node("Plinth"), display)
		var record := local_bounds(display.get_node("Record"), display)
		max_contact = maxf(max_contact, absf(record.position.y-plinth.end.y))
		min_display_margin = minf(min_display_margin, minf(minf(record.position.x-plinth.position.x, plinth.end.x-record.end.x), minf(record.position.z-plinth.position.z, plinth.end.z-record.end.z)))
		var lectern := station.get_node("Lectern") as Node3D
		var marker := lectern.get_node("ScreenCenter") as Marker3D
		var normal := station.global_basis.inverse() * marker.global_basis.y
		check(normal.y > .95 and normal.z > .30, "Lectern screen slopes toward inward-facing user")
	check(max_contact < .0001 and min_display_margin > .008, "Cassette rests within flat plinth top")
	var clear_radius := INF
	var min_separation := INF
	for i in range(new_objects.size()):
		var object := new_objects[i]
		var box := local_bounds(object, room)
		var nearest := Vector2(clampf(0,box.position.x,box.end.x),clampf(0,box.position.z,box.end.z))
		clear_radius = minf(clear_radius,nearest.length())
		for k in range(i):
			check(not box.intersects(local_bounds(new_objects[k],room)), "Independent furnishing envelopes do not overlap")
		for portal_index in [0,12]:
			var portal := base.get_node("Perimeter/Bay%d" % portal_index) as Node3D
			check(not local_bounds(object,portal).intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))), "Furnishings clear portal approach")
		# Caps intentionally contact their shelves. Stations must leave an aisle.
		if str(object.get_parent().name).begins_with("Station"):
			var station_box := local_bounds(object,object.get_parent())
			for obstacle in base.get_node("Shelves").get_children() + base.get_node("Perimeter").get_children():
				# Use the station frame: world AABBs inflate diagonal wall depth.
				var other := local_bounds(obstacle,object.get_parent())
				var dx := maxf(0,maxf(station_box.position.x-other.end.x,other.position.x-station_box.end.x))
				var dz := maxf(0,maxf(station_box.position.z-other.end.z,other.position.z-station_box.end.z))
				min_separation = minf(min_separation,Vector2(dx,dz).length())
	check(clear_radius > 20, "Optional furniture outside 40 m camera clear volume")
	check(min_separation > 1.0, "Furniture leaves at least 1 m from shelves and architecture")
	furnishing_stats = {"end_caps":cap_count,"stations":4,"benches":4,"lecterns":4,"displays":4,
		"max_cap_join_error_m":max_cap_error,"max_display_contact_error_m":max_contact,
		"min_display_edge_margin_m":min_display_margin,"conservative_furniture_clear_radius_m":clear_radius,
		"min_furniture_architecture_separation_m":min_separation}

func verify() -> void:
	root.size = Vector2i(1280,900)
	var review := (load(FURNISHED_OUT + "review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	# Validate representative imported components, independently of spatial fit.
	for path in ["Caps0/Left","Caps0/Right","Station0/Bench","Station0/Lectern","Station0/Display"]:
		bounds(room.get_node(path),true)
	inspect_furnishings(room)
	room.transform = Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))
	inspect_furnishings(room)
	room.transform = Transform3D.IDENTITY
	var boxes: Array[AABB] = []
	for node in room.find_children("*","MeshInstance3D",true,false):
		var mesh := node as MeshInstance3D
		boxes.append((room.global_transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb())
	var min_clearance := INF
	var samples := 0
	for radius in [12.0,16.0,19.0]:
		for height in [1.8,4.0,8.0]:
			for degrees in range(0,360,5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius*sin(angle),height,-radius*cos(angle))
				for box in boxes:
					var nearest := Vector3(clampf(point.x,box.position.x,box.end.x),clampf(point.y,box.position.y,box.end.y),clampf(point.z,box.position.z,box.end.z))
					min_clearance = minf(min_clearance,point.distance_to(nearest)-.3)
				samples += 1
	check(min_clearance > 0,"All camera samples clear all imported meshes")
	furnishing_stats["camera_samples"] = samples
	furnishing_stats["camera_envelope_radius_m"] = .3
	furnishing_stats["min_camera_clearance_m"] = min_clearance
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	var station := room.get_node("Station0") as Node3D
	var shelf := room.get_node("BaseRoom/Shelves/Shelf0") as Node3D
	for view in [["overview",Vector3(38,42,45),Vector3.ZERO,60.0],
		["station_front",station.to_global(Vector3(2,2.5,6)),station.to_global(Vector3(0,.55,0)),5.8],
		["station_rear_cutaway",station.to_global(Vector3(-2,2,-4)),station.to_global(Vector3(0,.55,0)),5.8],
		["capped_shelf",shelf.to_global(Vector3(3,2,4)),shelf.to_global(Vector3(0,1.2,0)),3.8]]:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		# Only this documented inspection capture hides the perimeter.
		room.get_node("BaseRoom/Perimeter").visible = view[0] != "station_rear_cutaway"
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(FURNISHED_OUT+"godot_"+view[0]+".png") == OK,"GPU capture")
	room.get_node("BaseRoom/Perimeter").show()
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"issues":[29,34,35,36],"furnishings":furnishing_stats,
		"base_room":stats,"placements_tested":2,"validated_meshes":meshes,
		"mcp":"Blender status/scene and Godot get_state disconnected; standalone Godot fallback",
		"scope":"Optional static placement study; floor datum only. No production placement approval, physics, interactive camera or performance acceptance."}
	FileAccess.open(FURNISHED_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
