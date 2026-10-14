extends "res://assets/grounded_room_review/verify_grounded.gd"
## Standalone engine verification of configuration, imported surfaces and fit.
const REVIEW_OUT := "res://assets/modular_library_review/"
const ARC: PackedScene = preload("res://assets/wall_infill_bay/configurable_bay_arc.tscn")
const RING: PackedScene = preload("res://assets/wall_infill_bay/library_perimeter.tscn")
const PORTAL_ARC: PackedScene = preload("res://assets/passage_portal_bay_frame/portal_bay_arc.tscn")
const POPULATED: PackedScene = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.tscn")
const ROW: PackedScene = preload("res://assets/record_stack_end_cap/configurable_populated_shelf_row.tscn")
const EPS: float = .0001
var arc_cases: Array[Dictionary] = []
var shelf_cases: Array[Dictionary] = []
var row_cases: Array[Dictionary] = []
var sector_cases: Array[Dictionary] = []

func inspect_arc(arc: Node3D, layout: PackedInt32Array, label: String) -> void:
	var count := layout.size()
	var piers := count if count == 24 else count + 1
	var min_gap := INF
	var max_gap := 0.0
	var probes := 0
	check(arc.get_node("Piers").find_children("Pier*", "Node3D", false, false).size() == piers, label + ": shared pier count")
	check(arc.get_node("Bays").find_children("Bay*", "Node3D", false, false).size() == count, label + ": bay count")
	for index in range(count):
		var bay := arc.get_node("Bays/Bay%d" % index) as Node3D
		var box := local_bounds(bay, bay)
		check(bay.scene_file_path == ["res://assets/wall_infill_bay/wall_infill_bay.tscn",
			"res://assets/passage_portal_bay_frame/passage_portal_bay_frame.tscn",
			"res://assets/window_bay_frame/window_bay_frame.tscn"][layout[index]], label + ": selected bay scene")
		check(bay.owner == null and bay.scale.is_equal_approx(Vector3.ONE), label + ": generated unscaled bay")
		check(absf(box.position.y) < EPS and absf(box.end.y - 4.75) < EPS, label + ": floor/header")
		for side in range(2):
			var pier := arc.get_node("Piers/Pier%d" % ((index + side) % piers)) as Node3D
			check(pier.owner == null and pier.scale.is_equal_approx(Vector3.ONE), label + ": unscaled shared pier")
			var pier_box := local_bounds(pier, bay)
			var gap := box.position.x - pier_box.end.x if side == 0 else pier_box.position.x - box.end.x
			min_gap = minf(min_gap, gap)
			max_gap = maxf(max_gap, gap)
			check(gap > .008 and gap < .010, label + ": both actual mesh interfaces, including ring closure")
		for x in [-1.501, -1.499, 0.0, 1.499, 1.501]:
			for y in [.001, 1.7, 3.399, 3.401]:
				var expected: bool = layout[index] == 0 or (layout[index] == 1 and (absf(x) > 1.5 or y > 3.4)) or (layout[index] == 2 and y < .16)
				check(segment_hits(bay, bay.to_global(Vector3(x,y,1)), bay.to_global(Vector3(x,y,-1))) == expected, label + ": wall/portal/window surface probe")
				probes += 1
		if layout[index] == 1:
			check(bay.get_node("InsideApproach").position == Vector3(0,0,5) and bay.get_node("OutsideApproach").position == Vector3(0,0,-1), label + ": portal approach interfaces")
	arc_cases.append({"case":label, "bays":count, "piers":piers, "min_join_m":min_gap,
		"max_join_m":max_gap, "surface_probes":probes})

