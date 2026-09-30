extends SceneTree
## Standalone GPU fallback, importing the delivered GLBs and instanced scenes.
const OUT := "res://assets/roof_review/"
var failures: Array[String] = []
var surfaces: Array[Dictionary] = []
var seam_error := 0.0
var contact_error := 0.0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func points(node: Node3D, validate: bool = false) -> PackedVector3Array:
	var result := PackedVector3Array()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var instance := child as MeshInstance3D
		var mesh := instance.mesh
		for surface in range(mesh.get_surface_count()):
			var arrays := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				result.append(instance.global_transform * vertex)
			if not validate:
				continue
			var mat := mesh.surface_get_material(surface) as StandardMaterial3D
			check(mat != null and mat.roughness > .6 and mat.transparency == 0, "Opaque matte material")
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			check(normals.size() == vertices.size() and uvs.size() == vertices.size(), "Normals and UV0")
			for normal in normals:
				check(absf(normal.length()-1) < .001, "Unit normals")
			for i in range(0,indices.size(),3):
				var a := indices[i]
				var b := indices[i+1]
				var c := indices[i+2]
				var cross := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a])
				check(cross.length()>1e-10 and cross.dot(normals[a])<0,"Triangle winding and area")
				check(absf((uvs[b]-uvs[a]).cross(uvs[c]-uvs[a]))>1e-12,"UV area")
			surfaces.append({"mesh":str(child.name),"triangles":indices.size()/3,"material":mat.resource_name})
	return result

func capture(scene: Node3D, label: String, pos: Vector3, target: Vector3, size: float, perspective: bool = false) -> void:
	var camera := scene.get_node("ReviewRig/Camera3D") as Camera3D
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE if perspective else Camera3D.PROJECTION_ORTHOGONAL
	camera.position = pos
	camera.look_at(target)
	camera.size = size
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+"godot_"+label+".png")==OK,"Capture "+label)

func hit(node: Node3D, start: Vector3, end: Vector3) -> Variant:
	for child in node.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		var faces := mesh.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var point: Variant = Geometry3D.segment_intersects_triangle(start,end,mesh.global_transform*faces[i],mesh.global_transform*faces[i+1],mesh.global_transform*faces[i+2])
			if point != null:
				return point
	return null

func verify() -> void:
	root.size = Vector2i(1100,800)
	for name in ["oculus_curb_segment","radial_roof_beam"]:
		var single := (load(OUT+"review_"+name+".tscn") as PackedScene).instantiate() as Node3D
		root.add_child(single)
		current_scene = single
		var vertices := points(single.get_node("Asset"),true)
		var triangle_count := 0
		var surface_count := 0
		for surface in surfaces:
			if surface.mesh == name:
				triangle_count += int(surface.triangles)
				surface_count += 1
		check(triangle_count == (396 if name == "oculus_curb_segment" else 28),"Imported triangle count")
		check(surface_count == 2,"Two imported material surfaces")
		var low := vertices[0]
		var high := vertices[0]
		for vertex in vertices:
			low = low.min(vertex)
			high = high.max(vertex)
		if name == "radial_roof_beam":
			check((high-low).distance_to(Vector3(14.9,.55,.32))<.00001,"Beam dimensions")
		else:
			check(absf(high.y-.6)<.00001 and absf(low.y)<.00001,"Curb height and pivot")
			for vertex in vertices:
				check(Vector2(vertex.x,vertex.z).length()>=9.99999 and Vector2(vertex.x,vertex.z).length()<=10.60001,"Curb radii")
		var target := Vector3(10.3,.3,0) if name=="oculus_curb_segment" else Vector3(7.45,.275,0)
		var span := 4.3 if name=="oculus_curb_segment" else 17.0
		for view in [["front",Vector3(-.5,.4,1)],["rear",Vector3(.5,.4,-1)],["end",Vector3(1,.1,.2)],["underside",Vector3(-.4,-.6,1)]]:
			await capture(single,name+"_"+view[0],target+view[1]*span,target,span)
		single.queue_free()
		await process_frame
	var assembly := (load(OUT+"review_assembly.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(assembly)
	current_scene = assembly
	for i in range(24):
		var curb := assembly.get_node("Curb"+str(i)) as Node3D
		var next := assembly.get_node("Curb"+str((i+1)%24)) as Node3D
		var beam := assembly.get_node("Beam"+str(i)) as Node3D
		var pier := assembly.get_node("Pier"+str(i)) as Node3D
		var neighbor_points := points(next)
		var count := 0
		for vertex in points(curb):
			var local := curb.to_local(vertex)
			if absf(atan2(-local.z,local.x)-deg_to_rad(7.5))<.00001:
				var distance := INF
				for neighbor in neighbor_points:
					distance=minf(distance,vertex.distance_to(neighbor))
				seam_error=maxf(seam_error,distance)
				count+=1
		check(count>=8,"Sector seam found")
		# Probe actual triangles on each bearing surface, not only bounding boxes.
		for support in [[curb,.215],[pier,14.65]]:
			for dx in [-.10,0.0,.10]:
				for dz in [-.10,.10]:
					var pos := beam.to_global(Vector3(support[1]+dx,0,dz))
					var below: Variant = hit(support[0],pos+Vector3(0,.001,0),pos-Vector3(0,.01,0))
					var above: Variant = hit(beam,pos-Vector3(0,.001,0),pos+Vector3(0,.01,0))
					check(below!=null and above!=null,"Both bearing surfaces exist")
					if below!=null and above!=null:
						contact_error=maxf(contact_error,below.distance_to(above))
		var inner := beam.get_node("InnerBearing") as Marker3D
		check(inner.global_position.distance_to(curb.get_node("BeamBearing").global_position)<.00001,"Inner attachment markers")
		check(beam.get_node("OuterBearing").global_position.distance_to(pier.get_node("GalleryBearing").global_position)<.00001,"Outer attachment markers")
		# Beams occupy disjoint 15-degree sectors; the narrowest angular gap is at the inner end.
		for vertex in points(beam):
			var local := curb.to_local(vertex)
			check(absf(atan2(-local.z,local.x))<deg_to_rad(7.5),"Beam contained in own sector")
	check(seam_error<.00002,"Full ring seam closure")
	check(contact_error<.00002,"Bearing contact tolerance")
	check(hit(assembly,Vector3(0,20,0),Vector3(0,0,0))==null,"Open oculus")
	await capture(assembly,"assembly",Vector3(43,47,43),Vector3(0,12,0),67)
	await capture(assembly,"camera_height",Vector3(0,1.7,4),Vector3(15,14,0),50,true)
	await capture(assembly,"inner_bearing",Vector3(8,16,2),Vector3(10.4,14.8,0),2.5)
	await capture(assembly,"outer_bearing",Vector3(22,16,2),Vector3(24.8,14.7,0),2.5)
	var report := {"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"passed":failures.is_empty(),"failures":failures,"surfaces":surfaces,"ring_instances":24,"beam_instances":24,"seam_error_m":seam_error,"bearing_contact_error_m":contact_error,"bearing_ray_pairs":288,"open_oculus":true,"mcp":"Unavailable; standalone GPU validation","collision":"Decorative static models; no physics or animation","limits":"Full room scale, camera navigation and timeline readability pending"}
	FileAccess.open(OUT+"godot_validation.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
