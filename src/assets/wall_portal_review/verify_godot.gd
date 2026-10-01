extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/wall_portal_review/"
var failures: Array[String] = []
var meshes: Array[Dictionary] = []
var mixed_fit: Dictionary = {}

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
	await verify_mixed()
	report["mixed_bay_fit"] = mixed_fit
	report["passed"] = failures.is_empty()
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func verify_mixed() -> void:
	var assembly := (load(OUT + "review_mixed.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var arc := assembly.get_node("MixedBayArc") as Node3D
	check(arc.get_child_count() == 7, "Three bays must share exactly four piers")
	var interface_gaps: Array[float] = []
	for index in range(3):
		var bay := arc.get_node(["Wall", "Portal", "Window"][index]) as Node3D
		var bay_bounds := bounds(bay)
		check(absf(bay_bounds.position.y) < .00001, "Mixed bay floor: " + str(bay.name))
		check(absf(bay_bounds.end.y - 4.75) < .00001, "Mixed bay header: " + str(bay.name))
		check(bay.scale.is_equal_approx(Vector3.ONE), "Unscaled bay: " + str(bay.name))
		# Compute bounds in each bay's coordinate frame, not world AABBs which
		# overlap legitimately on a curved grid.
		for side in range(2):
			var pier := arc.get_node("Pier%d" % (index + side)) as Node3D
			var local_box := bounds_in(pier, bay.global_transform.affine_inverse())
			var gap := -2.73 - local_box.end.x if side == 0 else local_box.position.x - 2.73
			interface_gaps.append(gap)
			check(gap > .008 and gap < .010, "Mixed bay/pier clearance: " + str(bay.name))
		var local_bounds := bounds_in(bay, bay.global_transform.affine_inverse())
		check(absf(local_bounds.size.x - 5.46) < .00001, "Common bay width")
	# Test transformed assets too: a displaced/rotated repeat must preserve the
	# solid wall and clear portal, including probes just inside both jambs.
	var probes := 0
	for placement in [Transform3D.IDENTITY, Transform3D(Basis(Vector3.UP, .71), Vector3(8, 2, -6))]:
		arc.transform = placement
		for kind in ["Wall", "Portal"]:
			var bay := arc.get_node(kind) as Node3D
			for x in [-1.501, -1.499, 0.0, 1.499, 1.501]:
				for y in [.001, 1.7, 3.399, 3.401]:
					var start := bay.to_global(Vector3(x,y,1))
					var end := bay.to_global(Vector3(x,y,-1))
					var expected: bool = kind == "Wall" or absf(x) > 1.5 or y > 3.4
					check(segment_hits(arc,start,end) == expected, "Mixed transformed wall/portal probe")
					probes += 1
	arc.transform = Transform3D.IDENTITY
	mixed_fit = {"bays":3,"shared_piers":4,"pier_radius_m":24.8,"pitch_degrees":15,"interface_gaps_m":interface_gaps,"transformed_surface_probes":probes}
	await capture(assembly,"mixed",Vector3(0,2.375,.4),22.0)
	assembly.queue_free()
	await process_frame

func bounds_in(node: Node3D, frame: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var box: AABB = (frame * instance.global_transform) * instance.mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func ray_hits(node: Node3D, point: Vector3) -> bool:
	return segment_hits(node, point+Vector3(0,0,1), point-Vector3(0,0,1))

func segment_hits(node: Node3D, start: Vector3, end: Vector3) -> bool:
	for child in node.find_children("*","MeshInstance3D",true,false):
		var instance := child as MeshInstance3D
		var faces := instance.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var hit: Variant = Geometry3D.segment_intersects_triangle(start,end,instance.global_transform*faces[i],instance.global_transform*faces[i+1],instance.global_transform*faces[i+2])
			if hit != null:
				return true
	return false
