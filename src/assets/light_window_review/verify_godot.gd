extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/light_window_review/"
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
				check(mat.roughness > .6 and mat.transparency == 0, "Opaque matte material required")
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

func capture(assembly: Node3D, label: String, target: Vector3, span: float) -> void:
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["front",Vector3(.45,.25,1)],["rear",Vector3(-.45,.25,-1)],["end",Vector3(1,.05,.15)],["underside",Vector3(.4,-.65,1)]]:
		camera.position = target + view[1] * span
		camera.look_at(target)
		camera.size = span
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT+"godot_"+label+"_"+view[0]+".png")==OK,"Capture")

func verify() -> void:
	root.size = Vector2i(1100,800)
	var shelf := (load(OUT+"review_shelf.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(shelf)
	current_scene = shelf
	var min_headroom := INF
	for i in range(4):
		var light := shelf.get_node("Light%d" % i) as Node3D
		var box := bounds(light,i==0)
		check(box.size.distance_to(Vector3(1.46,.01,.044)) < .00001,"Light envelope")
		check(absf(box.end.y-(.72+i*.56-.028)) < .00001,"Mount contacts shelf deck")
		check(box.position.x > -.75 and box.end.x < .75,"Light span clears uprights")
		check(box.position.z > .15 and box.end.z < .20,"Light fits 50mm recess")
		check(box.position.y > .72+i*.56-.04,"Light recessed above lip")
		var record := bounds(shelf.get_node("Record%d" % i))
		check(record.end.y < box.position.y,"Cassette clears light")
		min_headroom = minf(min_headroom,box.position.y-record.end.y)
		var lenses := light.find_children("*recessed_diffuser*","MeshInstance3D",true,false)
		check(lenses.size()==1,"Separate diffuser")
		if lenses.size()==1:
			var mat := (lenses[0] as MeshInstance3D).mesh.surface_get_material(0) as StandardMaterial3D
			check(mat.emission_enabled and mat.emission_energy_multiplier <= 1.0,"Subdued emission region")
	await capture(shelf,"shelf",Vector3(0,1.2,0),3.0)
	# Close underside view exposes the finished fittings and recessed diffuser.
	var cam := shelf.get_node("ReviewRig/Camera3D") as Camera3D
	cam.position=Vector3(.4,.20,1.8)
	cam.look_at(Vector3(0,.688,.175))
	cam.size=1.65
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"godot_light_closeup.png")
	shelf.queue_free()
	await process_frame
	var window := (load(OUT+"review_window.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(window)
	current_scene=window
	var frame := bounds(window.get_node("Frame"),true)
	check(frame.size.distance_to(Vector3(5.46,4.75,.246))<.00001,"Frame envelope")
	check(absf(frame.position.y)<.00001,"Floor contact")
	var left := bounds(window.get_node("LeftPier"))
	var right := bounds(window.get_node("RightPier"))
	var clearance := minf(frame.position.x-left.end.x,right.position.x-frame.end.x)
	check(clearance>.008,"Pier footprint separation")
	check(absf(frame.end.y-left.end.y)<.00001,"Common tier header")
	# Verify actual triangle rays, including open aperture and opaque reveals.
	var frame_node := window.get_node("Frame") as Node3D
	for point in [Vector3(0,2.375,0),Vector3(-2.56,2.375,0),Vector3(2.56,2.375,0),Vector3(0,.17,0),Vector3(0,4.58,0)]:
		check(not ray_hits(frame_node,point),"Empty window opening")
	for point in [Vector3(-2.65,2.375,0),Vector3(2.65,2.375,0),Vector3(0,.08,0),Vector3(0,4.67,0)]:
		check(ray_hits(frame_node,point),"Closed frame front/back")
	await capture(window,"window",Vector3(0,2.375,0),8.5)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"min_cassette_headroom_m":min_headroom,"min_pier_aabb_gap_m":clearance,"mcp":"Both unavailable; standalone Blender and Godot fallback","collision":"Static model dressing; no physics bodies or animation","room_scale":"Full room camera/readability review remains pending"}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func ray_hits(node: Node3D, point: Vector3) -> bool:
	for child in node.find_children("*","MeshInstance3D",true,false):
		var instance := child as MeshInstance3D
		var faces := instance.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit: Variant = Geometry3D.segment_intersects_triangle(point+Vector3(0,0,1),point-Vector3(0,0,1),instance.global_transform*faces[i],instance.global_transform*faces[i+1],instance.global_transform*faces[i+2])
			if hit != null:
				return true
	return false
