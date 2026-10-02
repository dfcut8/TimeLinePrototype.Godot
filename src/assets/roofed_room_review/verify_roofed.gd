extends "res://assets/grounded_room_review/verify_grounded.gd"
## Imported geometry checks in the complete single-storey fit study.
const ROOFED_OUT := "res://assets/roofed_room_review/"
var roof_stats: Dictionary = {}

func vertices_in(node: Node3D, space: Node3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var transform_to_space := space.global_transform.affine_inverse() * mesh.global_transform
		# Use surface vertices for sub-millimetre seams; get_faces() goes through
		# TriangleMesh and may weld nearby positions for intersection queries.
		for surface in range(mesh.mesh.get_surface_count()):
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				result.append(transform_to_space * vertex)
	return result

func surface_hit(node: Node3D, start: Vector3, end: Vector3) -> Variant:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var faces := mesh.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var point: Variant = Geometry3D.segment_intersects_triangle(start, end,
				mesh.global_transform * faces[i], mesh.global_transform * faces[i+1], mesh.global_transform * faces[i+2])
			if point != null:
				return point
	return null

func inspect_roofed(room: Node3D) -> void:
	var grounded := room.get_node("GroundedRoom") as Node3D
	var base := grounded.get_node("Furnishings/BaseRoom") as Node3D
	var roof := room.get_node("RoofFrame") as Node3D
	inspect_grounding(grounded)
	check(roof.get_child_count() == 48, "24 beams and 24 curb sectors without duplicate piers")
	var seam_error := 0.0
	var bearing_error := 0.0
	var marker_error := 0.0
	var paired_probes := 0
	for i in range(24):
		var curb := roof.get_node("Curb%d" % i) as Node3D
		var next_curb := roof.get_node("Curb%d" % ((i+23)%24)) as Node3D
		var beam := roof.get_node("Beam%d" % i) as Node3D
		var pier := base.get_node("Perimeter/Pier%d" % i) as Node3D
		check(curb.scale.is_equal_approx(Vector3.ONE) and beam.scale.is_equal_approx(Vector3.ONE), "Unscaled roof components")
		var neighbor_vertices := vertices_in(next_curb, curb)
		var seam_vertices := 0
		for vertex in vertices_in(curb, curb):
			if absf(atan2(-vertex.z, vertex.x)-deg_to_rad(7.5)) < .00001:
				var distance := INF
				for neighbor in neighbor_vertices:
					distance = minf(distance, vertex.distance_to(neighbor))
				seam_error = maxf(seam_error, distance)
				seam_vertices += 1
		check(seam_vertices >= 8, "Curb seam vertices present, including closing seam")
		for vertex in vertices_in(beam, curb):
			check(absf(atan2(-vertex.z, vertex.x)) < deg_to_rad(7.5), "Beam stays in its own sector")
		for pair in [["InnerBearing", curb, "BeamBearing"], ["OuterBearing", pier, "GalleryBearing"]]:
			var first := beam.get_node(pair[0]) as Marker3D
			var second := (pair[1] as Node3D).get_node(pair[2]) as Marker3D
			marker_error = maxf(marker_error, first.global_position.distance_to(second.global_position))
		for support in [[curb, .215], [pier, 14.65]]:
			for dx in [-.1, 0.0, .1]:
				for dz in [-.1, .1]:
					var point := beam.to_global(Vector3(support[1]+dx, 0, dz))
					var up := room.global_basis.y.normalized()
					var below: Variant = surface_hit(support[0], point+up*.001, point-up*.01)
					var above: Variant = surface_hit(beam, point-up*.001, point+up*.01)
					check(below != null and above != null, "Both actual bearing surfaces present")
					if below != null and above != null:
						bearing_error = maxf(bearing_error, below.distance_to(above))
					paired_probes += 1
	check(seam_error < .00003 and bearing_error < .00003 and marker_error < .00003, "Roof contacts within 0.03 mm")
	var roof_box := local_bounds(roof, room)
	check(absf(roof_box.position.y-4.15) < .0001 and absf(roof_box.end.y-5.3) < .0001, "Single-storey roof frame height")
	var min_wall_clearance := INF
	for i in range(24):
		var bay := base.get_node("Perimeter/Bay%d" % i) as Node3D
		var bay_box := local_bounds(bay, bay)
		for piece in roof.get_children():
			var piece_box := local_bounds(piece, bay)
			# Curb is wholly inside the room. Beams may meet the header plane but cannot penetrate it.
			check(not piece_box.intersects(bay_box), "Roof does not penetrate wall/window/portal")
			if str(piece.name).begins_with("Beam"):
				min_wall_clearance = minf(min_wall_clearance, piece_box.position.y-bay_box.end.y)
	for index in [0,12]:
		var portal := base.get_node("Perimeter/Bay%d" % index) as Node3D
		for piece in roof.get_children():
			check(not local_bounds(piece,portal).intersects(AABB(Vector3(-1.5,0,-1),Vector3(3,3.4,6))), "Roof leaves portal approach clear")
	var shelf_clearance := INF
	for shelf in base.get_node("Shelves").get_children():
		var shelf_box := local_bounds(shelf, room)
		shelf_clearance = minf(shelf_clearance, roof_box.position.y-shelf_box.end.y)
	check(shelf_clearance > 1.0, "All 448 cassettes and their shelves clear lowest roof plane")
	check(surface_hit(roof,room.to_global(Vector3(0,6,0)),room.to_global(Vector3(0,0,0))) == null, "Oculus remains open")
	# Positive control proves the same triangle query detects the actual curb.
	var curb0 := roof.get_node("Curb0") as Node3D
	check(surface_hit(roof,curb0.to_global(Vector3(10.3,2,0)),curb0.to_global(Vector3(10.3,-1,0))) != null, "Curb ray positive control")
	roof_stats = {"beam_count":24,"curb_count":24,"bearing_ray_pairs":paired_probes,
		"max_seam_error_m":seam_error,"max_bearing_error_m":bearing_error,"max_marker_error_m":marker_error,
		"minimum_beam_header_vertical_clearance_m":min_wall_clearance,
		"conservative_populated_shelf_roof_clearance_m":shelf_clearance,"oculus_open":true,
		"roof_underside_m":roof_box.position.y,"roof_top_m":roof_box.end.y}

func envelope_clearance(point: Vector3, boxes: Array[AABB]) -> float:
	var clearance := INF
	for box in boxes:
		var nearest := Vector3(clampf(point.x,box.position.x,box.end.x),clampf(point.y,box.position.y,box.end.y),clampf(point.z,box.position.z,box.end.z))
		clearance = minf(clearance,point.distance_to(nearest)-.3)
	return clearance

func verify() -> void:
	root.size = Vector2i(1280,900)
	var review := (load("res://assets/roofed_room_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	var placement_reports: Array[Dictionary] = []
	for placement in [Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))]:
		room.transform = placement
		inspect_roofed(room)
		placement_reports.append(roof_stats.duplicate(true))
	room.transform = Transform3D.IDENTITY
	for path in ["RoofFrame/Curb0","RoofFrame/Beam0"]:
		bounds(room.get_node(path),true)
	var boxes: Array[AABB] = []
	for child in room.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		boxes.append((room.global_transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb())
	var min_camera_clearance := INF
	var samples := 0
	for radius in [9.0,10.3,12.0,16.0,19.0]:
		for height in [1.8,3.5]:
			for degrees in range(0,360,5):
				var angle := deg_to_rad(float(degrees))
				min_camera_clearance = minf(min_camera_clearance,envelope_clearance(Vector3(radius*sin(angle),height,-radius*cos(angle)),boxes))
				samples += 1
	check(min_camera_clearance > 0,"Camera envelope clears floor, roof, rail and furnishings")
	var curb := room.get_node("RoofFrame/Curb0") as Node3D
	check(envelope_clearance(room.to_local(curb.to_global(Vector3(10.3,.3,0))),boxes) < 0,"Reject camera inside curb")
	check(envelope_clearance(Vector3(2,.1,2),boxes) < 0,"Reject camera intersecting floor")
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	var base := room.get_node("GroundedRoom/Furnishings/BaseRoom") as Node3D
	var small := base.get_node("Shelves/Shelf0") as Node3D
	var large := base.get_node("Shelves/Shelf1") as Node3D
	var beam := room.get_node("RoofFrame/Beam0") as Node3D
	for view in [["overview",Vector3(38,42,45),Vector3(0,1,0)],
		["portal",Vector3(0,1.8,-19),Vector3(0,3,-24.6)],
		["small_shelf",small.to_global(Vector3(2,1.7,4)),small.to_global(Vector3(0,2,0))],
		["large_shelf",large.to_global(Vector3(2,1.7,4)),large.to_global(Vector3(0,2,0))],
		["bearing",beam.to_global(Vector3(12.5,1.5,2)),beam.to_global(Vector3(14.65,0,0))],
		["interior",Vector3(0,1.8,8),Vector3(0,3.6,-12)]]:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL if view[0] == "overview" else Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 65
		camera.size = 70
		camera.position = view[1]
		camera.look_at(view[2])
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(ROOFED_OUT+"godot_"+view[0]+".png") == OK,"GPU capture")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"issues":[24,25,31,33],"roof_placements":placement_reports,
		"grounding":grounding_stats,"room":stats,"furnishings":furnishing_stats,"validated_meshes":meshes,
		"camera_samples":samples,"camera_heights_m":[1.8,3.5],"camera_envelope_radius_m":.3,"min_camera_clearance_m":min_camera_clearance,
		"mcp":"Blender status/scene and Godot state unavailable; standalone Godot fallback",
		"limits":"Single-storey open roof frame fit study; no roof panels, structural engineering, physics, interactive camera, text readability, art approval or performance acceptance."}
	FileAccess.open(ROOFED_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
