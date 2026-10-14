extends "res://assets/archive_island_review/verify_island.gd"
## Exercise the editing workflows with imported geometry, not mock cassettes.

const EDIT_OUT := "res://assets/archive_editing_review/"
const FIXED_BAY: PackedScene = preload("res://assets/record_stack_shelf_bay/configurable_cassette_shelf_bay.tscn")
const EDIT_ROW: PackedScene = preload("res://assets/record_stack_end_cap/configurable_shelf_row.tscn")
const POPULATED_ROW: PackedScene = preload("res://assets/record_stack_end_cap/configurable_populated_shelf_row.tscn")
var edit_cases: Array[String] = []
var identity_checks: int = 0

func snapshot(container: Node) -> Dictionary:
	var result: Dictionary = {}
	for child in container.get_children():
		if child is Node3D and not child.scene_file_path.is_empty():
			result[str(child.name)] = child.get_instance_id()
	return result

func retains(container: Node, previous: Dictionary, names: Array[String], label: String) -> void:
	var current := snapshot(container)
	for object_name in names:
		check(current.get(object_name) == previous.get(object_name), label + ": retain " + object_name)
		identity_checks += 1

func record_names(count: int) -> Array[String]:
	var names: Array[String] = []
	for tier in range(4):
		for slot in range(count):
			names.append("Record_%d_%d" % [tier, slot])
	return names

func inspect_fixed(bay: Node3D, label: String) -> void:
	var count: int = bay.get("records_per_shelf")
	var records := bay.get_node("Records")
	check(snapshot(records).size() == count * 4, label + ": exact fixed population")
	var shelf := bay.get_node("Shelf") as Node3D
	for tier in range(4):
		var deck := part_bounds(shelf, "shelf_%d_deck" % tier, bay)
		var previous := AABB()
		for slot in range(count):
			var record := records.get_node("Record_%d_%d" % [tier, slot]) as Node3D
			var box := local_bounds(record, bay)
			check(absf(box.position.y - deck.end.y) < EPS, label + ": deck datum")
			check(record_supported(record, shelf, bay), label + ": imported bottom support")
			check(record.owner == null and record.scale.is_equal_approx(Vector3.ONE), label + ": unsaved unscaled scene")
			check(box.position.x > -.72 and box.end.x < .72, label + ": clear width")
			if slot > 0:
				check(box.position.x > previous.end.x, label + ": separated records")
			previous = box

func inspect_population(bay: Node3D, packed: bool, label: String) -> void:
	if packed:
		inspect_packed(bay, label)
	else:
		inspect_fixed(bay, label)

func verify_records(scene: PackedScene, size: int) -> void:
	var packed: bool = scene == PACKED_BAY
	var count_property: String = "requested_records_per_shelf" if packed else "records_per_shelf"
	var label := ("packed" if packed else "fixed") + " size " + str(size)
	var bay := scene.instantiate() as Node3D
	bay.set("cassette_pattern", PackedInt32Array([size]))
	bay.set(count_property, 3)
	root.add_child(bay)
	var records := bay.get_node("Records") as Node3D
	var before := snapshot(records)
	var first := records.get_node("Record_0_0") as Node3D
	var addition := attach_sentinel(first, first)
	first.set_meta("catalog_note", "survive count and spacing")
	var mesh := first.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var override := StandardMaterial3D.new()
	override.albedo_color = Color(.2, .3, .4)
	mesh.material_override = override
	bay.set("cassette_pattern", PackedInt32Array([size, size]))
	bay.set(count_property, 9 if not packed else 32)
	retains(records, before, record_names(3), label + " growth and equivalent pattern")
	var removed := records.get_node("Record_0_2") as Node3D
	bay.set(count_property, 2)
	retains(records, before, record_names(2), label + " shrink")
	check(removed.get_parent() == null and removed.is_queued_for_deletion(), label + ": removed slot detached immediately")
	if packed:
		for gap in [.15, .02]:
			bay.set("record_gap", gap)
			retains(records, before, record_names(2), label + " gap")
			inspect_population(bay, packed, label + " gap " + str(gap))
	check(is_instance_valid(addition) and first.get_meta("catalog_note") == "survive count and spacing",
		label + ": child state survives edits")
	check(mesh.material_override == override, label + ": material override survives edits")
	mesh.material_override = null
	bay.set(count_property, 3)
	before = snapshot(records)
	bay.set("cassette_pattern", PackedInt32Array([size, (size + 1) % 3, size]))
	for tier in range(4):
		retains(records, before, ["Record_%d_0" % tier, "Record_%d_2" % tier], label + " one-size edit")
		check(snapshot(records)["Record_%d_1" % tier] != before["Record_%d_1" % tier], label + ": changed size replaced")
	before = snapshot(records)
	records.transform = Transform3D(Basis(Vector3.UP, .37), Vector3(3, 2, -1))
	bay.transform = Transform3D(Basis(Vector3.UP, -.71), Vector3(8, 2, -6))
	bay.set(count_property, 3)
	retains(records, before, record_names(3), label + " transformed container")
	inspect_population(bay, packed, label + " transformed container")
	var container_addition := attach_sentinel(records, bay)
	var restored := disk_roundtrip(bay, "editing_" + label.replace(" ", "_"))
	inspect_population(restored, packed, label + " disk reload")
	check(restored.has_node("Records/UserAttachment"), label + ": owned container addition serialized")
	check(not restored.has_node("Records/Record_0_0/UserAttachment"), label + ": generated slot state is transient")
	root.remove_child(bay)
	bay.set(count_property, 2)
	root.add_child(bay)
	retains(records, before, record_names(2), label + " detached edit")
	# Recover an externally deleted managed slot, without replacing its neighbor.
	var neighbor_id := records.get_node("Record_1_0").get_instance_id()
	first.queue_free()
	bay.set(count_property, 2)
	check(records.get_node("Record_0_0").get_instance_id() != before["Record_0_0"], label + ": queued slot recreated")
	check(records.get_node("Record_1_0").get_instance_id() == neighbor_id, label + ": neighbor unaffected by repair")
	records.get_node("Record_0_1").free()
	bay.set(count_property, 2)
	check(records.has_node("Record_0_1") and snapshot(records).size() == 8, label + ": freed slot recreated exactly once")
	bay.set(count_property, 0)
	check(snapshot(records).is_empty(), label + ": zero removes every generated record")
	check(is_instance_valid(container_addition), label + ": emptying retains container additions")
	bay.set(count_property, 3)
	inspect_population(bay, packed, label + " repopulated")
	check(restored.get(count_property) == 3, label + ": reload remains independent")
	bay.free()
	restored.free()
	edit_cases.append(label + ": growth, shrink, size, spacing, overrides, transforms, disk, detached, repair, empty")

