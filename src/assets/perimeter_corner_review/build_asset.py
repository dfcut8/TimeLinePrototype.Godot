"""Deterministic Blender authoring: --background --python build_asset.py -- floor|corner.

Uses a new scene and writes only that scene's library, never the user's .blend.
Dimensions below are Godot XYZ meters; conversion to Blender happens in box().
"""
import bpy, bmesh, json, struct, hashlib, sys
from pathlib import Path
from mathutils import Vector

KIND = sys.argv[sys.argv.index('--') + 1]
assert KIND in ('floor', 'corner')
NAME = 'curved_floor_perimeter_wedge' if KIND == 'floor' else 'record_stack_corner'
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


from math import sin, cos, pi

def prism(name, polygon, bottom, top, mat):
    # Polygon in Godot XZ; recalculate orientation before authoring UVs.
    vertices=[(x,-z,y) for y in (bottom,top) for x,z in polygon]
    n=len(polygon)
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(vertices,[],faces); mesh.update()
    bm=bmesh.new(); bm.from_mesh(mesh); bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(mesh); bm.free()
    ob=bpy.data.objects.new(name,mesh); asset.objects.link(ob); ob.parent=root
    mesh.materials.append(mat); parts.append(ob)
    return ob

def arc(name, inner, outer, bottom, top, mat):
    n=72
    poly=[(outer*cos(i*pi/(2*n)),outer*sin(i*pi/(2*n))) for i in range(n+1)]
    poly += [(inner*cos(i*pi/(2*n)),inner*sin(i*pi/(2*n))) for i in range(n,-1,-1)]
    return prism(name,poly,bottom,top,mat)

if KIND == 'floor':
    # One quarter of disk minus square, exact 4 m tile boundary at X/Z=20.
    n=144
    polygon=[(20,0),(32,0)]
    polygon += [(32*cos(i*pi/(2*n)),32*sin(i*pi/(2*n))) for i in range(1,n+1)]
    polygon += [(0,20),(20,20)]
    prism('quarter_perimeter_closed',polygon,-.25,0,ceramic)
else:
    # Concave front radius .8 m, finished outer back radius 1.24 m.
    arc('corner_base',.8,1.24,0,.12,ceramic)
    arc('closed_curved_back',1.20,1.24,.12,2.4,panel)
    for i,top in enumerate([.16,.72,1.28,1.84,2.40]):
        arc('shelf_%d_deck'%i,.8,1.20,top-.028,top,graphite)
        arc('shelf_%d_rear_web'%i,.87,1.20,top-.04,top-.028,graphite)
        arc('shelf_%d_front_lip'%i,.8,.82,top-.04,top-.028,ceramic)
    # Back already has complete closed surfaces; no coplanar overlay panels.
for ob in parts: ob.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')
report = {'blender_version': bpy.app.version_string, 'issue':21 if KIND=='floor' else 30, 'parts':[]}
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
report['materials']=1 if KIND=='floor' else 3
report['bounds_blender']={'min':[min(v[i] for v in points) for i in range(3)], 'max':[max(v[i] for v in points) for i in range(3)]}
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+'.glb')),use_selection=True,use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
data=(OUT/(NAME+'.glb')).read_bytes()
magic,version,length=struct.unpack_from('<4sII',data)
assert magic==b'glTF' and version==2 and length==len(data)
chunk_len=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+chunk_len])
assert len(gltf['materials'])==report['materials'] and not gltf.get('images')
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
camera.data.type='ORTHO'; camera.data.ortho_scale=3.2
def aim(ob, loc, target=(0,0,1.2)):
    ob.location=loc
    ob.rotation_euler=(Vector(target)-ob.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size in [('Key',(3,-4,5),900,4),('Fill',(-3,-2,3),650,3),('Rim',(1,3,4),1100,3)]:
    light=bpy.data.lights.new(name,'SUN'); light.energy=power/500
    ob=bpy.data.objects.new(name,light); studio.objects.link(ob); aim(ob,loc)
scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=640; scene.render.resolution_y=640
scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
for view,loc in [('front',(3,-5,3)),('rear',(-3,5,3)),('side',(5,0,1.2)),('underside',(3,-5,-2))]:
    target=Vector((18,-18,-.125)) if KIND=='floor' else Vector((.65,-.65,1.2))
    offset=Vector(loc)-Vector((0,0,1.2))
    if KIND=='corner': offset.x=-offset.x; offset.y=-offset.y
    loc=target+offset*(8 if KIND=='floor' else 1)
    camera.data.ortho_scale=52 if KIND=='floor' else 3.2
    aim(camera,loc,target)
    scene.render.filepath=str(OUT/('preview_'+view+'.png'))
    bpy.ops.render.render(write_still=True)
target=Vector((18,-18,-.125)) if KIND=='floor' else Vector((.65,-.65,1.2))
offset=Vector((24,-40,14.4)) if KIND=='floor' else Vector((-3,5,1.8))
aim(camera,target+offset,target)
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').touch()
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
print(json.dumps(report))
