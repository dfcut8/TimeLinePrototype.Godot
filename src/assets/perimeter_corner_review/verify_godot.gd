extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/perimeter_corner_review/"
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


func world_vertices(node: Node3D) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		for surface in range(instance.mesh.get_surface_count()):
			var arrays := instance.mesh.surface_get_arrays(surface)
			for v in arrays[Mesh.ARRAY_VERTEX]:
				result.append(instance.global_transform * v)
	return result

func capture(assembly: Node3D, label: String, views: Array, target: Vector3, size: float) -> void:
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	camera.size = size
	for view in views:
		camera.position = view[1]
		camera.look_at(target)
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT+"godot_"+label+"_"+view[0]+".png")==OK,"Capture")

func verify() -> void:
	root.size = Vector2i(900,800)
	var floor_scene := (load(OUT+"review_floor.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(floor_scene)
	current_scene = floor_scene
	var wedge := floor_scene.get_node("Wedge0") as Node3D
	var envelope := bounds(wedge,true)
	check(envelope.size.distance_to(Vector3(32,.25,32)) < .0001,"Floor radius/thickness")
	check(absf(envelope.end.y)<.0001 and absf(envelope.position.y+.25)<.0001,"Floor deck datum")
	var seam_error := 0.0
	for i in range(4):
		var a := world_vertices(floor_scene.get_node("Wedge"+str(i)))
		var b := world_vertices(floor_scene.get_node("Wedge"+str((i+1)%4)))
		# Rotation maps the next quarter's +Z endpoint onto this quarter's +X endpoint.
		for r in [20.0,32.0]:
			for y in [-.25,0.0]:
				var expected := (floor_scene.get_node("Wedge"+str(i)) as Node3D).global_transform * Vector3(r,y,0)
				var da := INF
				var db := INF
				for v in a: da=minf(da,v.distance_to(expected))
				for v in b: db=minf(db,v.distance_to(expected))
				seam_error=maxf(seam_error,maxf(da,db))
	check(seam_error<.0001,"Quarter seams close circumference")
	for x in range(10):
		for z in range(10):
			var tile := bounds(floor_scene.get_node("Tile_%d_%d"%[x,z]),x==0 and z==0)
			check(absf(tile.end.y)<.0001 and absf(tile.position.y+.25)<.0001,"Flush tile thickness")
			check(tile.size.distance_to(Vector3(4,.25,4))<.0001,"Tile pitch")
	await capture(floor_scene,"floor",[["front",Vector3(60,65,60)],["rear",Vector3(-60,45,-60)],["underside",Vector3(50,-65,50)],["tile_join",Vector3(25,8,26)]],Vector3.ZERO,72)
	# Detail the actual square tile/curved infill interface.
	await capture(floor_scene,"floor",[["join_detail",Vector3(25,7,26)]],Vector3(20,0,20),13)
	floor_scene.queue_free()
	await process_frame
	var assembly := (load(OUT+"review_corner.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var corner := assembly.get_node("Corner") as Node3D
	var box := bounds(corner,true)
	check(box.size.distance_to(Vector3(1.24,2.4,1.24))<.0001,"Corner envelope")
	check(box.position.length()<.0001,"Corner floor pivot")
	var entry := bounds(assembly.get_node("EntryBay"))
	var exit_bay := bounds(assembly.get_node("ExitBay"))
	check(absf(entry.end.z)<.0001 and absf(exit_bay.end.x)<.0001,"Bay join planes")
	check(absf(entry.position.x-.8)<.0001 and absf(entry.end.x-1.24)<.0001,"Entry depth alignment")
	check(absf(exit_bay.position.z-.8)<.0001 and absf(exit_bay.end.z-1.24)<.0001,"Exit depth alignment")
	var headroom := INF
	var rear_clearance := INF
	var front_clearance := INF
	var record_boxes: Array[AABB] = []
	for child in assembly.get_children():
		if not str(child.name).begins_with("Record_"): continue
		var shelf := int(str(child.name).split("_")[1])
		var record_box := bounds(child)
		check(absf(record_box.position.y-(.16+shelf*.56))<.0001,"Record floor contact")
		headroom=minf(headroom,.16+shelf*.56+.532-record_box.end.y)
		for v in world_vertices(child):
			var radius := Vector2(v.x,v.z).length()
			rear_clearance=minf(rear_clearance,1.20-radius)
			front_clearance=minf(front_clearance,radius-.8)
			check(v.x>0 and v.z>0,"Cassette remains inside corner")
		for previous in record_boxes:
			check(not previous.intersects(record_box),"Cassette envelopes do not overlap")
		record_boxes.append(record_box)
	check(headroom>0 and rear_clearance>0 and front_clearance>0,"Cassette annular shelf clearances")
	# Match shelf top and recessed underside channel endpoint geometry to straight bays.
	var cv := world_vertices(corner)
	var channel_error := 0.0
	for top in [.16,.72,1.28,1.84,2.40]:
		for expected in [Vector3(.8,top,0),Vector3(.82,top-.04,0),Vector3(.87,top-.028,0),Vector3(0,top,.8),Vector3(0,top-.04,.82),Vector3(0,top-.028,.87)]:
			var nearest := INF
			for v in cv: nearest=minf(nearest,v.distance_to(expected))
			channel_error=maxf(channel_error,nearest)
	check(channel_error<.0001,"Shelf and light-channel endpoint profile")
	await capture(assembly,"corner",[["front",Vector3(-4,3,-5)],["rear",Vector3(5,3,5)],["side",Vector3(5,2,-2)],["underside",Vector3(-3,-3,-4)]],Vector3(0,1.2,0),4.7)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"floor_seam_error_m":seam_error,"channel_endpoint_error_m":channel_error,"cassette_headroom_m":headroom,"cassette_back_clearance_m":rear_clearance,"cassette_front_clearance_m":front_clearance,"floor_instances":4,"tile_instances":100,"cassette_instances":12,"mcp":"Unavailable; standalone GPU engine fallback","collision":"Model review only; no physics bodies","remaining":"Live MCP validation, complete room/orbit placement and curved light fixture are not tested"}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