func inspect_row_edit(row: Node3D, label: String) -> void:
	var count: int = row.get("bay_count")
	var bays := row.get_node("Bays")
	check(snapshot(bays).size() == count, label + ": exact bay count")
	var previous := AABB()
	var first := AABB()
	for index in range(count):
		var bay := bays.get_node("Bay%d" % index) as Node3D
		var shelf: Node3D = bay.get_node("Shelf") if bay.has_node("Shelf") else bay
		var box := local_bounds(shelf, row)
		check(box.size.distance_to(Vector3(1.6, 2.4, .44)) < EPS, label + ": imported shelf envelope")
		check(absf(box.position.y) < EPS, label + ": shelf floor datum")
		if index == 0:
			first = box
		else:
			check(absf(box.position.x - previous.end.x) < EPS, label + ": touching adjacent bays")
		previous = box
		if bay.has_node("Records"):
			inspect_population(bay, bay.scene_file_path == PACKED_BAY.resource_path, label + str(index))
	var left := local_bounds(row.get_node("CapLeft"), row)
	var right := local_bounds(row.get_node("CapRight"), row)
	check(absf(left.end.x - first.position.x) < EPS and absf(right.position.x - previous.end.x) < EPS, label + ": cap contacts")
	check(absf(left.position.x + right.end.x) < EPS, label + ": centered capped envelope")
	check(absf(row.get_node("LeftJoin").position.x - first.position.x) < EPS, label + ": left join marker")
	check(absf(row.get_node("RightJoin").position.x - previous.end.x) < EPS, label + ": right join marker")
	for side in ["Left", "Right"]:
		check(row.get_node("Cap" + side).scale.is_equal_approx(Vector3.ONE), label + ": cap without mirroring")