func inspect_shelf(bay: Node3D, pattern: PackedInt32Array, slots: int, label: String) -> void:
	var shelf := bay.get_node("Shelf") as Node3D
	var records := bay.get_node("Records")
	check(records.find_children("Record_*", "Node3D", false, false).size() == slots * 4, label + ": cassette count")
	check(local_bounds(shelf,bay).size.distance_to(Vector3(1.6,2.4,.44)) < EPS, label + ": preserved shelf interface")
	var max_contact := 0.0
	var min_clearance := INF
	var min_light := INF
	var min_neighbor := INF
	var left := part_bounds(shelf,"upright_left",bay)
	var right := part_bounds(shelf,"upright_right",bay)
	var back := part_bounds(shelf,"closed_back",bay)
	for tier in range(4):
		var deck := part_bounds(shelf,"shelf_%d_deck" % tier,bay)
		var ceiling := part_bounds(shelf,"shelf_%d_rear_web" % (tier+1),bay)
		var light := local_bounds(shelf.get_node("Light%d" % tier),bay)
		var previous := AABB()
		for slot in range(slots):
			var record := records.get_node("Record_%d_%d" % [tier,slot]) as Node3D
			var size: int = pattern[slot % pattern.size()]
			check(record.scene_file_path.ends_with("archive_record_%s.tscn" % ["small","medium","large"][size]), label + ": requested independent cassette")
			check(record.owner == null and record.scale.is_equal_approx(Vector3.ONE), label + ": generated unscaled record")
			var box := local_bounds(record,bay)
			max_contact = maxf(max_contact,absf(box.position.y-deck.end.y))
			min_clearance = minf(min_clearance,minf(minf(box.position.x-left.end.x,right.position.x-box.end.x),minf(box.position.z-back.end.z,deck.end.z-box.end.z)))
			min_clearance = minf(min_clearance,ceiling.position.y-box.end.y)
			min_light = minf(min_light,light.position.y-box.end.y)
			if slot > 0:
				min_neighbor = minf(min_neighbor,box.position.x-previous.end.x)
			previous = box
			# Probe the real supporting deck, not only matching bounding boxes.
			check(record_supported(record,shelf,bay),label + ": actual shelf support")
	check(max_contact < EPS, label + ": cassette support datum")
	check(slots == 0 or (min_clearance > .02 and min_light > .04), label + ": structure and light clearances")
	check(slots < 2 or min_neighbor > .04, label + ": neighboring cassette gap")
	shelf_cases.append({"case":label,"records":slots*4,"pattern":Array(pattern),"max_contact_error_m":max_contact,
		"min_structure_clearance_m":min_clearance if slots > 0 else null,
		"min_light_clearance_m":min_light if slots > 0 else null,
		"min_neighbor_gap_m":min_neighbor if slots > 1 else null})

func record_supported(record: Node3D, shelf: Node3D, bay: Node3D) -> bool:
	var box := local_bounds(record,bay)
	var point := bay.to_global(Vector3(box.get_center().x,box.position.y,box.get_center().z))
	return segment_hits(shelf,point+bay.global_basis.y*EPS,point-bay.global_basis.y*EPS)

func inspect_row(row: Node3D, count: int, pattern: PackedInt32Array, slots: int, label: String) -> void:
	check(row.get_node("Bays").find_children("Bay*","Node3D",false,false).size() == count, label + ": row length")
	var first := AABB()
	var previous := AABB()
	var seam_error := 0.0
	for index in range(count):
		var bay := row.get_node("Bays/Bay%d" % index) as Node3D
		check(bay.scene_file_path == POPULATED.resource_path, label + ": populated bay scene")
		inspect_shelf(bay,pattern,slots,label + " bay%d" % index)
		var box := local_bounds(bay,row)
		if index == 0:
			first = box
		else:
			seam_error = maxf(seam_error,absf(box.position.x-previous.end.x))
		previous = box
	var left := local_bounds(row.get_node("CapLeft"),row)
	var right := local_bounds(row.get_node("CapRight"),row)
	var cap_error := maxf(absf(left.end.x-first.position.x),absf(right.position.x-previous.end.x))
	for cap_name in ["CapLeft","CapRight"]:
		var cap := row.get_node(cap_name) as Node3D
		var box := local_bounds(cap,row)
		check(cap.scale.is_equal_approx(Vector3.ONE),label + ": cap rotation without reflection")
		check(absf(box.position.y) < EPS and absf(box.end.y-2.4) < EPS and absf(box.position.z+.22) < EPS and absf(box.end.z-.22) < EPS,label + ": full end closure")
	check(seam_error < EPS and cap_error < EPS,label + ": bay and cap seams")
	check(left.position.x < first.position.x and right.end.x > previous.end.x,label + ": outward handed caps")
	check(absf(local_bounds(row,row).size.x-(1.6*count+.164)) < EPS,label + ": full row width")
	check(absf(row.get_node("LeftJoin").position.x-first.position.x) < EPS and absf(row.get_node("RightJoin").position.x-previous.end.x) < EPS,label + ": join markers")
	row_cases.append({"case":label,"bays":count,"records":count*slots*4,"bay_seam_error_m":seam_error,"cap_join_error_m":cap_error})

