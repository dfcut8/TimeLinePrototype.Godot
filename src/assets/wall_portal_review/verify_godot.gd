extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/wall_portal_review/"
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
	var gaps: Array[float] = []
	for kind in ["wall", "portal"]:
		var assembly := (load(OUT+"review_"+kind+".tscn") as PackedScene).instantiate() as Node3D
		root.add_child(assembly)
		current_scene = assembly
		var frame_node := assembly.get_node("Frame") as Node3D
		var frame := bounds(frame_node,true)
		check(frame.size.distance_to(Vector3(5.46,4.75,.246)) < .00001,"Bay envelope: "+kind)
		check(absf(frame.position.y) < .00001,"Floor contact: "+kind)
		var left := bounds(assembly.get_node("LeftPier"))
		var right := bounds(assembly.get_node("RightPier"))
		var gap := minf(frame.position.x-left.end.x,right.position.x-frame.end.x)
		gaps.append(gap)
		check(gap > .008,"Pier separation: "+kind)
		check(absf(frame.end.y-left.end.y) < .00001,"Tier alignment: "+kind)
		check(frame_node.get_node("Header").position == Vector3(0,4.75,0),"Header marker")
		# Dense through-depth triangle probes include panel seams and the whole opening.
		for x in [-2.729,-2.2,-1.66,-1.575,-1.501,-1.499,-.91,0.0,.91,1.499,1.501,1.575,1.66,2.2,2.729]:
			for y in [.001,.156,.16,1.0,2.375,3.399,3.401,3.55,4.59,4.749]:
				var expected: bool = kind=="wall" or absf(x)>1.5 or y>3.4
				check(ray_hits(frame_node,Vector3(x,y,0))==expected,"Surface/opening probe: "+kind+str(Vector2(x,y)))
		await capture(assembly,kind,Vector3(0,2.375,0),8.5)
		assembly.queue_free()
		await process_frame
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"pier_aabb_gaps_m":gaps,"opening_m":[3.0,3.4],"mcp":"Both unavailable; standalone Blender and Godot fallback","collision":"Static model dressing; no physics bodies or animation","room_scale":"Full room camera/readability review remains pending"}
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
