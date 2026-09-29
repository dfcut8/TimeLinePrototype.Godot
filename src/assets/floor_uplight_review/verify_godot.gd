extends SceneTree
## Imported mesh and actual triangle fit checks; GPU captures in the local fallback.
const OUT := "res://assets/floor_uplight_review/"
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func meshes(node: Node) -> Array[Node]:
	return node.find_children("*", "MeshInstance3D", true, false)

func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for item: MeshInstance3D in meshes(node):
		var box := item.global_transform * item.mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func hits(node: Node3D, start: Vector3, end: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for item: MeshInstance3D in meshes(node):
		var faces := item.mesh.get_faces()
		for i in range(0, faces.size(), 3):
			var point: Variant = Geometry3D.segment_intersects_triangle(item.to_local(start),item.to_local(end),faces[i],faces[i+1],faces[i+2])
			if point != null:
				result.append(item.to_global(point))
	return result

func validate(node: Node3D, expected: Vector3, count: int, slots: int) -> void:
	var box := bounds(node)
	check(box.size.is_equal_approx(expected),str(node.name)+" dimensions: "+str(box))
	var triangles := 0
	var surfaces := 0
	var emission_count := 0
	for item: MeshInstance3D in meshes(node):
		check(item.transform.is_equal_approx(Transform3D.IDENTITY),"Identity mesh transform")
		for surface in range(item.mesh.get_surface_count()):
			surfaces += 1
			var mat := item.mesh.surface_get_material(surface) as StandardMaterial3D
			check(mat != null and mat.roughness > .6,"Matte PBR material")
			check(mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED,"Opaque material")
			var expected_material := "archive_basalt_ceramic" if slots==1 else ("archive_warm_diffuser" if item.name=="EmissionInsert" else "archive_graphite")
			check(mat.resource_name==expected_material,"Correct imported palette: "+expected_material)
			if mat.emission_enabled:
				emission_count += 1
				check(item.name=="EmissionInsert","Separate emission region")
			var arrays := item.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += indices.size()/3
			check(normals.size()==vertices.size() and uvs.size()==vertices.size(),"UV0 and normals")
			for n in normals:
				check(n.is_finite() and absf(n.length()-1)<.01,"Finite unit normal")
			for uv in uvs:
				check(uv.is_finite(),"Finite UV")
			for i in range(0,indices.size(),3):
				var a := indices[i]
				var b := indices[i+1]
				var c := indices[i+2]
				var cross := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
				check(cross.length()>1e-12 and cross.dot(normals[a])<0,"Clockwise nondegenerate triangle")
	check(triangles==count and surfaces==slots,"Expected mesh budget")
	check(emission_count==(1 if slots==2 else 0),"Expected emission material count")
	rows.append({"name":node.name,"bounds":str(box),"triangles":triangles,"surfaces":surfaces,"emission_surfaces":emission_count})

func capture(camera: Camera3D, label: String, eye: Vector3, target: Vector3, size: float) -> void:
	camera.position=eye
	camera.look_at(target)
	camera.size=size
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"godot_"+label+".png")==OK,"GPU screenshot")

func verify() -> void:
	root.size=Vector2i(1000,750)
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene=assembly
	var floor_tile := assembly.get_node("Floor00") as Node3D
	var fixture := assembly.get_node("Uplight") as Node3D
	var pier := assembly.get_node("Pier") as Node3D
	validate(floor_tile,Vector3(4,.25,4),20,1)
	validate(fixture,Vector3(.232,.14,.108),40,2)
	check(absf(bounds(floor_tile).end.y)<.000001,"Deck at zero")
	# Adjacent volume boundaries meet; their shallow chamfers have solid bottoms.
	for pair in [["Floor00","Floor10",0],["Floor01","Floor11",0],["Floor00","Floor01",2],["Floor10","Floor11",2]]:
		var a := bounds(assembly.get_node(pair[0]))
		var b := bounds(assembly.get_node(pair[1]))
		check(absf(a.end[pair[2]]-b.position[pair[2]])<.000001,"Flush tile boundary")
	for x: float in [1.997,1.999,2.0,2.001,2.003]:
		for z: float in [.13,1.999,2.001,3.87]:
			var points: Array[Vector3] = []
			for name in ["Floor00","Floor10","Floor01","Floor11"]:
				points.append_array(hits(assembly.get_node(name),Vector3(x,.1,z),Vector3(x,-.01,z)))
			check(not points.is_empty(),"No through hole at tile joint")
			for point in points:
				check(point.y>=-.00201 and point.y<=.000001,"Joint depth limited to chamfer")
	var fb := bounds(fixture)
	check(fb.position.x>-.12 and fb.end.x<.12 and fb.position.y>.31 and fb.end.y<.47 and fb.position.z>.18 and fb.end.z<.30,"Housing inside reserved pocket, positive clearance")
	# Rays to the existing pier's actual pocket back prove the receiver depth.
	for x: float in [-.115,0,.115]:
		for y: float in [.322,.39,.458]:
			var points := hits(pier,Vector3(x,y,.301),Vector3(x,y,.17))
			check(not points.is_empty(),"Pier pocket back")
			for point in points:
				check(absf(point.z-.18)<.00001,"No pier face clips the inserted housing")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	await capture(camera,"assembly",Vector3(10,9,13),Vector3(2,1,2),12)
	await capture(camera,"pocket",Vector3(.32,.62,.9),Vector3(0,.39,.24),.52)
	pier.visible=false
	for name in ["Floor00","Floor10","Floor01","Floor11"]:
		(assembly.get_node(name) as Node3D).visible=false
	await capture(camera,"fixture_front",Vector3(.35,.60,.9),fixture.position+Vector3(0,0,.054),.34)
	await capture(camera,"fixture_rear",Vector3(-.35,.50,-.5),fixture.position+Vector3(0,0,.054),.34)
	await capture(camera,"fixture_underside",Vector3(.35,.05,.9),fixture.position+Vector3(0,0,.054),.34)
	fixture.visible=false
	for name in ["Floor00","Floor10","Floor01","Floor11"]:
		(assembly.get_node(name) as Node3D).visible=true
	await capture(camera,"floor_top",Vector3(9,11,10),Vector3(2,0,2),11)
	await capture(camera,"floor_underside",Vector3(9,-9,10),Vector3(2,-.125,2),11)
	await capture(camera,"floor_seam",Vector3(2.6,.7,2.9),Vector3(2,0,2),1.4)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"meshes":rows,"joint_ray_probes":20,"pocket_ray_probes":9,"mcp":"Unavailable; CLI GPU fallback","collision_animation":"Not applicable to static art delivery"}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