func add_attachment(container: Node, object: Node) -> Node:
	var attachment := Marker3D.new()
	attachment.name = "UserAttachment"
	container.add_child(attachment)
	attachment.owner = object
	return attachment

func disk_roundtrip(object: Node3D, filename: String) -> Node3D:
	var packed := PackedScene.new()
	check(packed.pack(object) == OK,"Pack " + filename)
	check(ResourceSaver.save(packed,"user://"+filename+".tscn") == OK,"Save " + filename)
	var restored := (load("user://"+filename+".tscn") as PackedScene).instantiate() as Node3D
	root.add_child(restored)
	return restored

func verify_configuration() -> void:
	var arc := ARC.instantiate() as Node3D
	arc.set("bay_layout",PackedInt32Array([1,0,2]))
	arc.set("start_angle_degrees",37.0)
	root.add_child(arc)
	inspect_arc(arc,PackedInt32Array([1,0,2]),"pre-ready arc")
	var attachment := add_attachment(arc.get_node("Bays"),arc)
	for layout in [PackedInt32Array([0]),PackedInt32Array([1]),PackedInt32Array([2]),PackedInt32Array([0,1,2]),PackedInt32Array(),PackedInt32Array([-5,77])]:
		arc.set("bay_layout",layout)
		inspect_arc(arc,arc.get("bay_layout"),"arc edit " + str(Array(layout)))
		check(is_instance_valid(attachment),"Arc rebuild preserves user attachments")
	for count in [23,24,25]:
		var layout := PackedInt32Array()
		for index in range(count):
			layout.append(index%3)
		arc.set("bay_layout",layout)
		inspect_arc(arc,layout.slice(0,24),"ring boundary %d" % count)
	check(arc.get("bay_layout").size() == 24,"Arc count clamp")
	arc.set("bay_layout",PackedInt32Array())
	check(arc.get("bay_layout") == PackedInt32Array([0]),"Empty arc falls back to one wall")
	arc.set("bay_layout",PackedInt32Array([-5,77]))
	check(arc.get("bay_layout") == PackedInt32Array([0,2]),"Invalid bay codes clamp")
	for angle in [-400.0,400.0]:
		arc.set("start_angle_degrees",angle)
		check(absf(arc.get("start_angle_degrees")) == 180.0,"Arc angle clamp")
		inspect_arc(arc,PackedInt32Array([0,2]),"angle clamp")
	arc.transform = Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))
	inspect_arc(arc,PackedInt32Array([0,2]),"transformed arc")
	var restored := disk_roundtrip(arc,"arc")
	inspect_arc(restored,PackedInt32Array([0,2]),"arc disk roundtrip")
	check(restored.has_node("Bays/UserAttachment"),"Arc attachment serialized")
	var detached_layout: PackedInt32Array = restored.get("bay_layout")
	detached_layout[0] = 1
	check(restored.get("bay_layout")[0] == 0,"Arc layout getter returns a copy")
	root.remove_child(restored)
	restored.set("bay_layout",PackedInt32Array([1,0,1]))
	root.add_child(restored)
	inspect_arc(restored,PackedInt32Array([1,0,1]),"arc detached update")
	check(arc.get("bay_layout") == PackedInt32Array([0,2]),"Arc instances independent")
	arc.queue_free()
	restored.queue_free()
	for scene in [RING,PORTAL_ARC]:
		var variant := scene.instantiate() as Node3D
		root.add_child(variant)
		inspect_arc(variant,variant.get("bay_layout"),"saved " + str(variant.name))
		for bay in variant.get_node("Bays").get_children():
			bounds(bay,true)
		bounds(variant.get_node("Piers/Pier0"),true)
		variant.queue_free()
	await process_frame
	var bay := POPULATED.instantiate() as Node3D
	bay.set("cassette_pattern",PackedInt32Array([2,0,1,2]))
	bay.set("records_per_shelf",5)
	root.add_child(bay)
	inspect_shelf(bay,PackedInt32Array([2,0,1,2]),5,"pre-ready shelf")
	add_attachment(bay.get_node("Records"),bay)
	for pattern in [PackedInt32Array([0]),PackedInt32Array([1]),PackedInt32Array([2]),PackedInt32Array([2,1,0]),PackedInt32Array(),PackedInt32Array([-8,99])]:
		bay.set("cassette_pattern",pattern)
		for slots in [0,1,6,9]:
			bay.set("records_per_shelf",slots)
			inspect_shelf(bay,bay.get("cassette_pattern"),slots,"shelf pattern %s slots %d" % [str(Array(pattern)),slots])
		check(bay.has_node("Records/UserAttachment"),"Shelf rebuild preserves attachment")
	bay.set("records_per_shelf",99)
	check(bay.get("records_per_shelf") == 9,"Upper cassette count clamp")
	bay.set("records_per_shelf",-7)
	check(bay.get("records_per_shelf") == 0,"Lower cassette count clamp")
	bay.set("cassette_pattern",PackedInt32Array())
	check(bay.get("cassette_pattern") == PackedInt32Array([0]),"Empty cassette pattern falls back to small")
	bay.set("cassette_pattern",PackedInt32Array([-8,99]))
	check(bay.get("cassette_pattern") == PackedInt32Array([0,2]),"Invalid cassette codes clamp")
	var long_pattern := PackedInt32Array([0,1,2,0,1,2,0,1,2,0])
	bay.set("cassette_pattern",long_pattern)
	check(bay.get("cassette_pattern").size() == 9,"Pattern length clamp")
	long_pattern[0] = 2
	var copied_pattern: PackedInt32Array = bay.get("cassette_pattern")
	copied_pattern[0] = 2
	check(bay.get("cassette_pattern")[0] == 0,"Cassette pattern copied on read and write")
	bay.set("cassette_pattern",PackedInt32Array([0,1,2]))
	bay.set("records_per_shelf",9)
	bay.transform = Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))
	inspect_shelf(bay,PackedInt32Array([0,1,2]),9,"transformed shelf")
	restored = disk_roundtrip(bay,"shelf")
	inspect_shelf(restored,PackedInt32Array([0,1,2]),9,"shelf disk roundtrip")
	check(restored.has_node("Records/UserAttachment"),"Shelf attachment serialized")
	root.remove_child(restored)
	restored.set("records_per_shelf",1)
	root.add_child(restored)
	inspect_shelf(restored,PackedInt32Array([0,1,2]),1,"shelf detached update")
	check(bay.get("records_per_shelf") == 9,"Shelf instances independent")
	bounds(bay.get_node("Shelf"),true)
	for slot in range(3):
		bounds(bay.get_node("Records/Record_0_%d" % slot),true)
	var record := bay.get_node("Records/Record_0_0") as Node3D
	var seated := record.position
	record.position.y += .01
	check(not record_supported(record,bay.get_node("Shelf"),bay),"Floating cassette negative control")
	record.position = seated + Vector3(3,0,0)
	check(not record_supported(record,bay.get_node("Shelf"),bay),"Unsupported cassette negative control")
	record.position = seated
	bay.queue_free()
	restored.queue_free()
	await process_frame
	var row := ROW.instantiate() as Node3D
	row.set("bay_count",1)
	row.set("cassette_pattern",PackedInt32Array([2,1]))
	row.set("records_per_shelf",3)
	root.add_child(row)
	inspect_row(row,1,PackedInt32Array([2,1]),3,"pre-ready row")
	add_attachment(row.get_node("Bays"),row)
	var bay_attachment := add_attachment(row.get_node("Bays/Bay0/Records"),row)
	var bay_id := row.get_node("Bays/Bay0").get_instance_id()
	row.set("cassette_pattern",PackedInt32Array([0,1,2]))
	row.set("records_per_shelf",9)
	check(row.get_node("Bays/Bay0").get_instance_id() == bay_id and is_instance_valid(bay_attachment),"Population edits retain bay instance and user attachment")
	for count in [1,2,3,4]:
		row.set("bay_count",count)
		inspect_row(row,count,PackedInt32Array([0,1,2]),9,"populated row resize %d" % count)
		check(row.has_node("Bays/UserAttachment"),"Row resize preserves persistent attachment")
	row.set("records_per_shelf",0)
	inspect_row(row,4,PackedInt32Array([0,1,2]),0,"empty populated row")
	row.set("bay_count",99)
	check(row.get("bay_count") == 32,"Populated row max bay clamp")
	inspect_row(row,32,PackedInt32Array([0,1,2]),0,"maximum empty row")
	row.set("bay_count",-5)
	check(row.get("bay_count") == 1,"Populated row min bay clamp")
	row.set("cassette_pattern",PackedInt32Array([-1,99]))
	row.set("records_per_shelf",99)
	check(row.get("cassette_pattern") == PackedInt32Array([0,2]) and row.get("records_per_shelf") == 9,"Row population clamps")
	row.set("bay_count",2)
	row.transform = Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))
	inspect_row(row,2,PackedInt32Array([0,2]),9,"transformed populated row")
	restored = disk_roundtrip(row,"row")
	inspect_row(restored,2,PackedInt32Array([0,2]),9,"row disk roundtrip")
	check(restored.has_node("Bays/UserAttachment"),"Row attachment serialized")
	root.remove_child(restored)
	restored.set("bay_count",1)
	restored.set("records_per_shelf",1)
	root.add_child(restored)
	inspect_row(restored,1,PackedInt32Array([0,2]),1,"row detached update")
	check(row.get("bay_count") == 2 and row.get("records_per_shelf") == 9,"Row instances independent")
	bounds(row.get_node("CapLeft"),true)
	bounds(row.get_node("CapRight"),true)
	row.queue_free()
	restored.queue_free()
	await process_frame

