"""Export and inspect the active cassette scene. Execute after build_asset.py."""
import bpy, bmesh, json, hashlib, struct, math
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent
NAME="archive_record_medium"
scene=bpy.context.scene
asset=next(c for c in scene.collection.children if c.name.startswith("ASSET_"))
root=next(o for o in asset.objects if o.type=="EMPTY")
parts=[o for o in asset.objects if o.type=="MESH"]
report={"blender_version":bpy.app.version_string,"issue":32,"godot_import":"NOT RUN: explicitly deferred by user","parts":[]}
points=[]
for ob in parts:
    mesh=ob.data; mesh.calc_loop_triangles()
    bm=bmesh.new(); bm.from_mesh(mesh)
    row={"name":ob.name,"triangles":len(mesh.loop_triangles),"non_manifold_edges":sum(not e.is_manifold for e in bm.edges),
         "degenerate_faces":sum(f.calc_area()<1e-12 for f in bm.faces),"signed_volume_m3":bm.calc_volume(signed=True),
         "uv_layers":len(mesh.uv_layers),"identity_transform":all(abs(v)<1e-7 for v in ob.location) and all(abs(v-1)<1e-7 for v in ob.scale) and all(abs(v)<1e-7 for v in ob.rotation_euler)}
    assert row["non_manifold_edges"]==0 and row["degenerate_faces"]==0 and row["signed_volume_m3"]>0 and row["uv_layers"]>0 and row["identity_transform"],row
    bm.free();report["parts"].append(row)
    points.extend(ob.matrix_world @ v.co for v in mesh.vertices)
lo=[min(p[i] for p in points) for i in range(3)]
hi=[max(p[i] for p in points) for i in range(3)]
report["bounds_blender_m"]={"min":lo,"max":hi}
report["dimensions_blender_m"]=[hi[i]-lo[i] for i in range(3)]
report["triangles"]=sum(p["triangles"] for p in report["parts"])
report["material_count"]=len({m.name for o in parts for m in o.data.materials})
report["provisional_shelf_opening_m"]={"width_per_record":.105,"depth":.30,"height":.44}
report["clearance_m"]={"side_each":(.105-report["dimensions_blender_m"][0])/2,"depth_total":.30-report["dimensions_blender_m"][1],"above":.44-hi[2]}
assert all(x>0 for x in report["clearance_m"].values())
# Export a merged copy for four material surfaces, preserving editable parts.
for ob in scene.objects: ob.select_set(False)
copies=[]
for ob in parts:
    c=ob.copy();c.data=ob.data.copy();c.parent=None;scene.collection.objects.link(c);c.select_set(True);copies.append(c)
bpy.context.view_layer.objects.active=copies[0]
bpy.ops.object.join()
export_ob=bpy.context.object
export_ob.name="archive_record_medium_mesh"
# Deduplicate slots after joining.
mats=list(dict.fromkeys(export_ob.data.materials))
mapping=[mats.index(m) for m in export_ob.data.materials]
indices=[mapping[p.material_index] for p in export_ob.data.polygons]
export_ob.data.materials.clear()
for m in mats:export_ob.data.materials.append(m)
for p,idx in zip(export_ob.data.polygons,indices):p.material_index=idx
export_ob["issue"]=root["issue"]
# Default exporter format is binary; inspect actual header below.
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+".glb")),use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_extras=True,export_yup=True)
bpy.data.objects.remove(export_ob,do_unlink=True)
data=(OUT/(NAME+".glb")).read_bytes()
magic,version,length=struct.unpack_from("<4sII",data)
assert magic==b"glTF" and version==2 and length==len(data)
chunk_len,chunk_type=struct.unpack_from("<I4s",data,12)
assert chunk_type==b"JSON"
gltf=json.loads(data[20:20+chunk_len])
assert len(gltf["meshes"])==1 and len(gltf["materials"])==4
assert not gltf.get("images") and not gltf.get("cameras") and not gltf.get("animations")
export_triangles=sum(gltf["accessors"][p["indices"]]["count"]//3 for m in gltf["meshes"] for p in m["primitives"])
assert export_triangles==report["triangles"]
for mesh in gltf["meshes"]:
    for p in mesh["primitives"]:
        assert "NORMAL" in p["attributes"] and "TEXCOORD_0" in p["attributes"]
report["glb"]={"magic":magic.decode(),"version":version,"bytes":len(data),"meshes":1,"material_surfaces":len(gltf["meshes"][0]["primitives"]),"triangles":export_triangles,"sha256":hashlib.sha256(data).hexdigest(),"external_dependencies":[]}
report["materials"]=[{"name":m["name"],"pbr":m["pbrMetallicRoughness"]} for m in gltf["materials"]]
(OUT/"validation.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
# Library write includes this scene and its dependencies only, preserving the user's scene.
bpy.data.libraries.write(str(OUT/(NAME+".blend")),{scene},fake_user=True,compress=True)
print(json.dumps(report,indent=2))
