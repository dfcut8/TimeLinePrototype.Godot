extends "res://assets/event_socket/verify_godot.gd"
## Static asset/assembly checks and actual GPU captures in an isolated project.

const INSERT_OUT := "res://assets/event_strip_insert/"
const ERA_OUT := "res://assets/era_label_tab/"
const PANEL := "Pivot/Model/Yaw/Pitch/PanelAttachment/Casing"

func vertex_bounds(node: Node3D) -> AABB:
	var points: Array[Vector3] = []
	for child in node.find_children("*","MeshInstance3D",true,false):
		var part := child as MeshInstance3D
		for surface in range(part.mesh.get_surface_count()):
			var vertices: PackedVector3Array = part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				points.append(node.to_local(part.to_global(vertex)))
	var bounds := AABB(points[0],Vector3.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds

func verify() -> void:
	var assembly := (load(INSERT_OUT + "review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	root.size = Vector2i(1100, 760)
	var insert := (load(INSERT_OUT + "event_strip_insert.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(insert)
	var box := inspect_meshes(insert, 156)
	check(box.position.is_equal_approx(Vector3(-.437,-.087,0)), "Insert seat/origin")
	# Godot pads planar surface AABBs by 10 micrometres; use vertices for exact fit.
	check(box.size.distance_to(Vector3(.874,.174,.003)) < .00002, "Insert render bounds")
	var insert_bounds := vertex_bounds(insert)
	check(insert_bounds.size.distance_to(Vector3(.874,.174,.003)) < .000001, "Insert vertex dimensions")
	var mesh_node := insert.find_child("BlankInsert*",true,false) as MeshInstance3D
	check(mesh_node.mesh.get_surface_count() == 2, "Separate presentation surface required")
	var front_surface := -1
	for s in range(mesh_node.mesh.get_surface_count()):
		if mesh_node.mesh.surface_get_material(s).resource_name.begins_with("presentation_dark"):
			front_surface = s
	check(front_surface >= 0, "Named replaceable presentation material")
	if front_surface >= 0:
		var max_uv_error := 0.0
		var arrays := mesh_node.mesh.surface_get_arrays(front_surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for i in range(vertices.size()):
			check(absf(vertices[i].z-.003) < .00001, "Presentation is front only")
			max_uv_error = maxf(max_uv_error,uvs[i].distance_to(Vector2(vertices[i].x/.873+.5,.5-vertices[i].y/.173)))
		check(max_uv_error < .000001, "Front UV orientation/continuity within absolute float tolerance: " + str(max_uv_error))
		var replacement := StandardMaterial3D.new()
		mesh_node.set_surface_override_material(front_surface,replacement)
		check(mesh_node.get_active_material(front_surface) == replacement, "Presentation slot replacement")
		mesh_node.set_surface_override_material(front_surface,null)
	insert.free()
	var era := (load(ERA_OUT + "era_label_tab.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(era)
	var era_box := inspect_meshes(era,404)
	check(era_box.position.is_equal_approx(Vector3(-.16,0,-.012)), "Era attachment origin")
	check(era_box.size.is_equal_approx(Vector3(.32,.155,.024)), "Era dimensions")
	check(era.get_node("LabelOrigin").position.is_equal_approx(Vector3(0,.12,.005)), "Live label clearance")
	era.free()
	var pose_samples := 0
	for label in ["Above","Below"]:
		var event := assembly.get_node(label) as Node3D
		var panel := event.get_node(PANEL) as Node3D
		var face := panel.get_node("Insert") as Node3D
		var face_bounds := vertex_bounds(face)
		var shell := panel.get_node("Casing").find_child("StripShell*",true,false) as MeshInstance3D
		var floor_points: Array[Vector3] = []
		for surface in range(shell.mesh.get_surface_count()):
			var shell_vertices: PackedVector3Array = shell.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in shell_vertices:
				if absf(vertex.z-.015) < .000001:
					floor_points.append(vertex)
		check(not floor_points.is_empty(), "Casing floor geometry found")
		var floor_bounds := AABB(floor_points[0],Vector3.ZERO)
		for point in floor_points:
			floor_bounds = floor_bounds.expand(point)
		check(face.position.is_equal_approx(Vector3(0,0,.015)), "Insert seats at casing recess floor")
		check(absf((floor_bounds.size.x-face_bounds.size.x)/2-.001) < .000001 and absf((floor_bounds.size.y-face_bounds.size.y)/2-.001) < .000001, "Measured one millimetre casing edge clearance")
		check(absf(face.position.z+face_bounds.position.z-floor_bounds.position.z) < .000001, "Measured rear seat contact")
		check(absf(vertex_bounds(panel.get_node("Casing")).end.z-(face.position.z+face_bounds.end.z)-.012) < .000001, "Measured 12 mm lip recess")
		check(face_bounds.size.x > .852 and face_bounds.size.y > .152, "Existing safe presentation rectangle fits")
		var pivot := event.get_node("Pivot") as Node3D
		for yaw in [-60.0,0.0,60.0]:
			for pitch in [-20.0,0.0,20.0]:
				pivot.set("yaw_degrees",yaw)
				pivot.set("pitch_degrees",pitch)
				check(panel.to_local(face.global_position).is_equal_approx(Vector3(0,0,.015)), "Insert follows articulated casing")
				pose_samples += 1
		pivot.set("yaw_degrees",0.0)
		pivot.set("pitch_degrees",0.0)
	var mounted_era := assembly.get_node("EraTab") as Node3D
	var rail_bounds := vertex_bounds(assembly.get_node("Housing"))
	check(absf(mounted_era.global_position.y-rail_bounds.end.y) < .000001, "Era seat meets measured rail top")
	check(mounted_era.global_position.z-.012 > -.046 and mounted_era.global_position.z+.012 < .046, "Seat on flat rail crown")
	# Static model clearances: tab is above the light and below neighboring records.
	var upper_panel := assembly.get_node("Above/" + PANEL) as Node3D
	var upper_bounds: AABB = upper_panel.global_transform * vertex_bounds(upper_panel)
	var tab_bounds: AABB = mounted_era.global_transform * vertex_bounds(mounted_era)
	check(tab_bounds.position.y > .020 and tab_bounds.end.y < upper_bounds.position.y, "Era does not hide light or upper record")
	await physics_frame
	await physics_frame
	var panel := assembly.get_node("Above/" + PANEL) as Node3D
	var query := PhysicsRayQueryParameters3D.create(panel.to_global(Vector3(0,0,1)),panel.to_global(Vector3(0,0,-1)),32)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := panel.get_world_3d().direct_space_state.intersect_ray(query)
	check(not hit.is_empty() and hit.get("collider") == panel.get_node("Casing/PickingProxy"), "Insert preserves casing selection")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	var views := [
		[INSERT_OUT,"assembly",Vector3(1,.1,3),Vector3(1,0,0),1.7],
		[INSERT_OUT,"front",Vector3(.70,.76,1.7),Vector3(.55,.658,.175),.7],
		[INSERT_OUT,"rear",Vector3(.80,.80,-1.2),Vector3(.55,.658,.175),.7],
		[INSERT_OUT,"side",Vector3(1.7,.70,.4),Vector3(.55,.658,.175),.65],
		[INSERT_OUT,"underside",Vector3(.75,.15,.8),Vector3(.55,.658,.175),.65],
		[ERA_OUT,"front",Vector3(1.23,.24,.6),Vector3(1.15,.15,0),.27],
		[ERA_OUT,"rear",Vector3(1.25,.24,-.6),Vector3(1.15,.15,0),.27],
		[ERA_OUT,"side",Vector3(1.8,.22,.06),Vector3(1.15,.15,0),.27],
		[ERA_OUT,"underside",Vector3(1.22,-.20,.5),Vector3(1.15,.15,0),.30],
		[ERA_OUT,"seat",Vector3(1.23,.14,.17),Vector3(1.15,.067,0),.085]]
	for view in views:
		camera.position = view[2]
		camera.look_at(view[3])
		camera.size = view[4]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(view[0]+"godot_"+view[1]+".png") == OK,"Capture saved")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"meshes":rows,"articulated_samples":pose_samples,
		"insert_edge_clearance_m":.001,"insert_front_recess_m":.012,"live_text_offset_m":.001,
		"mcp":"Both live connections unavailable; standalone Blender and isolated Godot fallback. Live MCP validation incomplete.",
		"scope":"Static models, imported geometry, presentation UV and material replacement, assembly fit and casing ray picking. Room/camera/readability validation remains future work."}
	for path in [INSERT_OUT,ERA_OUT]:
		var file := FileAccess.open(path+"godot_validation.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