func inspect_sector(sector: Node3D, review: Node3D, label: String) -> void:
	var arc := sector.get_node("Architecture") as Node3D
	inspect_arc(arc,PackedInt32Array([0,1,0]),label)
	var portal := arc.get_node("Bays/Bay1") as Node3D
	var objects: Array[Node3D] = [sector.get_node("ShelfLeft"),sector.get_node("ShelfRight")]
	var min_setback := INF
	var floor_probes := 0
	for index in range(2):
		var row := objects[index]
		inspect_row(row,2,PackedInt32Array([0,1,2]) if index == 0 else PackedInt32Array([2,1,0]),9 if index == 0 else 6,label + " " + str(row.name))
		var wall := arc.get_node("Bays/Bay%d" % (index*2)) as Node3D
		var box := local_bounds(row,wall)
		var wall_box := local_bounds(wall,wall)
		min_setback = minf(min_setback,box.position.z-wall_box.end.z)
		check(not local_bounds(row,portal).intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))),label + ": clear portal approach")
		check(not local_bounds(row,sector).intersects(local_bounds(objects[1-index],sector)),label + ": separate rows")
		var supports: Array[Node3D] = [row.get_node("CapLeft"),row.get_node("CapRight")]
		for bay in row.get_node("Bays").get_children():
			supports.append(bay.get_node("Shelf"))
		for object in supports:
			var support_box := local_bounds(object,object)
			for fx in [.2,.8]:
				for fz in [.2,.8]:
					var point := review.to_local(object.to_global(Vector3(lerpf(support_box.position.x,support_box.end.x,fx),support_box.position.y,lerpf(support_box.position.z,support_box.end.z,fz))))
					check(supported(point),label + ": actual floor under shelf/cap bases")
					floor_probes += 1
	for x in [-1.49,-.75,0,.75,1.49]:
		for step in range(25):
			var point := review.to_local(portal.to_global(Vector3(x,0,-1+step*.25)))
			check(supported(point),label + ": continuous floor through portal approach")
			floor_probes += 1
		for y in [.001,1.7,3.399]:
			check(not segment_hits(sector,portal.to_global(Vector3(x,y,-1)),portal.to_global(Vector3(x,y,5))),label + ": unobstructed approach volume")
	check(min_setback > 1.0,label + ": wall setback")
	sector_cases.append({"case":label,"min_wall_setback_m":min_setback,"floor_probes":floor_probes,"records":120})

