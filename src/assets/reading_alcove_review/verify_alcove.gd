extends "res://assets/grounded_room_review/verify_grounded.gd"
## Check imported surfaces in object coordinates, then probe the real floor.
const ALCOVE_OUT := "res://assets/reading_alcove_review/"
const MIXED_ROW: PackedScene = preload("res://assets/record_stack_end_cap/capped_mixed_shelf_row.tscn")
const EMPTY_ROW: PackedScene = preload("res://assets/record_stack_end_cap/configurable_shelf_row.tscn")
const MIXED_BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/mixed_cassette_shelf_bay.tscn")
const TOLERANCE: float = .0001
var row_cases: Array[Dictionary] = []
var alcove_cases: Array[Dictionary] = []

func floor_supported(point: Vector3) -> bool:
	# A segment exactly on a triangle edge can miss after parent transforms.
	# Require support on BOTH sides within 10 micrometres in that case.
	var edge_offset := Vector3(.00001,0,.00001)
	return supported(point) or (supported(point+edge_offset) and supported(point-edge_offset))

func inspect_row(row: Node3D, count: int, populated: bool, label: String) -> void:
	var bays := row.get_node("Bays")
	check(bays.get_child_count() == count, label + ": generated bay count")
	var first := AABB()
	var previous := AABB()
	var seam_error := 0.0
	var records := 0
	var contact_error := 0.0
	var min_record_gap := INF
	for index in range(count):
		var bay := bays.get_node("Bay%d" % index) as Node3D
		var shelf: Node3D = bay.get_node("Shelf") if populated else bay
		check(bay.scene_file_path == (MIXED_BAY.resource_path if populated else "res://assets/record_stack_shelf_bay/illuminated_shelf_bay.tscn"), label + ": reusable bay")
		check(bay.scale.is_equal_approx(Vector3.ONE), label + ": unit scale")
		var box := local_bounds(shelf, row)
		check(box.size.distance_to(Vector3(1.6,2.4,.44)) < TOLERANCE, label + ": shelf interface")
		check(absf(box.position.y) < TOLERANCE, label + ": floor datum")
		if index == 0:
			first = box
		else:
			seam_error = maxf(seam_error, absf(box.position.x - previous.end.x))
		previous = box
		for tier in range(4):
			check(shelf.get_node("Light%d" % tier).scene_file_path.ends_with("shelf_light_channel.tscn"), label + ": independent light")
			if not populated:
				continue
			var deck := part_bounds(shelf, "shelf_%d_deck" % tier, bay)
			var light := local_bounds(shelf.get_node("Light%d" % tier), bay)
			var previous_record := AABB()
			for slot in range(9):
				var record := bay.get_node("Record_%d_%d" % [tier,slot]) as Node3D
				var size: String = ["small","medium","large"][slot % 3]
				check(record.scene_file_path.ends_with("archive_record_%s.tscn" % size), label + ": independent cassette")
				check(record.scale.is_equal_approx(Vector3.ONE), label + ": cassette scale")
				var record_box := local_bounds(record, bay)
				contact_error = maxf(contact_error, absf(record_box.position.y-deck.end.y))
				check(light.position.y-record_box.end.y > .04, label + ": cassette light clearance")
				if slot > 0:
					min_record_gap = minf(min_record_gap, record_box.position.x-previous_record.end.x)
				previous_record = record_box
				records += 1
	var left := local_bounds(row.get_node("CapLeft"), row)
	var right := local_bounds(row.get_node("CapRight"), row)
	var cap_error := maxf(absf(left.end.x-first.position.x), absf(right.position.x-previous.end.x))
	for name in ["CapLeft","CapRight"]:
		var cap := row.get_node(name) as Node3D
		var box := local_bounds(cap,row)
		check(cap.scale.is_equal_approx(Vector3.ONE), label + ": cap rotation without mirroring")
		check(absf(box.position.y) < TOLERANCE and absf(box.end.y-2.4) < TOLERANCE, label + ": cap height")
		check(absf(box.position.z+.22) < TOLERANCE and absf(box.end.z-.22) < TOLERANCE, label + ": full depth closure")
	check(left.position.x < first.position.x and right.end.x > previous.end.x, label + ": outward caps")
	check(cap_error < TOLERANCE and seam_error < TOLERANCE, label + ": cap and bay seams")
	check(absf(local_bounds(row,row).size.x-(1.6*count+.164)) < TOLERANCE, label + ": complete width")
	check(absf((row.get_node("LeftJoin") as Node3D).position.x-first.position.x) < TOLERANCE, label + ": left attachment marker")
	check(absf((row.get_node("RightJoin") as Node3D).position.x-previous.end.x) < TOLERANCE, label + ": right attachment marker")
	check(contact_error < TOLERANCE, label + ": cassette support")
	check(records == (count*36 if populated else 0), label + ": cassette count")
	if populated:
		check(min_record_gap > .05, label + ": cassette neighbors")
	row_cases.append({"case":label,"bays":count,"records":records,"cap_join_error_m":cap_error,
		"bay_seam_error_m":seam_error,"cassette_contact_error_m":contact_error,"width_m":local_bounds(row,row).size.x})

