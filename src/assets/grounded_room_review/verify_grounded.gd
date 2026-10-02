extends "res://assets/furnished_room_review/verify_furnished.gd"
## Static imported-mesh fit checks; no physics or gameplay is introduced.
const GROUNDED_OUT := "res://assets/grounded_room_review/"
var grounding_stats: Dictionary = {}
var floor_triangles := PackedVector3Array()

func cache_floor(floor_node: Node3D, space: Node3D) -> void:
	floor_triangles.clear()
	for child in floor_node.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		var to_space := space.global_transform.affine_inverse() * mesh.global_transform
		for vertex in mesh.mesh.get_faces():
			floor_triangles.append(to_space * vertex)

func supported(point: Vector3) -> bool:
	# The delivered slab has a 2 mm chamfer at seams, not a through hole.
	var start := point + Vector3(0, .0001, 0)
	var end := point - Vector3(0, .0021, 0)
	for i in range(0, floor_triangles.size(), 3):
		if Geometry3D.segment_intersects_triangle(start, end, floor_triangles[i], floor_triangles[i+1], floor_triangles[i+2]) != null:
			return true
	return false

func inspect_grounding(room: Node3D) -> void:
	var floor_node := room.get_node("Floor") as Node3D
	var furnished := room.get_node("Furnishings") as Node3D
	var base := furnished.get_node("BaseRoom") as Node3D
	inspect_furnishings(furnished)
	check(floor_node.get_child_count() == 104, "100 slabs and four perimeter wedges")
	var floor_box := local_bounds(floor_node, room)
	check(absf(floor_box.end.y) < .0001 and absf(floor_box.position.y + .25) < .0001, "Floor thickness and deck datum")
	cache_floor(floor_node, room)
	check(supported(Vector3(2,0,2)), "Floor support positive control")
	check(not supported(Vector3(33,0,0)), "Outside floor negative control")
	check(not supported(Vector3(2,.01,2)), "Raised support negative control")
	var support_probes := 0
	var max_contact := 0.0
	# Mesh bounds are transformed back into the object's frame before choosing probes.
	var objects: Array[Node3D] = []
	for i in range(24):
		objects.append(base.get_node("Perimeter/Bay%d" % i))
		objects.append(base.get_node("Perimeter/Pier%d" % i))
	for i in range(8):
		objects.append(base.get_node("Shelves/Shelf%d/Shelf" % i))
	for object in objects:
		var box := local_bounds(object, object)
		var object_in_room := room.global_transform.affine_inverse() * object.global_transform
		max_contact = maxf(max_contact, absf((object_in_room * Vector3(0,box.position.y,0)).y))
		# Portal centers are open; support probes lie within both solid jambs.
		for fraction_x in [.02,.98]:
			for fraction_z in [.1,.9]:
				var point := object_in_room * Vector3(lerpf(box.position.x,box.end.x,fraction_x),box.position.y,lerpf(box.position.z,box.end.z,fraction_z))
				check(supported(point), "Floor below support " + str(object.get_path()))
				support_probes += 1
	check(max_contact < .0001, "Architecture and shelf base contact within 0.1 mm")
	var thresholds := 0
	for index in [0,12]:
		var portal := base.get_node("Perimeter/Bay%d" % index) as Node3D
		var portal_to_room := room.global_transform.affine_inverse() * portal.global_transform
		for x in [-1.49,-.75,0,.75,1.49]:
			for step in range(25):
				var z := -1.0 + step * .25
				check(supported(portal_to_room * Vector3(x,0,z)), "Continuous portal approach floor")
				thresholds += 1
			for y in [.001,1.7,3.399]:
				check(not segment_hits(portal,portal.to_global(Vector3(x,y,-1)),portal.to_global(Vector3(x,y,1))), "No portal threshold lip or blocked opening")
	var rail := base.get_node("Timeline") as Node3D
	var rail_box := local_bounds(rail, room)
	check(rail_box.position.y > 1.4, "Rail remains above finished floor")
	check(rail.get_node("Modules").get_child_count() == 7, "14 m rail retains seven unscaled modules")
	var rail_probes := 0
	for step in range(29):
		var point := Vector3(-7 + .5 * step,0,0)
		check(supported(point), "Floor covers rail projection")
		rail_probes += 1
	# Probe the floor's grid joins and wedge interfaces in all quadrants.
	var seam_probes := 0
	for seam in range(-20,21,4):
		for along in range(-19,20,2):
			for point in [Vector3(seam,0,along),Vector3(along,0,seam)]:
				check(supported(point + Vector3(.00001,0,.00001)) and supported(point - Vector3(.00001,0,.00001)), "Floor interface sides within 0.02 mm: " + str(point))
				seam_probes += 1
	grounding_stats = {"floor_modules":104,"support_objects":objects.size(),"support_probes":support_probes,
		"max_base_datum_error_m":max_contact,"portal_floor_probes":thresholds,"rail_projection_probes":rail_probes,
		"rail_floor_clearance_m":rail_box.position.y,"floor_seam_probes":seam_probes,"floor_triangles":floor_triangles.size()/3}

func verify() -> void:
	root.size = Vector2i(1280,900)
	var review := (load("res://assets/grounded_room_review/review_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(review)
	current_scene = review
	var room := review.get_node("Room") as Node3D
	for placement in [Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,.71),Vector3(8,2,-6))]:
		room.transform = placement
		inspect_grounding(room)
	room.transform = Transform3D.IDENTITY
	bounds(room.get_node("Floor/Tile_0_0"),true)
	bounds(room.get_node("Floor/Wedge0"),true)
	var camera := review.get_node("ReviewRig/Camera3D") as Camera3D
	for view in [["overview",Vector3(38,42,45),Vector3.ZERO,70.0],
		["portal",Vector3(0,2,-20),Vector3(0,1,-25),9.0],
		["shelf",Vector3(9,2,-16),Vector3(11.5,1,-19.9186),5.0],
		["rail",Vector3(10,6,12),Vector3(0,1,0),18.0]]:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL if view[0] == "overview" else Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 60.0
		camera.position = view[1]
		camera.look_at(view[2])
		camera.size = view[3]
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(GROUNDED_OUT+"godot_"+view[0]+".png") == OK,"GPU capture")
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),
		"passed":failures.is_empty(),"failures":failures,"grounding":grounding_stats,"room":stats,
		"furnishings":furnishing_stats,"placements_tested":2,"issues":[5,24,25,28],
		"mcp":"Blender status/scene and Godot get_state unavailable; standalone Godot fallback",
		"limits":"Static floor fit; no roof, physics, interactive camera, text readability, performance acceptance or art approval."}
	FileAccess.open(GROUNDED_OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
