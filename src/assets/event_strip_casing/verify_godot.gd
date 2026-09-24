extends "res://assets/event_socket/verify_godot.gd"
## Checks imported triangles before lighting review; sweeps both articulation axes.

const STRIP_OUT := "res://assets/event_strip_casing/"
const PIVOT_OUT := "res://assets/event_strip_rear_pivot/"
const ATTACH := "Model/Yaw/Pitch/PanelAttachment"

func verify() -> void:
	var assembly := (load(STRIP_OUT + "review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1000, 700)
	var samples := 0
	var minimum_arm_clearance := INF
	var minimum_yoke_clearance := INF
	for label in ["Above", "Below"]:
		var event := assembly.get_node(label) as Node3D
		var arm := event.get_node("Arm") as Node3D
		var pivot := event.get_node("Pivot") as Node3D
		var casing := pivot.get_node(ATTACH + "/Casing") as Node3D
		inspect_meshes(pivot.get_node("Model") as Node3D, 1440)
		var box := inspect_meshes(casing, 376)
		check(box.size.is_equal_approx(Vector3(.9,.2,.03)), "Casing envelope " + str(box))
		check(pivot.global_position.is_equal_approx(arm.get_node("PivotAttachment").global_position), "Connector seat seam")
		check(casing.global_position.is_equal_approx(pivot.get_node(ATTACH).global_position), "Panel mount seam")
		var yaw_node := pivot.get_node("Model/Yaw") as Node3D
		check(yaw_node.position.is_equal_approx(Vector3(0,.03,0)), "Yaw center")
		check(pivot.get_node("Model/Yaw/Pitch").position.is_equal_approx(Vector3(0,.11,0)), "Pitch center")
		var shell := casing.find_child("StripShell*", true, false) as MeshInstance3D
		var vertices: PackedVector3Array = shell.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for yaw in range(-60,61,5):
			for pitch in range(-20,21,5):
				pivot.set("yaw_degrees", yaw)
				pivot.set("pitch_degrees", pitch)
				for vertex in vertices:
					var world_vertex := shell.global_transform * vertex
					var in_pivot := pivot.to_local(world_vertex)
					var in_yaw := yaw_node.to_local(world_vertex)
					minimum_arm_clearance = minf(minimum_arm_clearance, in_pivot.y)
					minimum_yoke_clearance = minf(minimum_yoke_clearance, in_yaw.z - .022)
				check(casing.global_position.is_equal_approx(pivot.get_node(ATTACH).global_position), "Articulated mount drift")
				samples += 1
		pivot.set("yaw_degrees", 100.0)
		pivot.set("pitch_degrees", -100.0)
		check(is_equal_approx(pivot.get("yaw_degrees"),60.0) and is_equal_approx(pivot.get("pitch_degrees"),-20.0), "Angle clamps")
		pivot.set("yaw_degrees", 0.0)
		pivot.set("pitch_degrees", 0.0)
	check(minimum_arm_clearance > 0, "Shell enters connector's axial envelope")
	check(minimum_yoke_clearance > 0, "Shell enters yoke's front envelope")
	var preset := (load(PIVOT_OUT + "event_strip_rear_pivot.tscn") as PackedScene).instantiate() as Node3D
	preset.set("yaw_degrees", -35.0)
	preset.set("pitch_degrees", 12.0)
	root.add_child(preset)
	check(is_equal_approx(preset.get_node("Model/Yaw").rotation.y, deg_to_rad(-35.0)), "Pre-ready yaw lost")
	check(is_equal_approx(preset.get_node("Model/Yaw/Pitch").rotation.x, deg_to_rad(12.0)), "Pre-ready pitch lost")
	preset.free()
	var above := assembly.get_node("Above/Pivot") as Node3D
	var front_casing := above.get_node(ATTACH + "/Casing") as Node3D
	await physics_frame
	await physics_frame
	for direction in [-1.0,1.0]:
		var query := PhysicsRayQueryParameters3D.create(front_casing.to_global(Vector3(0,0,direction)),front_casing.to_global(Vector3(0,0,-direction)),32)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var hit := front_casing.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.get("collider") == front_casing.get_node("PickingProxy"), "Casing picking ray missed")
		query.from = front_casing.to_global(Vector3(.46,0,direction))
		query.to = front_casing.to_global(Vector3(.46,0,-direction))
		check(front_casing.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Proxy exceeds casing width")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly",Vector3(1,.1,3),Vector3(1,0,0),1.65],
		["front",Vector3(.80,.80,1.7),Vector3(.55,.658,.16),.70],
		["rear",Vector3(.85,.85,-1.2),Vector3(.55,.63,.12),.70],
		["underside",Vector3(.75,-.1,.8),Vector3(.55,.63,.13),.65],
		["side",Vector3(1.7,.68,.3),Vector3(.55,.63,.12),.65],
		["pivot",Vector3(.80,.70,-.4),Vector3(.55,.61,.11),.24],
		["articulated",Vector3(.95,.80,1.4),Vector3(.55,.65,.16),.70]]
	for view in views:
		if view[0] == "articulated":
			above.set("yaw_degrees", 60.0)
			above.set("pitch_degrees", 20.0)
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(STRIP_OUT + "godot_" + view[0] + ".png") == OK, "Screenshot save")
	above.set("yaw_degrees", 0.0)
	above.set("pitch_degrees", 0.0)
	var report := {"engine":Engine.get_version_info().string,
		"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),
		"failures":failures,"meshes":rows,"pose_samples":samples,
		"min_shell_to_connector_end_m":minimum_arm_clearance,
		"min_shell_to_yoke_front_m":minimum_yoke_clearance,
		"picking":"front/rear hits and outside-width misses",
		"mcp":"Bridge occupied; isolated pinned-engine fallback. Live MCP checks incomplete.",
		"scope":"Static model/assembly verification; no camera tracking, content or room-scale acceptance"}
	for path in [STRIP_OUT,PIVOT_OUT]:
		var file := FileAccess.open(path + "godot_validation.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
