"""Issue #5: run in live Blender via MCP. Preserves existing scenes.
One metre per unit. Output is confined to this script's directory.
"""
import bpy, bmesh, json, hashlib, struct
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
NAME = 'timeline_rail_housing'
scene = bpy.data.scenes.new('Timeline_Rail_Housing_Review')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
asset = bpy.data.collections.new('ASSET_' + NAME)
scene.collection.children.link(asset)
# Cross section in Godot (Z depth, Y height). The front opens toward +Z.
# Chamfers run longitudinally only: no bevel may shorten the mating ends.
profile = [(-.046,-.06),(.046,-.06),(.06,-.046),(.06,-.020),
           (.045,-.014),(.030,-.014),(.030,.014),(.045,.014),
           (.06,.020),(.06,.046),(.046,.06),(-.046,.06),
           (-.06,.046),(-.06,-.046)]
n = len(profile)
vertices = [(x,-z,y) for x in (0,2) for z,y in profile]
faces = [tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
mesh = bpy.data.meshes.new(NAME)
mesh.from_pydata(vertices,[],faces)
mesh.update()
bm = bmesh.new(); bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bmesh.ops.triangulate(bm,faces=list(bm.faces))
bm.to_mesh(mesh); bm.free()
ob = bpy.data.objects.new(NAME,mesh); asset.objects.link(ob)
mat = bpy.data.materials.new('archive_graphite')
mat.use_nodes = True
p = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
p.inputs['Base Color'].default_value = (.048,.060,.073,1)
p.inputs['Roughness'].default_value = .68
p.inputs['Metallic'].default_value = .22
mat.diffuse_color = (.048,.060,.073,1)
mesh.materials.append(mat)
ob.select_set(True); bpy.context.view_layer.objects.active = ob
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.02)
bpy.ops.object.mode_set(mode='OBJECT')
ob['issue'] = 5
ob['pivot'] = 'Earlier-end center; +X later, +Y up, +Z front in Godot'
ob['module_length_m'] = 2.0
ob['channel_seat_godot_z_m'] = .03
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+'.glb')),use_selection=True,
    use_active_scene=True,export_animations=False,export_cameras=False,
    export_lights=False,export_extras=True,export_yup=True)
bm = bmesh.new(); bm.from_mesh(mesh)
report = {'issue':5,'blender_version':bpy.app.version_string,
    'triangles':len(mesh.polygons),'materials':1,
    'non_manifold_edges':sum(not e.is_manifold for e in bm.edges),
    'degenerate_faces':sum(f.calc_area()<1e-12 for f in bm.faces),
    'signed_volume_m3':bm.calc_volume(signed=True),
    'uv_layers':len(mesh.uv_layers),'module_length_m':2,
    'dimensions_godot_m':[2,.12,.12],
    'three_module_seam_gap_m':[0,0]}
assert report['non_manifold_edges']==0 and report['degenerate_faces']==0
assert report['signed_volume_m3']>0
bm.free()
data=(OUT/(NAME+'.glb')).read_bytes()
magic,version,length=struct.unpack_from('<4sII',data)
assert magic==b'glTF' and version==2 and length==len(data)
chunk_len=struct.unpack_from('<I',data,12)[0]
gltf=json.loads(data[20:20+chunk_len])
assert len(gltf['meshes'])==1 and len(gltf['materials'])==1
assert not gltf.get('images') and not gltf.get('animations')
report['glb_sha256']=hashlib.sha256(data).hexdigest()
report['glb_bytes']=len(data)
(OUT/'validation.json').write_text(json.dumps(report,indent=2))
# Separate review collection, excluded from exported GLB.
studio=bpy.data.collections.new('REVIEW_ONLY'); scene.collection.children.link(studio)
world=bpy.data.worlds.new('Rail_Review_World'); world.use_nodes=True
bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND')
bg.inputs[0].default_value=(.12,.15,.20,1); bg.inputs[1].default_value=.6
scene.world=world
camera=bpy.data.objects.new('ReviewCamera',bpy.data.cameras.new('ReviewCamera'))
studio.objects.link(camera); camera.data.type='ORTHO'; camera.data.ortho_scale=2.65
scene.camera=camera
def aim(obj,loc,target):
    obj.location=loc
    obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
aim(camera,(2.8,-3,1.7),(1,0,0))
for name,loc,power,size in [('Key',(0,-2,3),500,4),('Rim',(2,2,2),600,3),('Fill',(1,-2,-2),250,3)]:
    light=bpy.data.lights.new(name,'AREA'); light.energy=power; light.size=size
    obj=bpy.data.objects.new(name,light); studio.objects.link(obj); aim(obj,loc,(1,0,0))
try: scene.render.engine='BLENDER_EEVEE'
except TypeError: pass
scene.render.resolution_x=1400; scene.render.resolution_y=650
scene.render.resolution_percentage=100
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA'
        area.spaces.active.shading.type='MATERIAL'
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').write_text('')
bpy.data.libraries.write(str(OUT/'source'/(NAME+'.blend')),{scene},fake_user=True,compress=True)
print(json.dumps(report))
