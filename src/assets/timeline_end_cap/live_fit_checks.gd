extends RefCounted
## Run through godot_exec in the live review scene; no file writes or game exit.
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

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


func validate(assembly: Node3D) -> Dictionary:
	var start := assembly.get_node("StartCap") as Node3D
	var end := assembly.get_node("EndCap") as Node3D
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
	return {"passed": failures.is_empty(), "failures": failures, "meshes": rows,
		"housing_seam_gaps_m": [first.position.x-start_box.end.x,end_box.position.x-last.end.x],
		"light_seam_gaps_m": [first_light.position.x-start_box.end.x,end_box.position.x-last_light.end.x],
		"channel_closure_probes_per_cap": 20,
		"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name()}
