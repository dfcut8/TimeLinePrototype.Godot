extends SceneTree
## Standalone fallback: inspect the actual imported assets and save GPU captures.
const OUT := "res://assets/furniture_review/"
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
	root.size = Vector2i(1000, 760)
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var bench_node := assembly.get_node("Bench") as Node3D
	var plinth_node := assembly.get_node("Plinth") as Node3D
	var record_node := assembly.get_node("Record") as Node3D
	var stack_node := assembly.get_node("Stack") as Node3D
	var bench := bounds(bench_node, true)
	var plinth := bounds(plinth_node, true)
	var record := bounds(record_node)
	var stack := bounds(stack_node)
	check(bench.size.distance_to(Vector3(1.6,.45,.48)) < .00001,"Bench dimensions")
	check(plinth.size.distance_to(Vector3(.7,.6,.55)) < .00001,"Plinth dimensions")
	check(absf(bench.position.y) < .00001 and absf(plinth.position.y) < .00001,"Floor contact")
	check(absf(record.position.y-plinth.end.y) < .00001,"Cassette top contact")
	check(record.position.x > plinth.position.x+.008 and record.end.x < plinth.end.x-.008,"Cassette clears top bevel in X")
	check(record.position.z > plinth.position.z+.008 and record.end.z < plinth.end.z-.008,"Cassette clears top bevel in Z")
	check(bench.position.z-stack.end.z > 1.0,"Bench-to-stack aisle gap")
	for node in [bench_node, plinth_node]:
		check(node.scale.is_equal_approx(Vector3.ONE),"Unit instance scale")
		for mesh_node in node.find_children("*","MeshInstance3D",true,false):
			check(mesh_node.scale.is_equal_approx(Vector3.ONE),"Unit mesh scale")
	# Each support reaches the underside frame, and both feet contact the floor.
	for side in ["left","right"]:
		var foot := bench_node.find_children("*floor_pad_"+side,"MeshInstance3D",true,false)[0] as MeshInstance3D
		var support := bench_node.find_children("*solid_support_"+side,"MeshInstance3D",true,false)[0] as MeshInstance3D
		var foot_box: AABB = foot.global_transform * foot.mesh.get_aabb()
		var support_box: AABB = support.global_transform * support.mesh.get_aabb()
		check(absf(foot_box.position.y)<.00001,"Foot grounded")
		check(absf(foot_box.end.y-support_box.position.y)<.00001,"Support contacts foot")
		check(absf(support_box.end.y-.325)<.00001,"Support contacts underside frame")
	await capture(assembly,"assembly",Vector3(-.3,1,-.5),4.7)
	stack_node.hide()
	plinth_node.hide()
	record_node.hide()
	await capture(assembly,"bench",Vector3(-1.1,.225,0),2.0)
	bench_node.hide()
	plinth_node.show()
	record_node.show()
	await capture(assembly,"plinth",Vector3(1,.54,0),1.4)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":meshes,"bench_size_m":str(bench.size),"plinth_size_m":str(plinth.size),"cassette_contact_error_m":absf(record.position.y-plinth.end.y),"cassette_x_margin_m":minf(record.position.x-plinth.position.x,plinth.end.x-record.end.x),"cassette_z_margin_m":minf(record.position.z-plinth.position.z,plinth.end.z-record.end.z),"bench_stack_aisle_m":bench.position.z-stack.end.z,"mcp":"Both disconnected; standalone Blender and isolated Godot fallback","scope":"Optional furniture staged only; full-room placement and camera clearance deferred. No collision or animation required."}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
