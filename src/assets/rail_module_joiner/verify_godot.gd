extends SceneTree
## Validates the actual imported meshes and captures the assembled rail without bloom.

const OUT := "res://assets/rail_module_joiner/"
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func bounds_of(node: Node3D, expected: Vector3, triangles: int) -> AABB:
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 1, "Expected one mesh: " + str(node.get_path()))
	var instance := meshes[0] as MeshInstance3D
	var mesh := instance.mesh
	var box: AABB = instance.global_transform * mesh.get_aabb()
	check(box.size.is_equal_approx(expected), "Imported bounds: " + str(box))
	check(mesh.get_surface_count() == 1, "Material surface count")
	var mat := mesh.surface_get_material(0) as StandardMaterial3D
	check(mat != null, "Missing material")
	check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Must be opaque")
	var light := node.name == &"Light"
	check(mat.emission_enabled == light, "Emission flag mismatch")
	check(mat.roughness > .6, "Matte material lost")
	if light:
		check(mat.emission.b > mat.emission.r and mat.emission.r > .5, "Pale cyan emission lost")
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	check(indices.size() == triangles * 3, "Triangle count changed")
	check(normals.size() == vertices.size() and uvs.size() == vertices.size(), "Normals/UVs missing")
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var cross := (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a])
		check(cross.length() > 1e-10 and cross.dot(normals[a]) < 0, "Degenerate/reversed triangle")
	for normal in normals:
		check(normal.is_finite() and absf(normal.length() - 1) < .01, "Invalid normal")
	rows.append({"node": str(node.get_path()), "bounds": str(box), "triangles": triangles,
		"material": mat.resource_name, "emission": mat.emission_enabled})
	return box

func verify() -> void:
	var packed := load(OUT + "review_assembly.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	var assembly := packed.instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1200, 600)
	var lights: Array[AABB] = []
	for label in ["ModuleA", "ModuleB", "ModuleC"]:
		var module := assembly.get_node(label) as Node3D
		bounds_of(module.get_node("Housing"), Vector3(2, .12, .12), 52)
		var box := bounds_of(module.get_node("Light"), Vector3(2, .024, .013), 28)
		lights.append(box)
		check(absf(box.position.z - .031) < .00001, "Insert seat clearance")
		check(absf(box.end.z - .044) < .00001, "Insert front recess")
		check(box.position.y >= -.01201 and box.end.y <= .01201, "Insert lateral clearance")
	for i in range(2):
		check(absf(lights[i].end.x - lights[i + 1].position.x) < .00001, "Light line seam gap")
		var joiner := assembly.get_node(["JoinerA", "JoinerB"][i]) as Node3D
		var box := bounds_of(joiner, Vector3(.08, .126, .043), 44)
		check(absf(box.get_center().x - lights[i].end.x) < .00001, "Joiner seam alignment")
		check(box.end.z < -.01999, "Joiner obstructs front channel")
		var saddle_mesh := joiner.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var vertices: PackedVector3Array = saddle_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			check(absf(vertex.y) >= .06049 or vertex.z <= -.06049, "Joiner penetrates housing")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly", Vector3(3,.7,6), Vector3(3,0,0), 6.6],
		["front", Vector3(2,.16,.6), Vector3(2,0,0), .5],
		["rear", Vector3(2,.16,-.6), Vector3(2,0,0), .5],
		["underside", Vector3(2,-.4,.4), Vector3(2,0,0), .5],
		["side", Vector3(-.5,.02,.035), Vector3(0,0,0), .22]
	]
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + "godot_" + view[0] + ".png") == OK, "Screenshot write")
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "meshes": rows,
		"passed": failures.is_empty(), "failures": failures,
		"seam_gaps_m": [lights[1].position.x-lights[0].end.x, lights[2].position.x-lights[1].end.x],
		"mcp": "Unavailable: another client owns bridge; isolated CLI validation",
		"physics_animation": "Not applicable: static decorative parts"}
	for folder in [OUT, "res://assets/rail_recessed_light_insert/"]:
		var file := FileAccess.open(folder + "godot_validation.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