func save_view(camera: Camera3D, label: String, position: Vector3, target: Vector3, span: float) -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = position
	camera.look_at(target)
	camera.size = span
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(REVIEW_OUT+"godot_"+label+".png") == OK,"GPU capture " + label)

func verify() -> void:
	root.size = Vector2i(1280,800)
	await verify_configuration()
	var review := (load(REVIEW_OUT+"review_sector.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var sector := review.get_node("Sector") as Node3D
	for placement in [Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))]:
		review.transform = placement
		cache_floor(review.get_node("Floor"),review)
		inspect_sector(sector,review,"sector " + str(placement.origin))
	review.transform = Transform3D.IDENTITY
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	await save_view(camera,"sector_front",Vector3(16,12,-9),Vector3(0,1.8,-23),23)
	await save_view(camera,"portal",Vector3(0,2.4,-17),Vector3(0,2.0,-24.6),9)
	var row := sector.get_node("ShelfLeft") as Node3D
	await save_view(camera,"row_front",row.to_global(Vector3(3,2.5,5)),row.to_global(Vector3(0,1.2,0)),4.6)
	sector.get_node("Architecture").visible = false
	sector.get_node("ShelfRight").visible = false
	review.get_node("Floor").visible = false
	await save_view(camera,"row_rear",row.to_global(Vector3(-3,2.5,-5)),row.to_global(Vector3(0,1.2,0)),4.6)
	await save_view(camera,"row_end",row.to_global(Vector3(5,1.8,.6)),row.to_global(Vector3(0,1.2,0)),4.6)
	await save_view(camera,"row_underside",row.to_global(Vector3(2,-3,5)),row.to_global(Vector3(0,1.2,0)),4.6)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"issues":[24,25,28,29],"arc_cases":arc_cases,
		"shelf_cases":shelf_cases,"row_cases":row_cases,"sector_cases":sector_cases,"meshes":meshes,
		"mcp":"Blender status/scene and Godot get_state disconnected; standalone Godot fallback",
		"limits":"Static model assembly; live Inspector/MCP, physics, continuous camera, roof fit, performance and art approval incomplete."}
	FileAccess.open(REVIEW_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Modular library: %d arc, %d shelf, %d row and %d sector checks; %d failures." % [arc_cases.size(),shelf_cases.size(),row_cases.size(),sector_cases.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
