"""Original cassette geometry for issue #32. Run in Blender's Scripting workspace.
Creates a new scene without deleting existing user work. Outputs beside this script.
Only MEDIUM is built; other family dimensions are interface proposals.
"""
import bpy, bmesh, json, math
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
NAME = "archive_record_medium"
FAMILY = {"small": (0.065, 0.22, 0.32), "medium": (0.085, 0.27, 0.40), "large": (0.105, 0.32, 0.48)}
W, D, H = FAMILY["medium"]
scene = bpy.data.scenes.new("Archive_Record_Medium_Review")
bpy.context.window.scene = scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
asset = bpy.data.collections.new("ASSET_archive_record_medium")
scene.collection.children.link(asset)
studio = bpy.data.collections.new("REVIEW_ONLY_studio")
scene.collection.children.link(studio)
root = bpy.data.objects.new(NAME, None)
asset.objects.link(root)
root["issue"] = "https://github.com/dfcut8/TimeLinePrototype.Godot/issues/32"
root["pivot"] = "Bottom center; Blender +Z up, -Y spine front; glTF +Y up, +Z spine front"
root["dimensions_m"] = [W,D,H]
root["status"] = "Model review; Godot import and actual shelf fit deferred"
parts = []
def material(name, color, roughness, metallic=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    p.inputs["Base Color"].default_value = (*color,1)
    p.inputs["Roughness"].default_value = roughness
    p.inputs["Metallic"].default_value = metallic
    m.diffuse_color = (*color,1)
    return m
graphite = material("archive_graphite",(.048,.060,.073),.68,.22)
ceramic = material("archive_basalt_ceramic",(.085,.103,.117),.81)
panel = material("archive_dark_panel",(.018,.026,.033),.76)
index = material("archive_neutral_index",(.40,.43,.42),.62,.12)
def box(name, size, center, mat, bevel=.001, collection=asset):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm,size=1)
    for v in bm.verts:
        v.co = Vector((v.co.x*size[0],v.co.y*size[1],v.co.z*size[2])) + Vector(center)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(mesh); bm.free()
    ob = bpy.data.objects.new(name,mesh)
    collection.objects.link(ob)
    mesh.materials.append(mat)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    if bevel:
        mod = ob.modifiers.new("Manufactured edge radius","BEVEL")
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Hard planar faces and real bevel facets; portable normals without shader tricks.
    for p in mesh.polygons: p.use_smooth = False
    if collection == asset:
        ob.parent = root
        parts.append(ob)
    ob.select_set(False)
    return ob
# Closed core with intentional protected cover insets, all surfaces finished.
box("cassette_closed_chassis",(W-.010,D,H),(0,0,H/2),graphite,.004)
for sign, side in [(-1,"left"),(1,"right")]:
    box("ceramic_cover_"+side,(.008,D-.018,H-.020),(sign*(W/2-.004),.001,H/2),ceramic,.003)
    box("cover_inset_"+side,(.0015,D-.050,H-.072),(sign*(W/2-.00045),.004,H/2-.007),panel,.0006)
    # Two understated geometric index strokes per broad face; no glyphs or text.
    for k,length in enumerate([.042,.025]):
        box("cover_index_"+side+"_"+str(k),(.0012,length,.002),(sign*(W/2+.0002),-.068,H-.061-k*.008),index,.00035)
# Spine is the narrow shelf-facing edge.
box("spine_inlay",(W-.028,.003,H-.034),(0,-D/2+.0005,H/2),panel,.001)
for k,width in enumerate([.030,.023,.015]):
    box("spine_index_"+str(k),(width,.0015,.0022),(0,-D/2-.0011,H-.060-k*.010),index,.00045)
box("spine_catalog_blank",(W-.038,.0018,.021),(0,-D/2-.0012,.055),index,.0006)
box("catalog_center",(W-.043,.001,.016),(0,-D/2-.0023,.055),graphite,.00035)
# Restrained rear/end detailing, closed top and underside inherited from chassis.
box("rear_binding",(W-.030,.002,H-.042),(0,D/2-.0001,H/2),panel,.0007)
# UV islands packed over the full asset, after bevel generation.
for ob in parts: ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.uv.smart_project(island_margin=.015)
bpy.ops.object.mode_set(mode="OBJECT")
for ob in parts: ob.select_set(False)
# Review scene; deliberately excluded from export.
ground = material("REVIEW_ground",(.115,.137,.16),.9)
box("REVIEW_ground",(200,200,.02),(0,0,-.012),ground,0,studio)
world = bpy.data.worlds.new("REVIEW_world")
world.use_nodes = True
bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (.17,.20,.25,1)
bg.inputs[1].default_value = .45
scene.world = world
camera = bpy.data.objects.new("REVIEW_camera",bpy.data.cameras.new("REVIEW_camera"))
studio.objects.link(camera)
camera.data.type = "ORTHO"; camera.data.ortho_scale = .66
scene.camera = camera
def aim(ob,loc,target=(0,0,.20)):
    ob.location = loc
    ob.rotation_euler = (Vector(target)-ob.location).to_track_quat("-Z","Y").to_euler()
aim(camera,(.82,-1.10,.70))
for name,loc,power,size,color in [
    ("key",(.30,-.60,.95),36,.65,(.88,.94,1)),
    ("fill",(-.60,-.20,.42),20,.55,(1,.93,.82)),
    ("rim",(.15,.62,.75),45,.45,(.83,.90,1))]:
    data=bpy.data.lights.new("REVIEW_"+name,"AREA")
    data.energy=power; data.shape = data.shape; data.size=size; data.color=color
    ob=bpy.data.objects.new("REVIEW_"+name,data); studio.objects.link(ob); aim(ob,loc)
try: scene.render.engine="BLENDER_EEVEE"
except TypeError: pass
scene.render.resolution_x=1100; scene.render.resolution_y=1100
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.film_transparent=False
# Read view properties instead of replacing the user's workspace.
for area in bpy.context.screen.areas:
    if area.type=="VIEW_3D":
        area.spaces.active.region_3d.view_perspective="CAMERA"
        area.spaces.active.shading.type="MATERIAL"
root.select_set(True)
bpy.context.view_layer.objects.active=root
bpy.context.view_layer.update()
print("Created",len(parts),"asset mesh parts in",scene.name)
