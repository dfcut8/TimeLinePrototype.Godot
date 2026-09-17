"""Issue #19: original parametric gallery. Run with Blender --background --python.
Writes only this asset's generated outputs. Existing Blender scenes are preserved.
"""
import bpy
import bmesh
import json
import math
import struct
from pathlib import Path
from mathutils import Vector, Matrix

OUT = Path(__file__).resolve().parent
NAME = 'curved_gallery'
ANGLE = math.radians(15)
SEGMENTS = 24
# Cross-section (radius, height). Integral parapet avoids intersecting shells.
# Tiny radial bevels preserve the exact planar sector interfaces.
PROFILE = [(22.015, -.25), (25.485, -.25), (25.5, -.235),
           (25.5, -.015), (25.485, 0), (22.18, 0),
           (22.18, 1.085), (22.165, 1.1), (22.015, 1.1),
           (22, 1.085), (22, -.235)]
scene = bpy.data.scenes.new('Gallery_19_Review')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
asset = bpy.data.collections.new('ASSET_curved_gallery')
scene.collection.children.link(asset)
studio = bpy.data.collections.new('REVIEW_ONLY')
scene.collection.children.link(studio)

def material(name, color, roughness, metallic=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = roughness
    shader.inputs['Metallic'].default_value = metallic
    return mat

materials = [material('archive_graphite', (.048,.060,.073), .68, .22),
             material('archive_basalt_ceramic', (.085,.103,.117), .81)]
n = len(PROFILE)
verts = [(r*math.cos(a), r*math.sin(a), z)
         for i in range(SEGMENTS+1)
         for a in [-ANGLE/2 + ANGLE*i/SEGMENTS] for r,z in PROFILE]
faces = [(i*n+j, i*n+(j+1)%n, (i+1)*n+(j+1)%n, (i+1)*n+j)
         for i in range(SEGMENTS) for j in range(n)]
faces += [tuple(reversed(range(n))), tuple(SEGMENTS*n+j for j in range(n))]
mesh = bpy.data.meshes.new(NAME)
mesh.from_pydata(verts, [], faces)
mesh.update()
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
assert all(e.is_manifold for e in bm.edges)
assert all(f.calc_area() > 1e-9 for f in bm.faces)
volume = bm.calc_volume(signed=True)
assert volume > 0
bm.to_mesh(mesh)
bm.free()
ob = bpy.data.objects.new(NAME, mesh)
asset.objects.link(ob)
for mat in materials:
    mesh.materials.append(mat)
for poly in mesh.polygons:
    # Ceramic walking deck and inner parapet; graphite soffit and outer face.
    poly.material_index = int(poly.index < SEGMENTS*n and poly.index % n in (4,5,6,7))
    poly.use_smooth = False
bpy.context.view_layer.objects.active = ob
ob.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(island_margin=.025)
bpy.ops.object.mode_set(mode='OBJECT')
ob['issue'] = 'https://github.com/dfcut8/TimeLinePrototype.Godot/issues/19'
ob['interface'] = 'Rotation center origin; +/-7.5 degree radial seams; deck Z=0; tier pitch 5 m'
ob['dependency'] = 'Pier A #16 interface proposed, actual fit pending'
mesh.calc_loop_triangles()
triangles = len(mesh.loop_triangles)
# Every radial seam vertex coincides under one sector rotation.
rotation = Matrix.Rotation(ANGLE, 4, 'Z')
seam_error = max(((rotation @ Vector(verts[j]))-Vector(verts[SEGMENTS*n+j])).length for j in range(n))
assert seam_error < 1e-5
minimum_radius = 22*math.cos(ANGLE/SEGMENTS/2)
assert minimum_radius > 20
bpy.ops.export_scene.gltf(filepath=str(OUT/(NAME+'.glb')), export_format='GLB',
                         use_selection=True, use_active_scene=True, export_yup=True, export_cameras=False,
                         export_lights=False, export_extras=True)
data = (OUT/(NAME+'.glb')).read_bytes()
magic, version, length = struct.unpack_from('<III', data)
assert magic == 0x46546c67 and version == 2 and length == len(data)
json_length, chunk_type = struct.unpack_from('<II', data, 12)
assert chunk_type == 0x4e4f534a
gltf = json.loads(data[20:20+json_length])
primitives = [p for m in gltf['meshes'] for p in m['primitives']]
assert len(gltf['meshes']) == 1 and len(gltf['materials']) == 2
assert all({'POSITION','NORMAL','TEXCOORD_0'} <= p['attributes'].keys() for p in primitives)
assert not any(gltf.get(k) for k in ('images','animations','cameras'))
assert sum(gltf['accessors'][p['indices']]['count']//3 for p in primitives) == triangles
report = dict(issue=19, blender=bpy.app.version_string, triangles=triangles,
              material_count=2, closed_manifold=True, positive_volume_m3=volume,
              degenerate_faces=0, uv0=True, identity_transforms=True,
              sector_degrees=15, segments=SEGMENTS, inner_radius_m=22,
              outer_radius_m=25.5, slab_thickness_m=.25, parapet_height_m=1.1,
              parapet_thickness_m=.18, tier_pitch_m=5, tier_clearance_m=3.65,
              seam_error_m=seam_error, minimum_faceted_radius_m=minimum_radius,
              central_clearance_m=minimum_radius-20, glb_bytes=len(data),
              actual_pier_fit='Pending issue #16', maps='None; embedded opaque PBR factors')
(OUT/'validation.json').write_text(json.dumps(report, indent=2)+'\n')

# A separate render collection is excluded from the portable GLB.
world = bpy.data.worlds.new('Gallery_studio_world')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs[0].default_value = (.19,.23,.29,1)
world.node_tree.nodes['Background'].inputs[1].default_value = .65
scene.world = world
for name, loc, energy, size in [('Key',(16,-6,9),2100,8),('Fill',(28,4,7),2600,7),('Soffit',(19,0,-6),1300,6)]:
    light = bpy.data.lights.new(name,'AREA')
    light.energy, light.shape, light.size = energy, 'DISK', size
    obj = bpy.data.objects.new(name,light)
    studio.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (Vector((23.5,0,0))-obj.location).to_track_quat('-Z','Y').to_euler()
camera = bpy.data.objects.new('Review_camera',bpy.data.cameras.new('Review_camera'))
studio.objects.link(camera)
scene.camera = camera
camera.data.type = 'ORTHO'
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = 1200
scene.render.resolution_y = 850
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.view_settings.view_transform = 'AgX'

def render(name, position, target, scale):
    camera.location = position
    camera.rotation_euler = (Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.ortho_scale = scale
    scene.render.filepath = str(OUT/(name+'.png'))
    bpy.ops.render.render(write_still=True)

render('preview_front',(14,-11,7),(23.4,0,.35),9)
render('preview_rear',(32,10,6),(23.4,0,.35),9)
render('preview_underside',(15,9,-5),(23.4,0,.25),9)
copies=[]
for tier in (0,5):
    for sector in (-2,-1,0,1,2):
        if tier == 0 and sector == 0:
            continue
        copy = bpy.data.objects.new('Review_sector_%s_%s'%(tier,sector),mesh)
        studio.objects.link(copy)
        copy.rotation_euler.z = ANGLE*sector
        copy.location.z = tier
        copies.append(copy)
render('preview_assembly',(0,-12,12),(22,0,2.5),38)
for copy in copies:
    copy.hide_render = True
    copy.hide_viewport = True
camera.location=(14,-11,7)
camera.rotation_euler=(Vector((23.4,0,.35))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale=9
bpy.data.libraries.write(str(OUT/(NAME+'.blend')), {scene}, fake_user=True, compress=True)
print(json.dumps(report))
