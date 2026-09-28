extends SceneTree
## Actual imported geometry checks and GPU captures, run by verify_godot.ps1.

const OUT := "res://assets/structural_pier_family/"
var failures: Array[String] = []
var rows: Array[Dictionary] = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func mesh_of(node: Node3D) -> MeshInstance3D:
	var meshes := node.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 1, "One mesh per object")
	return meshes[0] as MeshInstance3D

func hits(mesh_node: MeshInstance3D, start: Vector3, end: Vector3) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var faces := mesh_node.mesh.get_faces()
	var a := mesh_node.to_local(start)
	var b := mesh_node.to_local(end)
	for i in range(0, faces.size(), 3):
		var point: Variant = Geometry3D.segment_intersects_triangle(a, b, faces[i], faces[i+1], faces[i+2])
		if point != null:
			result.append(mesh_node.to_global(point))
	return result

func validate_pier(pier: Node3D, width: float) -> void:
	var instance := mesh_of(pier)
	var mesh := instance.mesh
	var bounds := mesh.get_aabb()
	check(bounds.size.is_equal_approx(Vector3(width+.1,4.75,.8)), "Pier dimensions: " + str(bounds))
	check(absf(bounds.position.y)<.00001, "Floor pivot")
	check(instance.transform.is_equal_approx(Transform3D.IDENTITY), "Identity model transform")
	check(mesh.get_surface_count()==2, "Two material surfaces")
	var triangles := 0
	var materials: Array[String] = []
	for surface in range(mesh.get_surface_count()):
		var mat := mesh.surface_get_material(surface) as StandardMaterial3D
		check(mat != null, "PBR material")
		check(mat.roughness>.6 and not mat.emission_enabled, "Matte non-emissive finish")
		check(mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED, "Opaque finish")
		materials.append(mat.resource_name)
		var data := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = data[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
		triangles += indices.size()/3
		check(normals.size()==vertices.size() and uvs.size()==vertices.size(), "Normals and UV0")
		for normal in normals:
			check(normal.is_finite() and absf(normal.length()-1)<.01, "Unit normals")
		for uv in uvs:
			check(uv.is_finite(), "Finite UVs")
		for i in range(0,indices.size(),3):
			var a := indices[i]
			var b := indices[i+1]
			var c := indices[i+2]
			var cross := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
			check(cross.length()>1e-10 and cross.dot(normals[a])<0, "Nondegenerate clockwise Godot triangles")
	check(triangles==76, "Expected exported triangle count")
	var pocket_hits := hits(instance, pier.to_global(Vector3(0,.39,.4)),pier.to_global(Vector3(0,.39,.1)))
	check(not pocket_hits.is_empty(), "Blind pocket back exists")
	for point in pocket_hits:
		check(absf(pier.to_local(point).z-.18)<.00001, "Pocket is open to its .12 m recess depth")
	for local_point in [Vector3.ZERO,Vector3(width/3,0,.15)]:
		var end_hits := hits(instance,pier.to_global(local_point-Vector3(0,.01,0)),pier.to_global(local_point+Vector3(0,4.76,0)))
		check(end_hits.size()>=2, "Bottom and top closures")
	check((pier.get_node("GalleryBearing") as Node3D).position==Vector3(0,4.75,0), "Bearing marker")
	rows.append({"name":pier.name,"bounds":str(bounds),"triangles":triangles,"materials":materials})

func capture(camera: Camera3D, label: String, position: Vector3, target: Vector3, size: float) -> void:
	camera.position=position
	camera.look_at(target)
	camera.size=size
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"godot_"+label+".png")==OK,"GPU capture")

func verify() -> void:
	root.size=Vector2i(1100,800)
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene=assembly
	var pier_a := assembly.get_node("PierA") as Node3D
	var pier_b := assembly.get_node("PierB") as Node3D
	validate_pier(pier_a,.8)
	validate_pier(pier_b,.4)
	var support_probes := 0
	# Test the reserved .3 m tangential x .4 m radial bearing rectangle
	# against actual triangles on both sides of each gallery seam.
	for pier in [pier_a,pier_b]:
		for x: float in [-.15,.15]:
			for z: float in [-.2,.2]:
				var point: Vector3 = pier.to_global(Vector3(x,4.75,z))
				var found := false
				for gallery_name in ["GalleryLeft","GalleryMiddle","GalleryRight"]:
					var gallery := mesh_of(assembly.get_node(gallery_name))
					for hit in hits(gallery,point-Vector3(0,.01,0),point+Vector3(0,.01,0)):
						found = found or absf(hit.y-4.75)<.00001
				check(found,"Gallery bearing contact at " + str(point))
				support_probes+=1
		check(Vector2(pier.position.x,pier.position.z).length()-.5>20,"Outside central clear volume")
		var upper := assembly.get_node(str(pier.name)+"Upper") as Node3D
		check(upper.position.is_equal_approx((pier.get_node("NextTier") as Node3D).global_position),"5 m tier pitch")
		check(absf(upper.position.y-5)<.00001,"Upper foot meets gallery deck")
	var camera := assembly.get_node("ReviewRig/Camera3D") as Camera3D
	await capture(camera,"assembly",Vector3(12,9,12),Vector3(24,4.5,-3),17)
	await capture(camera,"bearing",Vector3(22,4.1,2),Vector3(24.8,4.75,0),2)
	# Reuse the authored object scenes for the clean family inspection.
	for label in ["GalleryLeft","GalleryMiddle","GalleryRight","PierAUpper","PierBUpper"]:
		(assembly.get_node(label) as Node3D).visible=false
	pier_a.position=Vector3(-.85,0,0)
	pier_b.position=Vector3(.85,0,0)
	pier_a.rotation=Vector3.ZERO
	pier_b.rotation=Vector3.ZERO
	await capture(camera,"front",Vector3(5,4,10),Vector3(0,2.375,0),6)
	await capture(camera,"rear",Vector3(-5,4,-10),Vector3(0,2.375,0),6)
	await capture(camera,"underside",Vector3(4,-5,9),Vector3(0,2,0),6)
	await capture(camera,"top",Vector3(3,10,6),Vector3(0,2.375,0),6)
	await capture(camera,"pocket",Vector3(-.55,.65,1),Vector3(-.85,.36,.15),.75)
	var report := {"engine":Engine.get_version_info().string,
		"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),
		"failures":failures,"meshes":rows,"bearing_triangle_probes":support_probes,
		"tier_pitch_m":5,"gallery_thickness_m":.25,
		"mcp":"Unavailable; isolated local Godot CLI and GPU rendering",
		"physics_animation":"Not applicable: static model review; no collision or animation supplied"}
	var file := FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
