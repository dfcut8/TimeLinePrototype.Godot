"""Deterministic Blender authoring: --background --python build_asset.py -- bench|plinth.

Uses a new scene and writes only that scene's library, never the user's .blend.
Dimensions below are Godot XYZ meters; conversion to Blender happens in box().
"""
import bpy, bmesh, json, struct, hashlib, sys
from pathlib import Path
from mathutils import Vector

KIND = sys.argv[sys.argv.index('--') + 1]
assert KIND in ('bench', 'plinth')
NAME = 'reading_bench' if KIND == 'bench' else 'archive_display_plinth'
OUT = Path(__file__).resolve().parent.parent / NAME
OUT.mkdir(exist_ok=True)
scene = bpy.data.scenes.new(NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
asset = bpy.data.collections.new('ASSET_' + NAME)
scene.collection.children.link(asset)
studio = bpy.data.collections.new('REVIEW_ONLY')
scene.collection.children.link(studio)
root = bpy.data.objects.new(NAME, None)
asset.objects.link(root)
parts = []

def material(name, rgb, roughness, metallic=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value = (*rgb, 1)
    p.inputs['Roughness'].default_value = roughness
    p.inputs['Metallic'].default_value = metallic
    m.diffuse_color = (*rgb, 1)
    return m

graphite = material('archive_graphite', (.048, .060, .073), .68, .22)
ceramic = material('archive_basalt_ceramic', (.085, .103, .117), .81)
panel = material('archive_dark_panel', (.018, .026, .033), .76)

def box(name, size, center, mat, bevel=.002):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    for v in bm.verts:
        v.co = Vector((v.co.x*size[0]+center[0], v.co.y*size[2]-center[2], v.co.z*size[1]+center[1]))
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    ob = bpy.data.objects.new(name, mesh)
    asset.objects.link(ob)
    ob.parent = root
    mesh.materials.append(mat)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    if bevel:
        mod = ob.modifiers.new('Edge radius', 'BEVEL')
        mod.width = bevel
        mod.segments = 2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.select_set(False)
    parts.append(ob)
    return ob

if KIND == 'bench':
    box('ceramic_seat', (1.60,.08,.48), (0,.41,0), ceramic, .012)
    box('underseat_frame', (1.42,.045,.36), (0,.3475,0), graphite, .004)
    for x, side in [(-.56,'left'),(.56,'right')]:
        box('solid_support_'+side, (.12,.30,.38), (x,.175,0), graphite, .005)
        box('floor_pad_'+side, (.14,.025,.40), (x,.0125,0), panel, .002)
else:
    box('recessed_foot', (.54,.06,.39), (0,.03,0), panel, .004)
    box('ceramic_pedestal', (.62,.48,.47), (0,.30,0), ceramic, .007)
    box('top_shadow_neck', (.59,.012,.44), (0,.546,0), panel, .002)
    box('display_top', (.70,.048,.55), (0,.576,0), graphite, .008)

for ob in parts: ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')
report = {'blender_version': bpy.app.version_string, 'issue':35 if KIND=='bench' else 36, 'parts':[]}
points=[]
for ob in parts:
    mesh=ob.data
    mesh.calc_loop_triangles()
    bm=bmesh.new(); bm.from_mesh(mesh)
    row={'name':ob.name, 'triangles':len(mesh.loop_triangles), 'non_manifold_edges':sum(not e.is_manifold for e in bm.edges), 'degenerate_faces':sum(f.calc_area()<1e-12 for f in bm.faces), 'signed_volume':bm.calc_volume(signed=True), 'uv_layers':len(mesh.uv_layers)}
    assert row['non_manifold_edges']==0 and row['degenerate_faces']==0 and row['signed_volume']>0 and row['uv_layers']==1, row
    bm.free()
    points.extend(ob.data.vertices[v].co for v in range(len(ob.data.vertices)))
    report['parts'].append(row)
report['triangles']=sum(p['triangles'] for p in report['parts'])
report['materials']=3
report['bounds_blender']={'min':[min(v[i] for v in points) for i in range(3)], 'max':[max(v[i] for v in points) for i in range(3)]}
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+'.glb')),use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
data=(OUT/(NAME+'.glb')).read_bytes()
magic,version,length=struct.unpack_from('<4sII',data)
assert magic==b'glTF' and version==2 and length==len(data)
chunk_len=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+chunk_len])
assert len(gltf['materials'])==3 and not gltf.get('images')
assert sum(gltf['accessors'][p['indices']]['count']//3 for m in gltf['meshes'] for p in m['primitives'])==report['triangles']
report['glb_sha256']=hashlib.sha256(data).hexdigest()
report['passed']=True
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
for ob in parts: ob.select_set(False)
# Separate studio excluded from GLB; soft light, no emission, no bloom.
world=bpy.data.worlds.new('Review world'); world.use_nodes=True
next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND').inputs[0].default_value=(.17,.20,.25,1)
next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND').inputs[1].default_value=.6
scene.world=world
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
studio.objects.link(camera); scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=2.0
def aim(ob, loc, target=(0,0,.25)):
    ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Key',(3,-4,5),900,4),('Fill',(-3,-2,3),650,3),('Rim',(1,3,4),1100,3)]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.size=size
    ob=bpy.data.objects.new(name,light); studio.objects.link(ob); aim(ob,loc)
try:
    scene.render.engine='BLENDER_EEVEE'
except TypeError:
    pass
scene.render.resolution_x=640; scene.render.resolution_y=640
scene.render.resolution_percentage=100
assert 'PNG' in [i.identifier for i in scene.render.image_settings.bl_rna.properties['file_format'].enum_items]
scene.render.image_settings.file_format='PNG'
for view,loc in [('front',(3,-5,3)),('rear',(-3,5,3)),('side',(5,0,.25)),('underside',(3,-5,-2))]:
    aim(camera,loc)
    scene.render.filepath=str(OUT/('preview_'+view+'.png'))
    bpy.ops.render.render(write_still=True)
aim(camera,(3,-5,3))
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').touch()
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
print(json.dumps(report))