func inspect_alcove(alcove: Node3D, room: Node3D, base: Node3D) -> void:
	var row := alcove.get_node("ShelfRow") as Node3D
	var bench := alcove.get_node("Bench") as Node3D
	inspect_row(row, 2, true, str(alcove.name))
	var row_box := local_bounds(row, alcove)
	var bench_box := local_bounds(bench, alcove)
	var aisle := bench_box.position.z-row_box.end.z
	check(aisle > 1.5, "Bench/shelf aisle exceeds 1.5 m")
	check(bench.scale.is_equal_approx(Vector3.ONE), "Unit bench scale")
	var probes := 0
	var support_error := 0.0
	# Probe both actual imported foot pads away from bevel edges.
	for side in ["left","right"]:
		var pad := part_bounds(bench,"floor_pad_"+side,bench)
		for fx in [.2,.5,.8]:
			for fz in [.2,.5,.8]:
				var local_point := Vector3(lerpf(pad.position.x,pad.end.x,fx),pad.position.y,lerpf(pad.position.z,pad.end.z,fz))
				var point := room.to_local(bench.to_global(local_point))
				support_error = maxf(support_error,absf(point.y))
				check(floor_supported(point), "Actual floor below both bench pads")
				probes += 1
	# Both handed cap bases and each bay have surface support too.
	var supports: Array[Node3D] = [row.get_node("CapLeft"),row.get_node("CapRight")]
	for bay in row.get_node("Bays").get_children():
		supports.append(bay.get_node("Shelf"))
	for object in supports:
		var box := local_bounds(object,object)
		for fx in [.2,.8]:
			for fz in [.2,.8]:
				var point := room.to_local(object.to_global(Vector3(lerpf(box.position.x,box.end.x,fx),box.position.y,lerpf(box.position.z,box.end.z,fz))))
				check(floor_supported(point), "Actual floor below cap and bay bases")
				probes += 1
	check(support_error < TOLERANCE, "Bench pads on floor within 0.1 mm")
	# Aisle floor is sampled between the shelf face and bench rear, over bench width.
	for x in [-.7,0.0,.7]:
		for step in range(9):
			var point := room.to_local(alcove.to_global(Vector3(x,0,lerpf(row_box.end.z+.02,bench_box.position.z-.02,step/8.0))))
			check(floor_supported(point), "Continuous floor through bench/shelf aisle: " + str(point))
			probes += 1
	var other_objects: Array[Node] = base.get_node("Perimeter").get_children()+base.get_node("Shelves").get_children()
	var furnished := base.get_parent()
	for index in range(4):
		other_objects.append(furnished.get_node("Station%d" % index))
	var alcove_box := local_bounds(alcove,alcove)
	for other in other_objects:
		check(not alcove_box.intersects(local_bounds(other,alcove)), "Alcove clears existing room objects")
	for index in [0,12]:
		var portal := base.get_node("Perimeter/Bay%d" % index) as Node3D
		check(not local_bounds(alcove,portal).intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))), "Alcove clears portal approach")
	var in_room := local_bounds(alcove,room)
	var nearest := Vector2(clampf(0,in_room.position.x,in_room.end.x),clampf(0,in_room.position.z,in_room.end.z))
	check(nearest.length() > 20, "Alcove outside central 40 m diameter")
	alcove_cases.append({"name":str(alcove.name),"aisle_m":aisle,"floor_probes":probes,
		"max_bench_contact_error_m":support_error,"conservative_clear_radius_m":nearest.length()})

func save_view(camera: Camera3D, label: String, position: Vector3, target: Vector3, orthogonal_size: float = 0) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL if orthogonal_size > 0 else Camera3D.PROJECTION_PERSPECTIVE
	camera.size = orthogonal_size if orthogonal_size > 0 else 5.0
	camera.fov = 60
	camera.global_position = position
	camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(ALCOVE_OUT+"godot_"+label+".png") == OK, "GPU capture")

