"""Run through live Blender MCP; preserves all existing scenes and objects."""
import bpy
import bmesh
import json
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
NAME = 'rail_recessed_light_insert'


def build(name, out, profile, ends, color, emission, issue):
    scene = bpy.data.scenes.new(name + '_Review')
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    n = len(profile)
    vertices = [(x, -z, y) for x in ends for z, y in profile]
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    faces += [(i, (i + 1) % n, (i + 1) % n + n, i + n) for i in range(n)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    mat = bpy.data.materials.new('rail_pale_core' if emission else 'archive_graphite')
    mat.use_nodes = True
    shader = next(node for node in mat.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = .68
    shader.inputs['Metallic'].default_value = 0 if emission else .22
    shader.inputs['Emission Color'].default_value = (*color, 1)
    shader.inputs['Emission Strength'].default_value = emission
    mat.diffuse_color = (*color, 1)
    mesh.materials.append(mat)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(island_margin=.02)
    bpy.ops.object.mode_set(mode='OBJECT')
    obj['issue'] = issue
    obj['axes'] = 'Godot: X chronology, Y up, Z front; metre units'
    bpy.ops.export_scene.gltf(filepath=str(out / (name + '.glb')),
        use_selection=True, use_active_scene=True, export_animations=False,
        export_cameras=False, export_lights=False, export_extras=True, export_yup=True)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    report = dict(issue=issue, blender_version=bpy.app.version_string,
        triangles=len(mesh.polygons), materials=1, uv_layers=len(mesh.uv_layers),
        non_manifold_edges=sum(not e.is_manifold for e in bm.edges),
        degenerate_faces=sum(f.calc_area() < 1e-12 for f in bm.faces),
        signed_volume_m3=bm.calc_volume(signed=True),
        dimensions_godot_m=[ends[1]-ends[0], max(y for z,y in profile)-min(y for z,y in profile),
            max(z for z,y in profile)-min(z for z,y in profile)])
    bm.free()
    assert report['non_manifold_edges'] == report['degenerate_faces'] == 0
    assert report['signed_volume_m3'] > 0 and report['uv_layers'] == 1
    (out / 'validation.json').write_text(json.dumps(report, indent=2))
    world = bpy.data.worlds.new(name + '_World')
    world.use_nodes = True
    bg = next(node for node in world.node_tree.nodes if node.type == 'BACKGROUND')
    bg.inputs[0].default_value = (.12, .14, .17, 1)
    bg.inputs[1].default_value = .6
    scene.world = world
    camera = bpy.data.objects.new('ReviewCamera', bpy.data.cameras.new('ReviewCamera'))
    scene.collection.objects.link(camera)
    camera.data.type = 'ORTHO'
    scene.camera = camera
    center = Vector(((ends[0] + ends[1]) / 2,
        -(max(z for z,y in profile) + min(z for z,y in profile)) / 2,
        (max(y for z,y in profile) + min(y for z,y in profile)) / 2))
    span = max(report['dimensions_godot_m'])
    def aim(ob, location):
        ob.location = center + Vector(location) * span
        ob.rotation_euler = (center-ob.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.ortho_scale = span * (2.6 if span < 1 else 1.45)
    aim(camera, (1, -2, 1))
    for label, loc, power in [('Key', (0,-2,3), 400), ('Rear', (1,2,1), 300), ('Under', (0,-1,-2), 150)]:
        data = bpy.data.lights.new(label, 'AREA')
        data.energy = power * span * span
        data.size = span * 2
        lamp = bpy.data.objects.new(label, data)
        scene.collection.objects.link(lamp)
        aim(lamp, loc)
    try:
        scene.render.engine = 'BLENDER_EEVEE'
    except TypeError:
        pass
    scene.render.resolution_x = 1100
    scene.render.resolution_y = 600
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    for label, loc in [('front',(1,-2,1)), ('rear',(-1,2,1)), ('underside',(1,-2,-1)), ('end',(-2,-.25,.2))]:
        aim(camera, loc)
        scene.render.filepath = str(out / ('preview_' + label + '.png'))
        bpy.ops.render.render(write_still=True)
    aim(camera, (1,-2,1))
    for area in bpy.context.screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.region_3d.view_perspective = 'CAMERA'
    bpy.data.libraries.write(str(out / 'source' / (name + '.blend')), {scene}, fake_user=True, compress=True)
    print(json.dumps(report))


if __name__ == '__main__':
    # A 1 mm longitudinal chamfer; square mating ends preserve the luminous line.
    profile = [(.031,-.011),(.032,-.012),(.043,-.012),(.044,-.011),
               (.044,.011),(.043,.012),(.032,.012),(.031,.011)]
    build(NAME, OUT, profile, (0,2), (.60,.86,.91), 1.0, 6)
