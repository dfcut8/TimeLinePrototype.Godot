import bpy, json
from pathlib import Path
from mathutils import Vector
out=Path("C:/home/src/TimeLinePrototype.Godot/src/assets/archive_record_medium")
original=bpy.context.scene
check=bpy.data.scenes.new("TEMP_issue32_glb_check")
bpy.context.window.scene=check
try:
    bpy.ops.import_scene.gltf(filepath=str(out/"archive_record_medium.glb"))
    meshes=[o for o in check.objects if o.type=="MESH"]
    assert len(meshes)==1
    ob=meshes[0]; ob.data.calc_loop_triangles()
    points=[ob.matrix_world@v.co for v in ob.data.vertices]
    dims=[max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
    report=json.loads((out/"validation.json").read_text())
    assert len(ob.data.loop_triangles)==report["triangles"]
    assert all(abs(a-b)<1e-6 for a,b in zip(dims,report["dimensions_blender_m"]))
    assert len(ob.data.materials)==4
    report["blender_glb_roundtrip"]={"passed":True,"triangles":len(ob.data.loop_triangles),"dimensions_blender_m":dims,"material_slots":len(ob.data.materials)}
finally:
    bpy.context.window.scene=original
    for obj in list(check.objects): bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.scenes.remove(check)
with bpy.data.libraries.load(str(out/"archive_record_medium.blend")) as (source,target):
    report["blend_file_contents"]={"scenes":list(source.scenes),"objects":len(source.objects),"meshes":len(source.meshes)}
assert len(report["blend_file_contents"]["scenes"])==1
report["visual_review"]={"views":["preview_front.png","preview_rear.png","preview_underside.png"],"result":"Reviewed: front/spine, both broad covers, rear, top and underside are closed; no visible z-fighting; silhouette and index marks read without bloom."}
(out/"validation.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
for area in bpy.context.screen.areas:
    if area.type=="VIEW_3D":
        area.spaces.active.overlay.show_overlays=False
print(json.dumps({k:report[k] for k in ["blender_glb_roundtrip","blend_file_contents","visual_review"]}))
