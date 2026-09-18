extends SceneTree
## Imported geometry, rail interface and real physics-ray validation.

const OUT := "res://assets/event_socket/"
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
	root.size = Vector2i(1000, 700)
	var socket := assembly.get_node("Socket") as Node3D
	var box := inspect_meshes(socket, 692)
	check(box.size.is_equal_approx(Vector3(.11,.136,.0275)), "Socket dimensions: " + str(box))
	check(absf(box.position.z-.06) < .00001, "Socket rear must contact rail front at Z=.060")
	check(box.position.z > .044, "Socket intersects recessed light insert")
	check(socket.get_node("UpperAttachment").position.is_equal_approx(Vector3(0,.068,.074)), "Upper interface")
	check(socket.get_node("LowerAttachment").position.is_equal_approx(Vector3(0,-.068,.074)), "Lower interface")
	var body := socket.get_node("Model").find_child("SocketBody*", true, false) as MeshInstance3D
	check(body.mesh.get_surface_count() == 2, "Separate emphasis material missing")
	await physics_frame
	await physics_frame
	var query := PhysicsRayQueryParameters3D.create(Vector3(1,0,1), Vector3(1,0,-1), 16)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := socket.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.get("collider") == socket.get_node("PickingProxy"), "Front picking ray missed")
	query.from = Vector3(1,0,-1)
	query.to = Vector3(1,0,1)
	hit = socket.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.get("collider") == socket.get_node("PickingProxy"), "Rear picking ray missed")
	query.from = Vector3(1.2,0,1)
	query.to = Vector3(1.2,0,-1)
	check(socket.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Picking proxy too wide")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly", Vector3(1,.3,3), Vector3(1,0,0), 2.2],
		["front", Vector3(1.12,.08,.5), Vector3(1,0,.07), .24],
		["rear", Vector3(1.14,.12,-.5), Vector3(1,0,.07), .3],
		["underside", Vector3(1.1,-.4,.4), Vector3(1,0,.07), .3],
		["side", Vector3(1.5,.02,.12), Vector3(1,0,.07), .3]]
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + "godot_" + view[0] + ".png") == OK, "Screenshot write")
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "passed": failures.is_empty(),
		"failures": failures, "meshes": rows, "picking": "front/rear hits and outside miss checked",
		"mcp": "Unavailable: another client owns bridge; isolated engine fallback"}
	var file := FileAccess.open(OUT + "godot_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
