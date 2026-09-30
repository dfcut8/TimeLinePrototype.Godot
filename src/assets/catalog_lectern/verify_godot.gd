extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/catalog_lectern/"
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
	root.size = Vector2i(900, 760)
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var lectern := assembly.get_node("Lectern") as Node3D
	var box := bounds(lectern, true)
	var stack := bounds(assembly.get_node("Stack"))
	check(absf(box.size.x-.72)<.00001, "Lectern width")
	check(box.end.y > 1.04 and box.end.y < 1.06, "Sloped top height")
	check(absf(box.position.y)<.00001, "Floor contact")
	check(box.position.z-stack.end.z>1.0, "Stack aisle clearance")
	check(lectern.basis == Basis.IDENTITY, "Unit root transform")
	var screen := lectern.find_children("*blank_screen_insert", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var material := screen.mesh.surface_get_material(0) as StandardMaterial3D
	check(not material.emission_enabled and material.transparency == 0, "Blank screen opaque and unlit")
	var normal := Vector3(0,cos(deg_to_rad(18)),sin(deg_to_rad(18)))
	var marker := lectern.get_node("ScreenCenter") as Marker3D
	var arrays := screen.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var max_plane := -INF
	var min_plane := INF
	for v in vertices:
		var distance := normal.dot(screen.global_transform*v-Vector3(0,.95,0))
		max_plane=maxf(max_plane,distance)
		min_plane=minf(min_plane,distance)
	check(absf(min_plane-.03)<.00001 and absf(max_plane-.038)<.00001, "Screen seated on sloped top")
	check(absf(normal.dot(marker.position-Vector3(0,.95,0))-.038)<.00001, "Screen marker on outer face")
	check((marker.basis*Vector3.UP).distance_to(normal)<.00001, "Screen marker orientation")
	var triangles := 0
	for row in meshes:
		triangles += int(row.triangles)
	check(triangles == 432, "Triangle budget")
	await capture(assembly,"assembly",Vector3(0,1,-.65),3.9)
	assembly.get_node("Stack").hide()
	await capture(assembly,"lectern",Vector3(0,.52,0),1.5)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"bounds":str(box),"triangles":triangles,"stack_aisle_m":box.position.z-stack.end.z,"screen_plane_m":[min_plane,max_plane],"mcp":"Both disconnected; standalone fallback","scope":"Optional static asset; room placement deferred"}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
