extends "res://assets/event_socket/verify_godot.gd"
## Reuses imported mesh integrity checks; exercises both attachment directions.

const ARM_OUT := "res://assets/event_connector_arm/"

func mesh_bounds(node: MeshInstance3D) -> AABB:
	return node.global_transform * node.mesh.get_aabb()

func verify() -> void:
	var assembly := (load(ARM_OUT + "review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1000,700)
	var tested_lengths: Array[float] = []
	for label in ["Above", "Below"]:
		var event := assembly.get_node(label) as Node3D
		var arm := event.get_node("Arm") as Node3D
		var socket := event.get_node("Socket") as Node3D
		var box := inspect_meshes(arm, 308)
		check(box.size.is_equal_approx(Vector3(.028,.45,.028)), "Default arm dimensions: " + str(box))
		check(arm.get_node("SocketAttachment").global_position.is_equal_approx(
			socket.get_node("UpperAttachment").global_position), "Socket-to-arm seam gap")
		var base := arm.find_child("ConnectorBase*", true, false) as MeshInstance3D
		var shaft := arm.find_child("ConnectorShaft*", true, false) as MeshInstance3D
		var tip := arm.find_child("ConnectorTip*", true, false) as MeshInstance3D
		var base_size := mesh_bounds(base).size
		var tip_size := mesh_bounds(tip).size
		for requested in [.12, .45, .8, 2.0, -1.0, 3.0]:
			arm.set("length_m", requested)
			var expected := clampf(requested, .12, 2.0)
			check(is_equal_approx(arm.get("length_m"), expected), "Length clamping")
			var start: Vector3 = arm.get_node("SocketAttachment").global_position
			var end: Vector3 = arm.get_node("PivotAttachment").global_position
			check(is_equal_approx(start.distance_to(end), expected), "Attachment distance")
			check(end.y > start.y if label == "Above" else end.y < start.y, "Attachment direction")
			check(mesh_bounds(base).size.is_equal_approx(base_size), "Base fitting distorted")
			check(mesh_bounds(tip).size.is_equal_approx(tip_size), "Tip fitting distorted")
			check(is_equal_approx(mesh_bounds(shaft).size.x,.018), "Shaft diameter changed")
			check(is_equal_approx(mesh_bounds(shaft).size.y,expected-.056), "Shaft length")
			var shaft_start: Vector3 = shaft.transform * Vector3.ZERO
			var shaft_end: Vector3 = shaft.transform * Vector3(0,.394,0)
			check(is_equal_approx(.035-shaft_start.y,.007), "Base engagement must remain 7 mm")
			check(is_equal_approx(shaft_end.y-(expected-.035),.007), "Tip engagement must remain 7 mm")
			check(absf(start.z-.074) < .00001 and absf(end.z-.074) < .00001, "Front offset changed")
			tested_lengths.append(expected)
		arm.set("length_m", .45)
	var preset := (load(ARM_OUT + "event_connector_arm.tscn") as PackedScene).instantiate() as Node3D
	preset.set("length_m", .8)
	root.add_child(preset)
	check(is_equal_approx(preset.get_node("PivotAttachment").position.y,.8), "Pre-ready exported length lost")
	preset.free()
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		["assembly", Vector3(1,.15,3), Vector3(1,0,0), 2.2],
		["front", Vector3(.9,.3,.9), Vector3(.65,.27,.074), .65],
		["rear", Vector3(.9,.3,-.8), Vector3(.65,.27,.074), .65],
		["underside", Vector3(.9,-.8,.7), Vector3(.65,.27,.074), .75],
		["side", Vector3(1.5,.3,.15), Vector3(.65,.27,.074), .65],
		["socket_fit", Vector3(.78,.12,.4), Vector3(.65,.065,.074), .20],
		["pivot_end", Vector3(.77,.55,.4), Vector3(.65,.50,.074), .13]]
	for view in views:
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(ARM_OUT + "godot_" + view[0] + ".png") == OK, "Screenshot write")
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "passed": failures.is_empty(),
		"failures": failures, "meshes": rows, "tested_lengths_m": tested_lengths,
		"shaft_engagement_m": .007, "socket_seam_gap_m": 0,
		"mcp": "Unavailable: another client owns bridge; isolated engine fallback",
		"scope": "Static arm; actual rear pivot is issue #12 and is not delivered here"}
	var file := FileAccess.open(ARM_OUT + "godot_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
