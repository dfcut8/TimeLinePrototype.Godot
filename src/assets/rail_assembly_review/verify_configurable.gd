extends SceneTree
## Check imported bounds in rail-local space, including a rotated parent.
const OUT := "res://assets/rail_assembly_review/"
var failures: Array[String] = []
var cases: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func local_bounds(node: Node3D, rail: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var part: AABB = (rail.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()
		box = part if first else box.merge(part)
		first = false
	check(not first, "Imported geometry present")
	return box

func verify() -> void:
	root.size = Vector2i(1200, 600)
	var assembly := (load(OUT + "review_configurable.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var rail := assembly.get_node("Rail") as Node3D
	check(rail.get("module_count") == 7, "Saved exported count survives instancing")
	check(rail.get_node("Modules").get_child_count() == 7, "Ready builds saved count")
	var sentinel := Marker3D.new()
	sentinel.name = "UserAttachment"
	rail.add_child(sentinel)
	for requested: int in [1, 3, 7, 3, 0, 65, 7]:
		rail.set("module_count", requested)
		await process_frame
		var count := clampi(requested, 1, 64)
		check(rail.get("module_count") == count, "Count clamped")
		check(rail.get_node("Modules").get_child_count() == count, "Module count after rebuild")
		check(rail.get_node("Joiners").get_child_count() == count - 1, "Joiner count after rebuild")
		check(is_instance_valid(sentinel) and sentinel.get_parent() == rail, "User children preserved")
		var previous_housing := AABB()
		var previous_light := AABB()
		var max_gap := 0.0
		for index in range(count):
			var module := rail.get_node("Modules/Module%d" % index) as Node3D
			check(module.scale.is_equal_approx(Vector3.ONE), "Module is unscaled")
			check(not module.scene_file_path.is_empty(), "Module remains a scene instance")
			var housing := local_bounds(module.get_node("Housing"), rail)
			var light := local_bounds(module.get_node("Light"), rail)
			check(housing.size.distance_to(Vector3(2, .12, .12)) < .0001, "Housing envelope")
			if index > 0:
				max_gap = maxf(max_gap, absf(housing.position.x - previous_housing.end.x))
				max_gap = maxf(max_gap, absf(light.position.x - previous_light.end.x))
				var joiner := local_bounds(rail.get_node("Joiners/Joiner%d" % index), rail)
				check(absf(joiner.get_center().x - housing.position.x) < .0001, "Joiner on seam")
				check(joiner.end.z < -.0199, "Joiner clears channel")
			previous_housing = housing
			previous_light = light
		var start := local_bounds(rail.get_node("StartCap"), rail)
		var end := local_bounds(rail.get_node("EndCap"), rail)
		check(absf(start.end.x) < .0001, "Start cap contact")
		check(absf(end.position.x - previous_housing.end.x) < .0001, "End cap contact")
		check(absf(end.position.x - previous_light.end.x) < .0001, "Light termination")
		check((rail.get_node("LaterEnd") as Node3D).position.is_equal_approx(Vector3(count * 2, 0, 0)), "Later attachment tracks length")
		check(max_gap < .0001, "Continuous housing and light seams")
		cases.append({"requested": requested, "modules": count, "length_m": count * 2, "max_seam_error_m": max_gap, "transformed": rail.position != Vector3.ZERO})
		# Subsequent rebuilds must use local coordinates under this transform.
		rail.position = Vector3(3, 2, -5)
		rail.rotation_degrees = Vector3(0, 37, 0)
	# Render the 14 m example with the review rig; no full-room approval implied.
	rail.transform = Transform3D.IDENTITY
	# Packing must retain configuration without persisting generated duplicates.
	var saved := PackedScene.new()
	check(saved.pack(rail) == OK, "Pack configured rail")
	var restored := saved.instantiate() as Node3D
	root.add_child(restored)
	check(restored.get("module_count") == 7, "Packed count retained")
	check(restored.get_node("Modules").get_child_count() == 7, "Reload has no duplicate modules")
	restored.set("module_count", 1)
	check(rail.get_node("Modules").get_child_count() == 7, "Instances configure independently")
	root.remove_child(restored)
	restored.queue_free()
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["long", Vector3(7, 2, 10), Vector3(7, 0, 0), 15.0], ["last_seam", Vector3(12, .16, .6), Vector3(12, 0, 0), .5]]:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + "godot_configurable_" + view[0] + ".png") == OK, "Capture saved")
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "passed": failures.is_empty(), "failures": failures, "cases": cases, "mcp": "Disconnected; isolated Godot fallback"}
	FileAccess.open(OUT + "godot_configurable_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