func verify() -> void:
	root.size = Vector2i(1280,800)
	# Exercise the original default, the populated variant, resizing and save/reload.
	var test_row := MIXED_ROW.instantiate() as Node3D
	root.add_child(test_row)
	for count in [1,2,3,4]:
		test_row.set("bay_count",count)
		inspect_row(test_row,count,true,"populated resize %d" % count)
	test_row.set("bay_scene",null)
	inspect_row(test_row,4,false,"null fallback to original bay")
	test_row.set("bay_scene",MIXED_BAY)
	test_row.set("bay_count",2)
	inspect_row(test_row,2,true,"restore populated bay")
	var saved := PackedScene.new()
	check(saved.pack(test_row) == OK, "Pack populated row")
	check(ResourceSaver.save(saved,ALCOVE_OUT+"saved_row.tscn") == OK, "Save populated row")
	var reloaded := (load(ALCOVE_OUT+"saved_row.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(reloaded)
	inspect_row(reloaded,2,true,"save/reload without duplicates")
	test_row.set("bay_count",1)
	inspect_row(reloaded,2,true,"independent row instances")
	test_row.queue_free()
	reloaded.queue_free()
	var original := EMPTY_ROW.instantiate() as Node3D
	root.add_child(original)
	inspect_row(original,3,false,"unchanged default row")
	original.queue_free()
	await process_frame
	var review := (load(ALCOVE_OUT+"review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	var library := room.get_node("Library") as Node3D
	var base := library.get_node("Furnishings/BaseRoom") as Node3D
	for placement in [Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))]:
		room.transform = placement
		cache_floor(library.get_node("Floor"),room)
		for name in ["AlcoveEast","AlcoveWest"]:
			inspect_alcove(room.get_node(name),room,base)
	room.transform = Transform3D.IDENTITY
	cache_floor(library.get_node("Floor"),room)
	var bench := room.get_node("AlcoveEast/Bench") as Node3D
	var pad := part_bounds(bench,"floor_pad_left",bench)
	var valid_point := room.to_local(bench.to_global(Vector3(pad.get_center().x,pad.position.y,pad.get_center().z)))
	check(floor_supported(valid_point), "Floor support positive control")
	check(not floor_supported(valid_point+Vector3(0,.01,0)), "Floating bench negative control")
	check(not floor_supported(valid_point-Vector3(0,.01,0)), "Buried bench negative control")
	check(not floor_supported(Vector3(33,0,0)), "Missing floor negative control")
	var east := room.get_node("AlcoveEast") as Node3D
	for path in ["Bench","ShelfRow/CapLeft","ShelfRow/CapRight","ShelfRow/Bays/Bay0"]:
		bounds(east.get_node(path),true)
	var camera_min := INF
	var camera_samples := 0
	var boxes: Array[AABB] = []
	for child in room.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		boxes.append(mesh.global_transform*mesh.mesh.get_aabb())
	for radius in [12.0,16.0,19.0]:
		for height in [1.8,4.0,8.0]:
			for degrees in range(0,360,5):
				var angle := deg_to_rad(float(degrees))
				var point := Vector3(radius*sin(angle),height,radius*cos(angle))
				for box in boxes:
					var nearest := Vector3(clampf(point.x,box.position.x,box.end.x),clampf(point.y,box.position.y,box.end.y),clampf(point.z,box.position.z,box.end.z))
					camera_min = minf(camera_min,point.distance_to(nearest)-.3)
				camera_samples += 1
	check(camera_min > 0, "Camera envelope clears complete room")
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await save_view(camera,"overview",Vector3(38,42,45),Vector3.ZERO,70)
	await save_view(camera,"alcove_front",east.to_global(Vector3(2.5,2.5,5)),east.to_global(Vector3(0,1,-.6)))
	await save_view(camera,"floor_contact",east.to_global(Vector3(1,.3,2)),east.to_global(Vector3(0,.05,.6)))
	# Isolated views inspect closed rear/end/underside surfaces; room is hidden only here.
	var isolated := (load("res://assets/reading_bench/reading_alcove.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(isolated)
	room.hide()
	await save_view(camera,"isolated_rear",Vector3(-3,2.7,-6),Vector3(0,1,-.6))
	await save_view(camera,"isolated_end",Vector3(5,2,1),Vector3(0,1,-.6))
	await save_view(camera,"isolated_underside",Vector3(2,-3,4),Vector3(0,.5,-.6))
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"issues":[29,35],"row_cases":row_cases,"alcove_placements":alcove_cases,
		"camera_samples":camera_samples,"camera_envelope_radius_m":.3,"minimum_camera_clearance_m":camera_min,"validated_meshes":meshes,
		"support_negative_controls":["floating 10 mm","buried 10 mm","outside floor"],
		"mcp":"Blender status/scene and Godot editor state unavailable; standalone Godot fallback",
		"limits":"Static imported-mesh fit and sampled camera clearance. No physics, seating interaction, roof fit, performance acceptance or final art approval."}
	FileAccess.open(ALCOVE_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
