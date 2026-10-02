extends SceneTree
## Imported mesh bounds are measured in row space, even under rotated parents.
const OUT := "res://assets/record_stack_family/"
const ROW: PackedScene = preload("res://assets/record_stack_end_cap/configurable_shelf_row.tscn")
const EPS: float = 0.0001
var failures: Array[String] = []
var cases: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func bounds(node: Node3D, space: Node3D) -> AABB:
	var combined := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var box: AABB = (space.global_transform.affine_inverse() * mesh.global_transform) * mesh.mesh.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
	check(not first, "Imported geometry present: " + str(node.name))
	return combined

func inspect_row(row: Node3D, count: int, label: String) -> void:
	check(row.get("bay_count") == count, label + ": count")
	var bays := row.get_node("Bays")
	var previous := AABB()
	var first := AABB()
	var max_gap := 0.0
	var fixture_count := 0
	for index in range(count):
		var bay := bays.get_node("Bay%d" % index) as Node3D
		check(bay.scene_file_path.ends_with("illuminated_shelf_bay.tscn"), "Reusable illuminated bay")
		check(bay.scale.is_equal_approx(Vector3.ONE), "Unit bay scale")
		var box := bounds(bay.get_node("Bay"), row)
		check(box.size.distance_to(Vector3(1.6, 2.4, .44)) < EPS, "Bay envelope")
		check(absf(box.position.y) < EPS, "Floor contact")
		check(absf(box.get_center().x - (index - (count - 1) * .5) * 1.6) < EPS, "Centred bay pitch")
		if index == 0:
			first = box
		else:
			max_gap = maxf(max_gap, absf(box.position.x - previous.end.x))
		previous = box
		for tier in range(4):
			var light := bay.get_node("Light%d" % tier) as Node3D
			var mount := bay.get_node("Bay/LightMount%d" % tier) as Node3D
			var recess := bay.get_node("Bay/LightRecess%d" % tier) as Node3D
			var light_box := bounds(light, bay)
			check(light.global_position.distance_to(mount.global_position) < EPS, "Fixture mounting")
			check(light.scale.is_equal_approx(Vector3.ONE), "Unit fixture scale")
			check(absf(light_box.end.y - mount.position.y) < EPS, "Fixture deck contact")
			check(light_box.position.y > recess.position.y - .006, "Fixture lip clearance")
			check(light_box.position.x > -.75 and light_box.end.x < .75, "Fixture upright clearance")
			check(light_box.position.z > .15 and light_box.end.z < .20, "Fixture depth clearance")
			fixture_count += 1
	var left := bounds(row.get_node("CapLeft"), row)
	var right := bounds(row.get_node("CapRight"), row)
	check(absf(left.end.x - first.position.x) < EPS, "Left cap contact")
	check(absf(right.position.x - previous.end.x) < EPS, "Right cap contact")
	for cap_name in ["CapLeft", "CapRight"]:
		var cap := row.get_node(cap_name) as Node3D
		var box := bounds(cap, row)
		check(cap.scale.is_equal_approx(Vector3.ONE), "Caps use rotation, no mirroring")
		check(box.size.distance_to(Vector3(.082, 2.4, .44)) < EPS, "Cap covers height and depth")
		check(absf(box.position.y) < EPS and absf(box.get_center().z) < EPS, "Cap floor/depth alignment")
	check(left.position.x < first.position.x and right.end.x > previous.end.x, "Caps face outward")
	check(absf(left.position.x + right.end.x) < EPS, "Symmetric complete envelope")
	check(absf((row.get_node("LeftJoin") as Node3D).position.x - first.position.x) < EPS, "Left marker")
	check(absf((row.get_node("RightJoin") as Node3D).position.x - previous.end.x) < EPS, "Right marker")
	check(max_gap < EPS, "Adjacent bay seams")
	cases.append({"case": label, "bays": count, "fixtures": fixture_count,
		"complete_width_m": right.end.x - left.position.x, "max_seam_error_m": max_gap})

func verify() -> void:
	root.size = Vector2i(1100, 720)
	var assembly := (load(OUT + "review_configurable.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	var row := assembly.get_node("Row") as Node3D
	inspect_row(row, 5, "saved override")
	var sentinel := Marker3D.new()
	sentinel.name = "UserAttachment"
	row.get_node("Bays").add_child(sentinel)
	sentinel.owner = row
	for requested: int in [1, 2, 3, 7, 3, 0, -5, 33, 5]:
		row.set("bay_count", requested)
		await process_frame
		var count := clampi(requested, 1, 32)
		inspect_row(row, count, "requested %d" % requested)
		check(row.get_node("Bays").get_child_count() == count + 1, "No accumulated generated bays")
		check(is_instance_valid(sentinel) and sentinel.get_parent() == row.get_node("Bays"), "User attachment preserved")
		assembly.position = Vector3(-8, 1.5, 4)
		assembly.rotation_degrees = Vector3(0, -23, 0)
		row.position = Vector3(3, .5, -2)
		row.rotation_degrees = Vector3(0, 61, 0)
	# Disk round-trip, including non-default configuration and user-owned children.
	var saved := PackedScene.new()
	check(saved.pack(row) == OK, "Pack row")
	check(ResourceSaver.save(saved, "user://shelf_row.tscn") == OK, "Save row to disk")
	var reloaded := load("user://shelf_row.tscn") as PackedScene
	var restored := reloaded.instantiate() as Node3D
	root.add_child(restored)
	inspect_row(restored, 5, "disk reload")
	check(restored.get_node("Bays").get_child_count() == 6, "Disk reload has five bays and user attachment")
	check(restored.has_node("Bays/UserAttachment"), "User attachment serialized")
	restored.set("bay_count", 2)
	inspect_row(restored, 2, "independent instance")
	check(row.get("bay_count") == 5 and row.get_node("Bays").get_child_count() == 6, "Original instance unchanged")
	root.remove_child(restored)
	restored.queue_free()
	var detached := ROW.instantiate() as Node3D
	detached.set("bay_count", 2)
	root.add_child(detached)
	inspect_row(detached, 2, "configured before ready")
	root.remove_child(detached)
	detached.set("bay_count", 4)
	root.add_child(detached)
	inspect_row(detached, 4, "detached resize and reentry")
	root.remove_child(detached)
	detached.queue_free()
	assembly.transform = Transform3D.IDENTITY
	row.transform = Transform3D.IDENTITY
	row.set("bay_count", 3)
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["front", Vector3(3, 3, 7)], ["rear", Vector3(-3, 3, -7)],
		["end", Vector3(7, 2, 1)], ["underside", Vector3(3, -3, 6)]]:
		camera.position = view[1]
		camera.look_at(Vector3(0, 1.2, 0))
		camera.size = 6.0
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(OUT + "godot_configurable_" + view[0] + ".png") == OK, "Capture")
	var report := {"engine": Engine.get_version_info().string,
		"renderer": RenderingServer.get_current_rendering_method(), "passed": failures.is_empty(),
		"failures": failures, "cases": cases, "mcp": "Both disconnected; standalone Godot fallback",
		"scope": "Imported assembly fit and configuration; live editor, full room and performance unverified"}
	FileAccess.open(OUT + "godot_configurable_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
