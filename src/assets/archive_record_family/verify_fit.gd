extends "res://assets/archive_record_family/verify_godot.gd"
## Measure support geometry from imported meshes, not assumed shelf dimensions.

func mesh_box(node: Node3D, part: String) -> AABB:
	var matches := node.find_children("*" + part, "MeshInstance3D", true, false)
	check(matches.size() == 1, "Unique mesh: " + part)
	if matches.size() != 1:
		return AABB()
	var mesh := matches[0] as MeshInstance3D
	return mesh.global_transform * mesh.mesh.get_aabb()

func capture_fit(assembly: Node3D, target: Vector3, span: float, prefix: String) -> void:
	var rig := (load("res://assets/timeline_rail_housing/review_rig.tscn") as PackedScene).instantiate() as Node3D
	assembly.add_child(rig)
	var camera := rig.get_node("Camera3D") as Camera3D
	for view in [["front", Vector3(.4,.2,1)], ["rear", Vector3(-.4,.2,-1)], ["end", Vector3(1,.1,.2)], ["underside", Vector3(.4,-.65,1)]]:
		camera.position = target + view[1] * span
		camera.look_at(target)
		camera.size = span
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(prefix + view[0] + ".png") == OK, "Fit capture")

func verify() -> void:
	root.size = Vector2i(1000, 900)
	var results: Array[Dictionary] = []
	for size in ["small", "large"]:
		var base: String = "res://assets/archive_record_" + size + "/"
		var assembly := (load(base + "shelf_assembly.tscn") as PackedScene).instantiate() as Node3D
		root.add_child(assembly)
		current_scene = assembly
		var shelf := assembly.get_node("Shelf") as Node3D
		var left := mesh_box(shelf, "upright_left")
		var right := mesh_box(shelf, "upright_right")
		var back := mesh_box(shelf, "closed_back")
		var headroom := INF
		var rear := INF
		var front := INF
		var side := INF
		var gap := INF
		var contact_error := 0.0
		var light_clearance := INF
		var light_boxes: Array[AABB] = []
		for tier in range(4):
			var fixture := shelf.get_node("Light%d" % tier) as Node3D
			var mount := shelf.get_node("Bay/LightMount%d" % tier) as Marker3D
			check(fixture.global_position.distance_to(mount.global_position) < .00002, "Fixture at mounting interface")
			check(fixture.transform.basis.is_equal_approx(Basis.IDENTITY), "Unscaled fixture")
			var fixture_box := AABB()
			var first := true
			for child in fixture.find_children("*", "MeshInstance3D", true, false):
				var mesh := child as MeshInstance3D
				var part_box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
				fixture_box = part_box if first else fixture_box.merge(part_box)
				first = false
			check(not first, "Fixture has imported geometry")
			check(absf(fixture_box.end.y-mount.global_position.y) < .00002, "Fixture deck contact")
			light_boxes.append(fixture_box)
		var boxes: Array[AABB] = []
		var count := 0
		for child in assembly.get_children():
			if not str(child.name).begins_with("Record_"):
				continue
			var record := child as Node3D
			var level := int(str(record.name).split("_")[1])
			var deck := mesh_box(shelf, "shelf_%d_deck" % level)
			var ceiling := mesh_box(shelf, "shelf_%d_rear_web" % (level+1))
			var box := inspect_meshes(record, 1728)
			for fixture_box in light_boxes:
				check(not box.intersects(fixture_box), "Cassette clears every light fixture")
			# Conservative vertical separation, including cassettes behind the fixture.
			light_clearance = minf(light_clearance, light_boxes[level].position.y-box.end.y)
			check(record.transform.basis.is_equal_approx(Basis.IDENTITY), "Identity record orientation/scale")
			contact_error = maxf(contact_error, absf(box.position.y-deck.end.y))
			headroom = minf(headroom, ceiling.position.y-box.end.y)
			rear = minf(rear, box.position.z-back.end.z)
			front = minf(front, deck.end.z-box.end.z)
			side = minf(side, minf(box.position.x-left.end.x, right.position.x-box.end.x))
			for other in boxes:
				check(not box.intersects(other), "Records do not intersect")
				if absf(box.position.y-other.position.y) < .001:
					gap = minf(gap, box.position.x-other.end.x)
			boxes.append(box)
			count += 1
		check(count == (68 if size == "small" else 44), "Expected populated shelves")
		check(contact_error < .00002, "Measured shelf contact")
		check(minf(minf(headroom,rear),minf(front,side)) > .001, "Clear of shelf structure")
		check(gap > .018, "Neighbor spacing")
		check(light_clearance > .04, "At least 40 mm below fixture envelope")
		results.append({"size":size,"instances":count,"contact_error_m":contact_error,"headroom_m":headroom,"rear_clearance_m":rear,"front_clearance_m":front,"side_clearance_m":side,"neighbor_gap_m":gap,"light_instances":light_boxes.size(),"light_vertical_clearance_m":light_clearance})
		await capture_fit(assembly, Vector3(0,1.2,0), 2.9, base+"godot_shelf_")
		assembly.free()
	var display := (load("res://assets/archive_record_large/display_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(display)
	current_scene = display
	var top := mesh_box(display.get_node("Plinth"), "display_top")
	var record_box := inspect_meshes(display.get_node("Record"), 1728)
	var contact := absf(record_box.position.y-top.end.y)
	var margin_x := minf(record_box.position.x-top.position.x, top.end.x-record_box.end.x)
	var margin_z := minf(record_box.position.z-top.position.z, top.end.z-record_box.end.z)
	check(contact < .00002 and margin_x > .008 and margin_z > .008, "Large cassette contacts flat plinth inside bevel")
	await capture_fit(display, Vector3(0,.54,0), 1.4, "res://assets/archive_record_large/godot_display_")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"shelves":results,"display":{"contact_error_m":contact,"x_margin_m":margin_x,"z_margin_m":margin_z},"mcp":"Both disconnected; standalone Godot fallback","scope":"Actual imported mesh bounds, support contact, neighbor spacing, matte materials, UVs, normals and triangle winding. Decorative assets; no physics. Full-room camera and performance acceptance remain pending."}
	for path in [OUT,"res://assets/archive_record_small/","res://assets/archive_record_large/"]:
		var file := FileAccess.open(path+"godot_fit_validation.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
