extends SceneTree
## Isolated GPU validation; see verify_godot.ps1.

const ASSET := "res://assets/timeline_rail_housing/"
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var packed := load(ASSET + "review_assembly.tscn") as PackedScene
	if packed == null:
		push_error("Review scene failed to load")
		quit(1)
		return
	var assembly := packed.instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1400, 650)
	var rows: Array[Dictionary] = []
	var bounds: Array[AABB] = []
	for module_name in ["ModuleA", "ModuleB", "ModuleC"]:
		var module := assembly.get_node(module_name) as Node3D
		var meshes := module.find_children("*", "MeshInstance3D", true, false)
		check(meshes.size() == 1, "Expected one mesh in " + module_name)
		for node in meshes:
			var mesh_node := node as MeshInstance3D
			var mesh := mesh_node.mesh
			var box: AABB = mesh_node.global_transform * mesh.get_aabb()
			bounds.append(box)
			check(box.size.is_equal_approx(Vector3(2, .12, .12)), "Incorrect imported dimensions")
			check(mesh.get_surface_count() == 1, "Expected one material surface")
			var mat := mesh.surface_get_material(0) as StandardMaterial3D
			check(mat != null and mat.roughness > .6, "Missing matte PBR material")
			check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Unexpected transparency")
			var arrays := mesh.surface_get_arrays(0)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			check(indices.size() == 156, "Triangle count changed during import")
			check(normals.size() == positions.size() and uvs.size() == positions.size(), "Missing normals or UVs")
			for i in range(0, indices.size(), 3):
				var a := indices[i]
				var b := indices[i + 1]
				var c := indices[i + 2]
				var cross := (positions[b] - positions[a]).cross(positions[c] - positions[a])
				check(cross.length() > 0.00000001, "Degenerate triangle")
				check(cross.dot(normals[a]) < 0, "Winding does not match Godot clockwise normals")
			for normal in normals:
				check(normal.is_finite() and absf(normal.length() - 1) < .01, "Invalid normal")
			rows.append({"module": module_name, "bounds": str(box), "triangles": indices.size() / 3, "material": mat.resource_name})
	var gaps: Array[float] = []
	for i in range(2):
		var gap := bounds[i + 1].position.x - bounds[i].end.x
		gaps.append(gap)
		check(absf(gap) < .00001, "Gap or overlap between repeated modules")
		var left := assembly.get_node("Module" + ["A", "B"][i] + "/LaterEnd") as Marker3D
		var right := assembly.get_node("Module" + ["B", "C"][i] + "/EarlierEnd") as Marker3D
		check(left.global_position.is_equal_approx(right.global_position), "Attachment markers disagree")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly", Vector3(3, .8, 6), Vector3(3, 0, 0), 6.6],
		["front", Vector3(2.5, 1, 3), Vector3(1, 0, 0), 2.6],
		["rear", Vector3(-.5, .7, -3), Vector3(1, 0, 0), 2.6],
		["underside", Vector3(2.5, -1, 3), Vector3(1, 0, 0), 2.6],
		["end", Vector3(-1, .02, .035), Vector3(0, 0, 0), .24],
		["seam", Vector3(2, .16, .5), Vector3(2, 0, 0), .65]
	]
	for view in views:
		assembly.get_node("ModuleB").visible = view[0] in ["assembly", "seam"]
		assembly.get_node("ModuleC").visible = view[0] == "assembly"
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		var err := root.get_texture().get_image().save_png(ASSET + "godot_" + view[0] + ".png")
		check(err == OK, "Could not save rendered view")
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "modules": rows, "seam_gaps_m": gaps, "failures": failures, "passed": failures.is_empty(), "mcp": "Unavailable: another client owns bridge; isolated CLI fallback", "collision": "Not applicable: decorative housing; no physics or selection behavior requested"}
	var file := FileAccess.open(ASSET + "godot_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
