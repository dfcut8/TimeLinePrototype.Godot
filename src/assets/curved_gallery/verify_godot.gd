extends SceneTree
## Run in an isolated project containing curved_gallery.glb; see README.

var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var packed := load("res://curved_gallery.glb") as PackedScene
	if packed == null:
		push_error("GLB did not import as a PackedScene")
		quit(1)
		return
	var assembly := Node3D.new()
	root.add_child(assembly)
	var instance := packed.instantiate() as Node3D
	assembly.add_child(instance)
	var meshes: Array[Node] = instance.find_children("*", "MeshInstance3D", true, false)
	if instance is MeshInstance3D:
		meshes.append(instance)
	check(meshes.size() == 1, "Expected exactly one mesh")
	var vertices: Array[Vector3] = []
	var triangles := 0
	var materials: Array[String] = []
	var min_y := INF
	var max_y := -INF
	var minimum_radius := INF
	var maximum_radius := 0.0
	for node in meshes:
		var mesh_node := node as MeshInstance3D
		check(mesh_node.global_transform.is_equal_approx(Transform3D.IDENTITY), "Nonidentity import transform")
		var mesh: Mesh = mesh_node.mesh
		check(mesh.get_surface_count() == 2, "Expected two material surfaces")
		for surface in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(surface) as StandardMaterial3D
			check(mat != null, "Missing PBR material")
			if mat:
				materials.append(mat.resource_name)
				check(mat.roughness > 0.6, "Material lost matte roughness")
				check(mat.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "Unexpected transparency")
			var arrays: Array = mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += indices.size() / 3
			check(normals.size() == positions.size(), "Missing normals")
			check(uvs.size() == positions.size(), "Missing UV0")
			for v in positions:
				vertices.append(v)
				min_y = minf(min_y, v.y)
				max_y = maxf(max_y, v.y)
				var radius := Vector2(v.x, v.z).length()
				minimum_radius = minf(minimum_radius, radius)
				maximum_radius = maxf(maximum_radius, radius)
	check(triangles == 546, "Triangle count changed")
	check(absf(min_y + 0.25) < 0.00001 and absf(max_y - 1.1) < 0.00001, "Wrong vertical scale or axis")
	check(absf(minimum_radius - 22.0) < 0.00001 and absf(maximum_radius - 25.5) < 0.00001, "Wrong radial scale")
	check(materials.has("archive_graphite") and materials.has("archive_basalt_ceramic"), "Wrong material names")
	var seam_a: Array[Vector3] = []
	var seam_b: Array[Vector3] = []
	for v in vertices:
		var angle := atan2(-v.z, v.x)
		if absf(angle + deg_to_rad(7.5)) < 0.00001:
			seam_a.append(v)
		if absf(angle - deg_to_rad(7.5)) < 0.00001:
			seam_b.append(v)
	check(not seam_a.is_empty() and not seam_b.is_empty(), "Missing sector endpoints")
	var seam_error := 0.0
	for v in seam_a:
		var rotated := v.rotated(Vector3.UP, deg_to_rad(15.0))
		var nearest := INF
		for other in seam_b:
			nearest = minf(nearest, rotated.distance_to(other))
		seam_error = maxf(seam_error, nearest)
	check(seam_error < 0.00001, "Imported adjacent sector seam exceeds tolerance")
	for tier in range(2):
		for sector in range(3):
			if tier == 0 and sector == 0:
				continue
			var copy := packed.instantiate() as Node3D
			assembly.add_child(copy)
			copy.rotation.y = deg_to_rad(15.0 * sector)
			copy.position.y = 5.0 * tier
	check(5.0 + min_y - max_y > 3.64, "Tier clearance failed")
	var report := {
		"engine": Engine.get_version_info().string,
		"passed": failures.is_empty(), "failures": failures,
		"triangles": triangles, "materials": materials,
		"height_bounds_m": [min_y, max_y], "radial_bounds_m": [minimum_radius, maximum_radius],
		"seam_error_m": seam_error, "instances": assembly.get_child_count(),
		"tier_clearance_m": 5.0 + min_y - max_y,
		"scope": "Headless GLB import and assembly; GPU appearance and actual pier fit not validated"
	}
	var file := FileAccess.open("res://godot_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	print(JSON.stringify(report))
	assembly.free()
	quit(0 if failures.is_empty() else 1)
