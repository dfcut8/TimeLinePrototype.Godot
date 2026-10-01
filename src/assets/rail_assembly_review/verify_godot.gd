extends SceneTree
## Validates the actual imported meshes and captures the assembled rail without bloom.

const OUT := "res://assets/rail_assembly_review/"
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
	var housings: Array[AABB] = []
	for label in ["ModuleA", "ModuleB", "ModuleC"]:
		var module := assembly.get_node("Rail/"+label) as Node3D
		housings.append(bounds_of(module.get_node("Housing"), Vector3(2, .12, .12), 52))
		var box := bounds_of(module.get_node("Light"), Vector3(2, .024, .013), 28)
		lights.append(box)
		check(absf(box.position.z - .031) < .00001, "Insert seat clearance")
		check(absf(box.end.z - .044) < .00001, "Insert front recess")
		check(box.position.y >= -.01201 and box.end.y <= .01201, "Insert lateral clearance")
	for i in range(2):
		check(absf(housings[i].end.x-housings[i+1].position.x)<.00001, "Housing seam gap")
		var left := assembly.get_node("Rail/"+["ModuleA","ModuleB"][i]+"/Housing/LaterEnd") as Marker3D
		var right := assembly.get_node("Rail/"+["ModuleB","ModuleC"][i]+"/Housing/EarlierEnd") as Marker3D
		check(left.global_position.is_equal_approx(right.global_position), "Housing attachment alignment")
		check(absf(lights[i].end.x - lights[i + 1].position.x) < .00001, "Light line seam gap")
		var joiner := assembly.get_node("Rail/"+["JoinerA", "JoinerB"][i]) as Node3D
		var box := bounds_of(joiner, Vector3(.08, .126, .043), 44)
		check(absf(box.get_center().x - lights[i].end.x) < .00001, "Joiner seam alignment")
		check(box.end.z < -.01999, "Joiner obstructs front channel")
		var saddle_mesh := joiner.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var vertices: PackedVector3Array = saddle_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			check(absf(vertex.y) >= .06049 or vertex.z <= -.06049, "Joiner penetrates housing")
	check(RenderingServer.get_current_rendering_method() == "forward_plus", "Forward+ required")
	check(assembly.find_children("*", "Camera3D", true, false).size()==1,"Asset contains no review camera")
	var start := assembly.get_node("Rail/StartCap") as Node3D
	var end := assembly.get_node("Rail/EndCap") as Node3D
	var start_box := bounds_of(start, Vector3(.004,.12,.12), 28)
	var end_box := bounds_of(end, Vector3(.004,.12,.12), 28)
	var first := bounds_of(assembly.get_node("Rail/ModuleA/Housing"), Vector3(2,.12,.12), 52)
	var last := bounds_of(assembly.get_node("Rail/ModuleC/Housing"), Vector3(2,.12,.12), 52)
	var first_light := bounds_of(assembly.get_node("Rail/ModuleA/Light"), Vector3(2,.024,.013), 28)
	var last_light := bounds_of(assembly.get_node("Rail/ModuleC/Light"), Vector3(2,.024,.013), 28)
	check(absf(start_box.end.x - first.position.x) < 1e-6, "Start housing seam")
	check(absf(end_box.position.x - last.end.x) < 1e-6, "End housing seam")
	check(absf(start_box.end.x - first_light.position.x) < 1e-6, "Start light termination")
	check(absf(end_box.position.x - last_light.end.x) < 1e-6, "End light termination")
	check(absf(start_box.position.x + .004) < 1e-6 and absf(end_box.end.x - 6.004) < 1e-6, "Cap orientation")
	for cap: Node3D in [start, end]:
		check(cap.basis == Basis.IDENTITY, "Cap transform must be identity")
		check((cap.get_node("RailInterface") as Node3D).position == Vector3.ZERO, "Interface pivot")
		var mesh_instance := cap.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		var faces := mesh_instance.mesh.get_faces()
		# Probe actual triangles across the channel aperture, including both outer
		# sides of the light insert. AABB coverage alone cannot prove closure.
		for y: float in [-.019, -.012, 0.0, .012, .019]:
			for z: float in [.0305, .0375, .044, .059]:
				var hits := 0
				for i in range(0, faces.size(), 3):
					var hit: Variant = Geometry3D.segment_intersects_triangle(Vector3(-.01,y,z), Vector3(.01,y,z), faces[i],faces[i+1],faces[i+2])
					if hit != null:
						hits += 1
				check(hits >= 2, "Cap must close entire channel at " + str(Vector2(y,z)))
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly", Vector3(3,.7,6), Vector3(3,0,0), 6.6],
		["seam_front", Vector3(2,.16,.6), Vector3(2,0,0), .5],
		["seam_rear", Vector3(2,.16,-.6), Vector3(2,0,0), .5],
		["seam_underside", Vector3(2,-.4,.4), Vector3(2,0,0), .5],
		["start_front", Vector3(-.24,.17,.4), Vector3(.08,0,0), .42],
		["start_rear", Vector3(-.24,.17,-.4), Vector3(.06,0,0), .42],
		["start_underside", Vector3(-.24,-.22,.3), Vector3(.06,0,0), .42],
		["start_end", Vector3(-.5,0,0), Vector3.ZERO, .19],
		["end_front", Vector3(6.24,.17,.4), Vector3(5.92,0,0), .42],
		["end_rear", Vector3(6.24,.17,-.4), Vector3(5.94,0,0), .42],
		["end_underside", Vector3(6.24,-.22,.3), Vector3(5.94,0,0), .42],
		["end_end", Vector3(6.5,0,0), Vector3(6,0,0), .19]
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
		"housing_seam_gaps_m": [first.position.x-start_box.end.x,end_box.position.x-last.end.x],
		"light_seam_gaps_m": [first_light.position.x-start_box.end.x,end_box.position.x-last_light.end.x],
		"channel_closure_probes_per_cap": 20,
		"mcp": "Both MCPs disconnected; isolated Forward+ D3D12 fallback",
		"module_seam_gaps_m": [housings[1].position.x-housings[0].end.x,housings[2].position.x-housings[1].end.x],
		"physics_animation": "Not applicable: static decorative assembly"}
	for folder in [OUT]:
		var file := FileAccess.open(folder + "godot_validation.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)


