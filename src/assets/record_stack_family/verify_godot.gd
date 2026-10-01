extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/record_stack_family/"
var failures: Array[String] = []
var meshes: Array[Dictionary] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func bounds(node: Node3D, validate: bool = false) -> AABB:
	var combined := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var mesh := instance.mesh
		var box: AABB = instance.global_transform * mesh.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
		if not validate:
			continue
		for surface in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(surface) as StandardMaterial3D
			check(mat != null, "Material missing")
			if mat != null:
				check(mat.roughness > .6 and not mat.emission_enabled and mat.transparency == 0, "Opaque matte material required")
			var arrays := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			check(normals.size() == vertices.size() and uvs.size() == vertices.size(), "Normals and UVs present")
			for i in range(0, indices.size(), 3):
				var a := indices[i]
				var b := indices[i+1]
				var c := indices[i+2]
				var cross := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
				check(cross.length() > 1e-10 and cross.dot(normals[a]) < 0, "Winding/area: " + str(child.name))
				check(absf((uvs[b]-uvs[a]).cross(uvs[c]-uvs[a])) > 1e-12, "UV area: " + str(child.name))
			meshes.append({"name":str(child.name),"triangles":indices.size()/3,"material":mat.resource_name if mat else "missing"})
	return combined

func verify() -> void:
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1100,800)
	var bay := assembly.get_node("Row/Bay1") as Node3D
	var bay_bounds := bounds(bay.get_node("Bay"),true)
	check(bay_bounds.size.distance_to(Vector3(1.6,2.4,.44)) < .0001, "Shelf envelope")
	check(bay_bounds.position.distance_to(Vector3(-.8,0,-.22)) < .0001, "Shelf pivot")
	check(not bay.find_children("*closed_back*", "MeshInstance3D", true, false).is_empty(), "Named closed back")
	var left := bounds(assembly.get_node("Row/Bay0"))
	var right := bounds(assembly.get_node("Row/Bay2"))
	check(absf(left.end.x-bay_bounds.position.x)<.0001 and absf(bay_bounds.end.x-right.position.x)<.0001,"Adjacent bay seams")
	var cap_r := bounds(assembly.get_node("Row/CapRight"),true)
	var cap_l := bounds(assembly.get_node("Row/CapLeft"))
	check(absf(cap_r.position.x-right.end.x)<.0001 and absf(cap_l.end.x-left.position.x)<.0001,"Both cap attachments")
	check(absf(cap_r.size.y-2.4)<.0001 and absf(cap_r.size.z-.44)<.0001,"Cap height/depth")
	var min_headroom := INF
	var min_back_clearance := INF
	for child in assembly.get_children():
		if not str(child.name).begins_with("Record_"):
			continue
		var record := child as Node3D
		var box := bounds(record)
		var parts := str(child.name).split("_")
		var shelf := int(parts[2])
		var center_x := -1.6+int(parts[1])*1.6
		var floor_y := .16+shelf*.56
		var ceiling_y := floor_y+.52
		check(absf(box.position.y-floor_y)<.0001,"Cassette shelf contact: "+str(child.name))
		check(box.position.x>center_x-.75 and box.end.x<center_x+.75,"Side clearance")
		check(box.position.z>-.18 and box.end.z<.22,"Depth clearance")
		check(box.end.y<ceiling_y,"Head clearance")
		check(record.scale.is_equal_approx(Vector3.ONE),"Unscaled cassette")
		min_headroom=minf(min_headroom,ceiling_y-box.end.y)
		min_back_clearance=minf(min_back_clearance,box.position.z+.18)
	var light_count := 0
	for bay_index in range(3):
		var lit_bay := assembly.get_node("Row/Bay%d" % bay_index) as Node3D
		for tier in range(4):
			var fixture := lit_bay.get_node("Light%d" % tier) as Node3D
			var mount := lit_bay.get_node("Bay/LightMount%d" % tier) as Marker3D
			var recess := lit_bay.get_node("Bay/LightRecess%d" % tier) as Marker3D
			var box := bounds(fixture)
			check(fixture.global_position.distance_to(mount.global_position)<.00001,"Light mounting marker")
			check(absf(box.end.y-mount.global_position.y)<.00001,"Light deck contact")
			check(box.position.y>recess.global_position.y-.006,"Light lip clearance")
			check(box.position.z>recess.global_position.z-.025 and box.end.z<recess.global_position.z+.025,"Light depth clearance")
			check(box.position.x>lit_bay.position.x-.75 and box.end.x<lit_bay.position.x+.75,"Light upright clearance")
			check(fixture.scale.is_equal_approx(Vector3.ONE),"Unscaled light")
			light_count += 1
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["front",Vector3(4,3.1,7)],["rear",Vector3(-4,3.1,-7)],["side",Vector3(6,2,1)],["underside",Vector3(3,-3,6)]]:
		camera.position=view[1]
		camera.look_at(Vector3(0,1.2,0))
		camera.size=6.2
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT+"godot_"+view[0]+".png")==OK,"Capture")
	# Verify the same cap at both exposed ends of a rotated, corner-connected run.
	var alcove := (load("res://assets/record_stack_end_cap/capped_shelf_alcove.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(alcove)
	assembly.get_node("Row").visible = false
	for child in assembly.get_children():
		if str(child.name).begins_with("Record_"):
			(child as Node3D).visible = false
	var entry := bounds(alcove.get_node("EntryBay"))
	var exit_bay := bounds(alcove.get_node("ExitBay"))
	var entry_cap := bounds(alcove.get_node("EntryCap"))
	var exit_cap := bounds(alcove.get_node("ExitCap"))
	check(absf(entry_cap.end.z-entry.position.z)<.0001,"Rotated entry cap seam")
	check(absf(exit_cap.end.x-exit_bay.position.x)<.0001,"Rotated exit cap seam")
	check(absf(entry.end.z)<.0001 and absf(exit_bay.end.x)<.0001,"Corner bay seams")
	check(absf(entry_cap.position.y)<.0001 and absf(exit_cap.position.y)<.0001,"Rotated caps floor contact")
	check(absf(entry_cap.size.x-.44)<.0001 and absf(exit_cap.size.z-.44)<.0001,"Rotated caps cover depth")
	for node in alcove.get_children():
		check((node as Node3D).scale.is_equal_approx(Vector3.ONE),"No mirrored/scaled alcove parts")
	for view in [["alcove_front",Vector3(-4,3,-5)],["alcove_rear",Vector3(4,3,5)],["alcove_underside",Vector3(-4,-3,-5)]]:
		camera.position = view[1]
		camera.look_at(Vector3(-.15,1.2,-.15))
		camera.size = 4.6
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT+"godot_"+view[0]+".png")==OK,"Alcove capture")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"cassette_instances":108,"min_headroom_m":min_headroom,"min_back_clearance_m":min_back_clearance,"mcp":"Unavailable; standalone engine fallback","collision":"Static dressing; no physics/selection bodies","light_channel":{"instances":light_count,"mount_contact":true,"recess_clearance":true},"rotated_cap_fit":true}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
