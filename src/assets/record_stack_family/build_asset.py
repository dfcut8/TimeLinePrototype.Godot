"""Deterministic Blender authoring: --background --python build_asset.py -- bay|cap.

Uses a new scene and writes only that scene's library, never the user's .blend.
Dimensions below are Godot XYZ meters; conversion to Blender happens in box().
"""
import bpy, bmesh, json, struct, hashlib, sys
from pathlib import Path
from mathutils import Vector

KIND = sys.argv[sys.argv.index('--') + 1]
assert KIND in ('bay', 'cap')
NAME = 'record_stack_shelf_bay' if KIND == 'bay' else 'record_stack_end_cap'
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
    p = m.node_tree.nodes.get('Principled BSDF')
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

if KIND == 'bay':
    # Structural faces meet exactly; bevels only on exposed trim.
    box('lower_base', (1.6,.12,.44), (0,.06,0), ceramic, 0)
    for x, side in [(-.775,'left'),(.775,'right')]:
        box('upright_'+side, (.05,2.28,.44), (x,1.26,0), graphite, 0)
    box('closed_back', (1.5,2.28,.034), (0,1.26,-.197), panel, 0)
    for i, top in enumerate([.16,.72,1.28,1.84,2.40]):
        # A genuine downward-open 50 mm recess behind the front lip, no fake decal.
        box('shelf_%d_deck'%i, (1.5,.028,.40), (0,top-.014,.02), graphite, 0)
        box('shelf_%d_rear_web'%i, (1.5,.012,.33), (0,top-.034,-.015), graphite, 0)
        box('shelf_%d_front_lip'%i, (1.5,.012,.02), (0,top-.034,.21), ceramic, 0)
    # Four understated rear panels are flush backed, never open to the orbit camera.
    for i in range(4):
        box('rear_finish_%d'%i, (1.46,.50,.006), (0,.42+i*.56,-.217), ceramic, .001)
else:
    # Origin is the floor-level attachment plane. Local +X points outward.
    box('end_base', (.08,.12,.44), (.04,.06,0), ceramic, 0)
    box('end_closure', (.068,2.28,.44), (.034,1.26,0), graphite, 0)
    box('end_ceramic_panel', (.012,2.22,.40), (.074,1.26,0), ceramic, .002)
    box('end_dark_inset', (.003,2.08,.32), (.0795,1.26,0), panel, .001)
    # No light source: subtle geometric index, mirrored front/back so either end fits.
    for z in [-.12,.12]:
        box('end_index_'+str(z), (.002,.32,.004), (.081,1.26,z), ceramic, .0005)

for ob in parts: ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')
report = {'blender_version': bpy.app.version_string, 'issue':28 if KIND=='bay' else 29, 'parts':[]}
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
world.node_tree.nodes.get('Background').inputs[0].default_value=(.17,.20,.25,1)
world.node_tree.nodes.get('Background').inputs[1].default_value=.6
scene.world=world
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
studio.objects.link(camera); scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=3.2
def aim(ob, loc, target=(0,0,1.2)):
    ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Key',(3,-4,5),900,4),('Fill',(-3,-2,3),650,3),('Rim',(1,3,4),1100,3)]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.size=size
    ob=bpy.data.objects.new(name,light); studio.objects.link(ob); aim(ob,loc)
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=800; scene.render.resolution_y=800
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
for view,loc in [('front',(3,-5,3)),('rear',(-3,5,3)),('side',(5,0,1.2)),('underside',(3,-5,-2))]:
    aim(camera,loc)
    scene.render.filepath=str(OUT/('preview_'+view+'.png'))
    bpy.ops.render.render(write_still=True)
aim(camera,(3,-5,3))
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').touch()
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
print(json.dumps(report))
