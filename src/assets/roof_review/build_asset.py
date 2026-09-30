"""Original V5 roof kit. Blender --background --python-exit-code 1 --python this.py -- curb|beam.
Creates an isolated scene; exports only the chosen asset. No external dependencies.
"""
import bpy, bmesh, math, json, struct, sys
from pathlib import Path
from mathutils import Vector

KIND = sys.argv[sys.argv.index('--') + 1]
assert KIND in ('curb', 'beam')
NAME = 'oculus_curb_segment' if KIND == 'curb' else 'radial_roof_beam'
OUT = Path(__file__).resolve().parent.parent / NAME
scene = bpy.data.scenes.new(NAME)
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
asset = bpy.data.collections.new('ASSET_' + NAME)
scene.collection.children.link(asset)
studio = bpy.data.collections.new('REVIEW_ONLY')
scene.collection.children.link(studio)

def material(name, rgb, roughness, metal):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*rgb, 1)
    shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*rgb, 1)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Metallic'].default_value = metal
    return mat

mats = [material('archive_graphite', (.048,.060,.073), .68, .22),
        material('archive_basalt_ceramic', (.085,.103,.117), .81, 0)]
if KIND == 'curb':
    # Chamfered annular section, planar sector ends to retain exact modular seams.
    profile = [(10.015,0),(10.585,0),(10.6,.015),(10.6,.585),
               (10.585,.6),(10.015,.6),(10,.585),(10,.015)]
    steps = 24
    verts = [(r*math.cos(a), r*math.sin(a), h) for i in range(steps+1)
             for a in [math.radians(-7.5+15*i/steps)] for r,h in profile]
    target = (10.3,0,.3)
    span = 4.3
else:
    # Straight chamfered solid. Bottom center at inner end is the placement pivot.
    profile = [(-.145,0),(.145,0),(.16,.015),(.16,.535),
               (.145,.55),(-.145,.55),(-.16,.535),(-.16,.015)]
    steps = 1
    verts = [(x, w, h) for x in (0,14.9) for w,h in profile]
    target = (7.45,0,.275)
    span = 17
n = len(profile)
faces = [(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j)
         for i in range(steps) for j in range(n)]
faces += [tuple(reversed(range(n))),tuple(steps*n+j for j in range(n))]
mesh = bpy.data.meshes.new(NAME)
mesh.from_pydata(verts,[],faces)
mesh.update()
bm = bmesh.new(); bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
assert all(e.is_manifold for e in bm.edges)
assert all(f.calc_area()>1e-10 for f in bm.faces)
volume = bm.calc_volume(signed=True)
assert volume>0
bm.to_mesh(mesh); bm.free()
ob = bpy.data.objects.new(NAME,mesh); asset.objects.link(ob)
for mat in mats: mesh.materials.append(mat)
for p in mesh.polygons:
    p.material_index = int(p.index < steps*n and p.index%n == 4)
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.02)
bpy.ops.object.mode_set(mode='OBJECT')
mesh.calc_loop_triangles()
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+'.glb')),use_selection=True,
    use_active_scene=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
data = (OUT/(NAME+'.glb')).read_bytes()
magic,version,length = struct.unpack_from('<4sII',data)
assert magic==b'glTF' and version==2 and length==len(data)
gltf = json.loads(data[20:20+struct.unpack_from('<I',data,12)[0]])
primitives = [p for m in gltf['meshes'] for p in m['primitives']]
assert len(gltf['materials'])==2 and not gltf.get('images')
assert all({'POSITION','NORMAL','TEXCOORD_0'}<=p['attributes'].keys() for p in primitives)
assert sum(gltf['accessors'][p['indices']]['count']//3 for p in primitives)==len(mesh.loop_triangles)
report = dict(issue=22 if KIND=='curb' else 23,blender=bpy.app.version_string,
    triangles=len(mesh.loop_triangles),materials=2,closed_manifold=True,
    signed_volume_m3=volume,degenerate_faces=0,identity_transforms=True,uv0=True,passed=True)
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
world = bpy.data.worlds.new('Review world'); world.use_nodes=True
bg = next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
bg.inputs[0].default_value=(.19,.23,.29,1); bg.inputs[1].default_value=.7
scene.world=world
def aim(obj, position):
    obj.location=position
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
for label,offset,power in [('Key',(0,-5,8),1800),('Fill',(2,5,4),1300),('Soffit',(0,0,-6),1000)]:
    light=bpy.data.lights.new(label,'AREA'); light.energy=power; light.size=7
    obj=bpy.data.objects.new(label,light); studio.objects.link(obj)
    aim(obj,Vector(target)+Vector(offset))
camera=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'))
studio.objects.link(camera); scene.camera=camera
camera.data.type='ORTHO'; camera.data.ortho_scale=span
scene.render.engine='CYCLES'; scene.cycles.samples=16; scene.cycles.use_denoising=True
scene.render.resolution_x=1000; scene.render.resolution_y=650; scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG'
views = [('front',(-5,-7,4)),('rear',(5,7,4)),('end',(8,-2,1)),('underside',(-4,-6,-5))]
for label,offset in views:
    aim(camera,Vector(target)+Vector(offset))
    scene.render.filepath=str(OUT/('preview_'+label+'.png'))
    bpy.ops.render.render(write_still=True)
aim(camera,Vector(target)+Vector(views[0][1]))
(OUT/'source').mkdir(exist_ok=True); (OUT/'source'/'.gdignore').touch()
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
wrapper=f'[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://assets/{NAME}/{NAME}.glb" id="1"]\n[node name="{NAME.title().replace("_", "")}" type="Node3D"]\n[node name="Model" parent="." instance=ExtResource("1")]\n'
markers = [('BeamBearing',(10.365,.6,0)),('RingCenter',(0,0,0))] if KIND=='curb' else [('InnerBearing',(.215,0,0)),('OuterBearing',(14.65,0,0)),('OuterEnd',(14.9,0,0))]
for label,pos in markers:
    wrapper+=f'[node name="{label}" type="Marker3D" parent="."]\nposition = Vector3{pos}\n'
(OUT/(NAME+'.tscn')).write_text(wrapper)
print(json.dumps(report))
