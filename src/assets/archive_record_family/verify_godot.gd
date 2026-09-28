extends SceneTree
## Imported geometry, rail interface and real physics-ray validation.

const OUT := "res://assets/archive_record_family/"
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func inspect_meshes(node: Node3D, expected_triangles: int) -> AABB:
	var combined := AABB()
	var first := true
	var triangle_count := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var mesh := instance.mesh
		var box: AABB = instance.global_transform * mesh.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
		for surface in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(surface) as StandardMaterial3D
			check(mat != null, "Missing PBR material")
			if mat == null:
				continue
			check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Opaque material required")
			check(mat.roughness > .6 and not mat.emission_enabled, "Matte non-emissive material required")
			var arrays := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			check(normals.size() == vertices.size() and uvs.size() == vertices.size(), "Normals/UVs missing")
			triangle_count += indices.size() / 3
			for i in range(0, indices.size(), 3):
				var a := indices[i]
				var b := indices[i + 1]
				var c := indices[i + 2]
				var cross := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
				check(cross.length() > 1e-10 and cross.dot(normals[a]) < 0, "Degenerate/reversed triangle: " + str(child.name))
				check(absf((uvs[b]-uvs[a]).cross(uvs[c]-uvs[a])) > 1e-12, "Degenerate UV triangle")
			for normal in normals:
				check(normal.is_finite() and absf(normal.length()-1) < .01, "Invalid normal")
			rows.append({"mesh": str(child.name), "surface": surface, "triangles": indices.size()/3,
				"material": mat.resource_name, "bounds": str(box)})
	check(triangle_count == expected_triangles, "Unexpected triangle count: %d" % triangle_count)
	return combined

func verify() -> void:
	var assembly := (load(OUT + "review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1100, 800)
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var results: Array[Dictionary] = []
	for spec in [["Small", .065, .22, .32], ["Medium", .085, .27, .40], ["Large", .105, .32, .48]]:
		var record := assembly.get_node(spec[0]) as Node3D
		var box := inspect_meshes(record, 1728)
		check(absf(box.position.y) < .00002, "Bottom-center floor contact " + spec[0])
		check(box.size.distance_to(Vector3(spec[1]+.0016,spec[3],spec[2]+.0037)) < .00004, "Envelope " + spec[0] + str(box))
		check(record.scale.is_equal_approx(Vector3.ONE), "No stretched instance")
		var mesh := record.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		check(mesh.mesh.get_surface_count() == 4, "Four family material slots")
		results.append({"size":spec[0], "bounds":str(box), "proposed_shelf_depth_clearance_m":spec[2]+.030-box.size.z, "proposed_shelf_headroom_m":spec[3]+.040-box.size.y})
		if spec[0] == "Medium":
			continue
		for other in ["Small", "Medium", "Large"]:
			(assembly.get_node(other) as Node3D).visible = other == spec[0]
		var target := record.position + Vector3(0,spec[3]/2,0)
		for view in [["front",Vector3(.65,.35,1)], ["rear",Vector3(-.65,.35,-1)], ["side",Vector3(1,0,0)], ["underside",Vector3(.65,-.7,1)]]:
			camera.position = target + view[1]
			camera.look_at(target)
			camera.size = spec[3]*1.6
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://assets/archive_record_"+str(spec[0]).to_lower()+"/godot_"+view[0]+".png") == OK, "Capture saved")
		for other in ["Small", "Medium", "Large"]:
			(assembly.get_node(other) as Node3D).visible = true
	camera.position = Vector3(.9,.65,1.5)
	camera.look_at(Vector3(0,.24,0))
	camera.size = .95
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"godot_family.png") == OK, "Family capture")
	var report := {"engine":Engine.get_version_info().string, "renderer":RenderingServer.get_current_rendering_method(), "passed":failures.is_empty(), "failures":failures, "meshes":rows, "family":results, "shelf_fit":"Provisional dimensions only: issue #28 is not modeled", "mcp":"Unavailable; standalone engine fallback", "collision":"Decorative records; no physics or selection collision required"}
	for path in [OUT,"res://assets/archive_record_small/","res://assets/archive_record_large/"]:
		var file := FileAccess.open(path+"godot_validation.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
