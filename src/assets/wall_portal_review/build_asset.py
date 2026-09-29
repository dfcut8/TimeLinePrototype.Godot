"""Deterministic Blender authoring: --background --python build_asset.py -- wall|portal.

Uses a new scene and writes only that scene's library, never the user's .blend.
Dimensions below are Godot XYZ meters; conversion to Blender happens in box().
"""
import bpy, bmesh, json, struct, hashlib, sys
from pathlib import Path
from mathutils import Vector

KIND = sys.argv[sys.argv.index('--') + 1]
assert KIND in ('wall', 'portal')
NAME = 'wall_infill_bay' if KIND == 'wall' else 'passage_portal_bay_frame'
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

# Structural solids meet at boundaries. A continuous core closes all skin seams.
if KIND == 'wall':
    box('closed_wall_core',(5.46,4.75,.24),(0,2.375,0),panel,0)
    for z,face in [(-.1215,'rear'),(.1215,'front')]:
        # Three panel fields, with 8 mm recessed reveals backed by the core.
        for i,x in enumerate([-1.82,0,1.82]):
            box(face+'_panel_'+str(i),(1.812,4.43,.003),(x,2.375,z),ceramic,.0005)
        for y,label in [(.078,'base'),(4.672,'head')]:
            box(face+'_'+label,(5.46,.156,.003),(0,y,z),graphite,0)
else:
    # Same wall envelope; opening x +/-1.5, y 0..3.4, no sill.
    for x,side in [(-2.19,'left'),(2.19,'right')]:
        box(side+'_wall_core',(1.08,3.4,.24),(x,1.7,0),panel,0)
    for x,side in [(-1.575,'left'),(1.575,'right')]:
        box(side+'_jamb',(.15,3.4,.24),(x,1.7,0),graphite,0)
    box('header_reveal',(5.46,.15,.24),(0,3.475,0),graphite,0)
    box('upper_wall_core',(5.46,1.2,.24),(0,4.15,0),panel,0)
    for z,face in [(-.1215,'rear'),(.1215,'front')]:
        for x,side in [(-2.19,'left'),(2.19,'right')]:
            box(face+'_'+side+'_panel',(1.072,3.392,.003),(x,1.7,z),ceramic,.0005)
        box(face+'_upper_panel',(5.452,1.192,.003),(0,4.15,z),ceramic,.0005)

for ob in parts: ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')
report = {'blender_version': bpy.app.version_string, 'issue':24 if KIND=='wall' else 25, 'parts':[]}
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
# Separate studio excluded from GLB; soft light, no bloom.
world=bpy.data.worlds.new('Review world'); world.use_nodes=True
next(n for n in world.node_tree.nodes if n.type=='BACKGROUND').inputs[0].default_value=(.17,.20,.25,1)
next(n for n in world.node_tree.nodes if n.type=='BACKGROUND').inputs[1].default_value=.6
scene.world=world
camera=bpy.data.objects.new('Review camera',bpy.data.cameras.new('Review camera'))
studio.objects.link(camera); scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=7.5
def aim(ob, loc, target=None):
    if target is None: target=(0,0,2.375)
    ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Key',(3,-4,5),900,4),('Fill',(-3,-2,3),650,3),('Rim',(1,3,4),1100,3)]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.size=size
    ob=bpy.data.objects.new(name,light); studio.objects.link(ob); aim(ob,loc)
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=900; scene.render.resolution_y=650
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
for view,loc in [('front',(3,-5,3)),('rear',(-3,5,3)),('side',(7,-2,3)),('underside',(3,-5,-2))]:
    aim(camera,loc)
    scene.render.filepath=str(OUT/('preview_'+view+'.png'))
    bpy.ops.render.render(write_still=True)
aim(camera,(3,-5,3))
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').touch()
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
print(json.dumps(report))

wrapper = f'[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://assets/{NAME}/{NAME}.glb" id="1"]\n[node name="{NAME.title().replace("_", "")}" type="Node3D"]\n[node name="Model" parent="." instance=ExtResource("1")]\n'
for label,pos in [('LeftInterface',(-2.73,0,0)),('RightInterface',(2.73,0,0)),('Header',(0,4.75,0)),('OpeningCentre',(0,1.7,0))] if KIND=='portal' else [('LeftInterface',(-2.73,0,0)),('RightInterface',(2.73,0,0)),('Header',(0,4.75,0))]:
    wrapper += f'[node name="{label}" type="Marker3D" parent="."]\nposition = Vector3{pos}\n'
(OUT/(NAME+'.tscn')).write_text(wrapper)