func verify_rows(scene: PackedScene) -> void:
	var row := scene.instantiate() as Node3D
	row.set("bay_count", 2)
	root.add_child(row)
	var bays := row.get_node("Bays") as Node3D
	var before := snapshot(bays)
	var caps := [row.get_node("CapLeft").get_instance_id(), row.get_node("CapRight").get_instance_id()]
	var bay0 := bays.get_node("Bay0") as Node3D
	var shelf: Node3D = bay0.get_node("Shelf") if bay0.has_node("Shelf") else bay0
	var light_id := shelf.get_node("Light0").get_instance_id()
	var addition := attach_sentinel(bay0, bay0)
	bay0.set_meta("editing_note", "retain shelf state")
	var container_addition := attach_sentinel(bays, row)
	for count in [2, 4, 3, 1, 2]:
		row.set("bay_count", count)
		retains(bays, before, ["Bay0"], "row count " + str(count))
		check(shelf.get_node("Light0").get_instance_id() == light_id, "Row resize retains shelf fixture")
		check(is_instance_valid(addition) and bay0.get_meta("editing_note") == "retain shelf state", "Row resize retains nested state")
		check(row.get_node("CapLeft").get_instance_id() == caps[0] and row.get_node("CapRight").get_instance_id() == caps[1], "Row resize retains both cap identities")
		inspect_row_edit(row, "row resize " + str(count))
	before = snapshot(bays)
	bays.transform = Transform3D(Basis(Vector3.UP, -.4), Vector3(-3, 2, 4))
	row.transform = Transform3D(Basis(Vector3.UP, .61), Vector3(8, 2, -6))
	row.set("bay_count", 2)
	retains(bays, before, ["Bay0", "Bay1"], "row transformed container")
	inspect_row_edit(row, "row transformed container")
	# A different bay scene deliberately replaces all generated bays, keeping caps.
	row.set("bay_scene", PACKED_BAY)
	check(snapshot(bays)["Bay0"] != before["Bay0"], "Template change replaces generated bay")
	check(row.get_node("CapLeft").get_instance_id() == caps[0], "Template change retains cap")
	check(is_instance_valid(container_addition), "Template change retains unrelated container addition")
	inspect_row_edit(row, "packed template")
	var neighbor_id := bays.get_node("Bay1").get_instance_id()
	bays.get_node("Bay0").free()
	row.set("bay_count", 2)
	check(snapshot(bays).size() == 2 and bays.get_node("Bay1").get_instance_id() == neighbor_id, "Deleted bay repaired without replacing neighbor")
	inspect_row_edit(row, "repaired packed template")
	var restored := disk_roundtrip(row, "editing_row_" + str(scene == POPULATED_ROW))
	inspect_row_edit(restored, "row disk reload")
	check(restored.has_node("Bays/UserAttachment"), "Row container addition serialized")
	before = snapshot(bays)
	root.remove_child(row)
	row.set("bay_count", 3)
	root.add_child(row)
	retains(bays, before, ["Bay0", "Bay1"], "row detached grow")
	inspect_row_edit(row, "row detached grow")
	row.free()
	restored.free()
	edit_cases.append("row " + str(scene == POPULATED_ROW) + ": retained bays/fixtures, cap joins, templates, transforms, disk, detached")

func verify_island_edits() -> void:
	var island := ISLAND.instantiate() as Node3D
	island.set("front_records_per_shelf", 3)
	island.set("back_records_per_shelf", 3)
	root.add_child(island)
	var front := island.get_node("FrontRow/Bays/Bay0/Records")
	var back := island.get_node("BackRow/Bays/Bay0/Records")
	var front_ids := snapshot(front)
	var back_ids := snapshot(back)
	for count in [4, 1, 2]:
		island.set("bay_count", count)
		retains(front, front_ids, record_names(3), "island front count")
		retains(back, back_ids, record_names(3), "island back count")
		inspect_island(island, "island retained resize " + str(count))
	island.set("front_record_gap", .15)
	island.set("front_pattern", PackedInt32Array([0, 2, 0]))
	retains(back, back_ids, record_names(3), "island opposite population")
	for tier in range(4):
		retains(front, front_ids, ["Record_%d_0" % tier, "Record_%d_2" % tier], "island mixed small/large")
	inspect_island(island, "island edited front only")
	island.free()
	edit_cases.append("island count changes retain both populations; front size/gap edits retain opposite face")

func verify() -> void:
	root.size = Vector2i(1000, 700)
	for path in RECORD_PATHS:
		var record := (load(path) as PackedScene).instantiate() as Node3D
		root.add_child(record)
		actual_widths.append(local_bounds(record, record).size.x)
		bounds(record, true)
		record.free()
	for scene in [FIXED_BAY, PACKED_BAY]:
		for size in range(3):
			verify_records(scene, size)
	for scene in [EDIT_ROW, POPULATED_ROW]:
		verify_rows(scene)
	verify_island_edits()
	await process_frame
	var review := (load(EDIT_OUT + "review_island.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var island := review.get_node("Island") as Node3D
	island.set("bay_count", 3)
	island.set("front_pattern", PackedInt32Array([0, 2, 0]))
	island.set("back_pattern", PackedInt32Array([2, 0, 2]))
	inspect_island(island, "visible edited island")
	for node in [island.get_node("FrontRow/Bays/Bay0/Shelf"), island.get_node("FrontRow/CapLeft")]:
		bounds(node, true)
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["front", Vector3(4, 3, 7)], ["rear", Vector3(-4, 3, -7)], ["end", Vector3(7, 2.8, .3)]]:
		camera.position = view[1]
		camera.look_at(Vector3(0, 1.2, 0))
		camera.size = 6.7
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(EDIT_OUT + "godot_" + view[0] + ".png") == OK, "Capture edited " + view[0])
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(),
		"passed": failures.is_empty(), "failures": failures, "issues": [28, 29, 31, 33],
		"editing_cases": edit_cases, "identity_checks": identity_checks, "shelf_cases": shelf_cases,
		"island_cases": island_cases, "support_probes": support_probes, "closed_back_probes": closed_back_probes,
		"validated_meshes": meshes,
		"mcp": "Blender status/scene and Godot get_state disconnected; standalone Godot fallback; existing model sources reused.",
		"scope": "Instance retention and imported fit after edits; live Inspector, final art, physics and performance unverified."}
	FileAccess.open(EDIT_OUT + "godot_validation.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("Archive editing: %d workflows, %d identity checks; passed=%s" % [edit_cases.size(), identity_checks, str(failures.is_empty())])
	quit(0 if failures.is_empty() else 1)
