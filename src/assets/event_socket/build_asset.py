"""Original issue #10 geometry. Execute this file through live Blender MCP.

Coordinates supplied here are Godot metres (X chronology, Y up, Z front).
Creates a new scene; never clears or saves over the user's current Blender file.
"""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent


def material(name, color):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = .68
    shader.inputs['Metallic'].default_value = .22
    mat.diffuse_color = (*color, 1)
    return mat


def new_scene(name):
    scene = bpy.data.scenes.new(name + '_Review')
    bpy.context.window.scene = scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    return scene


def lathe(name, rings, materials, accent_segments=(), axis='Z', segments=32):
    """Closed revolved profile: rings are (axial distance, radius)."""
    verts = []
    for distance, radius in rings:
        for i in range(segments):
            angle = 2 * math.pi * i / segments
            x, radial = radius * math.cos(angle), radius * math.sin(angle)
            y, z = (radial, distance) if axis == 'Z' else (distance, radial)
            verts.append((x, -z, y))
    faces = [tuple(reversed(range(segments)))]
    indices = [0]
    for j in range(len(rings) - 1):
        for i in range(segments):
            k = (i + 1) % segments
            faces.append((j*segments+i, j*segments+k, (j+1)*segments+k, (j+1)*segments+i))
            indices.append(1 if j in accent_segments else 0)
    faces.append(tuple(range((len(rings)-1)*segments, len(rings)*segments)))
    indices.append(0)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    for mat in materials:
        mesh.materials.append(mat)
    for polygon, index in zip(mesh.polygons, indices):
        polygon.material_index = index
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    # Independent planar triangle UV islands avoid pole singularities and degenerate UVs.
    uv = mesh.uv_layers.new(name='UVMap')
    for face in mesh.polygons:
        points = [mesh.vertices[mesh.loops[i].vertex_index].co for i in face.loop_indices]
        u = (points[1] - points[0]).normalized()
        v = face.normal.cross(u).normalized()
        for loop, point in zip(face.loop_indices, points):
            d = point - points[0]
            uv.data[loop].uv = (d.dot(u), d.dot(v))
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def finish(scene, objects, out, name, issue, center, span):
    out.mkdir(parents=True, exist_ok=True)
    (out / 'source').mkdir(exist_ok=True)
    (out / 'source' / '.gdignore').touch()
    rows = []
    for obj in objects:
        obj.select_set(True)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        row = dict(name=obj.name, triangles=len(obj.data.polygons),
                   materials=len(obj.data.materials), uv_layers=len(obj.data.uv_layers),
                   non_manifold_edges=sum(not e.is_manifold for e in bm.edges),
                   degenerate_faces=sum(f.calc_area() < 1e-12 for f in bm.faces),
                   signed_volume_m3=bm.calc_volume(signed=True))
        bm.free()
        assert row['non_manifold_edges'] == row['degenerate_faces'] == 0
        assert row['signed_volume_m3'] > 0
        rows.append(row)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(out / (name + '.glb')),
        use_selection=True, use_active_scene=True, export_animations=False,
        export_cameras=False, export_lights=False, export_yup=True)
    report = dict(issue=issue, blender_version=bpy.app.version_string, meshes=rows,
                  triangles=sum(r['triangles'] for r in rows), passed=True)
    (out / 'validation.json').write_text(json.dumps(report, indent=2))
    world = bpy.data.worlds.new(name + '_World')
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == 'BACKGROUND')
    bg.inputs[0].default_value = (.12, .14, .17, 1)
    bg.inputs[1].default_value = .6
    scene.world = world
    camera = bpy.data.objects.new('ReviewCamera', bpy.data.cameras.new('ReviewCamera'))
    scene.collection.objects.link(camera)
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = span * 1.6
    scene.camera = camera
    target = Vector((center[0], -center[2], center[1]))
    def aim(obj, offset):
        obj.location = target + Vector(offset) * span
        obj.rotation_euler = (target-obj.location).to_track_quat('-Z', 'Y').to_euler()
    for label, offset, power in [('Key', (0,-2,3),400), ('Rear',(1,2,1),300), ('Under',(0,-1,-2),150)]:
        data = bpy.data.lights.new(label, 'AREA')
        data.energy = power * span * span
        data.size = span * 2
        lamp = bpy.data.objects.new(label, data)
        scene.collection.objects.link(lamp)
        aim(lamp, offset)
    try:
        scene.render.engine = 'BLENDER_EEVEE'
    except TypeError:
        pass
    scene.render.resolution_x = 800
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    for label, offset in [('front',(.6,-2,.5)), ('rear',(-.6,2,.5)), ('underside',(.6,-1,-2)), ('side',(2,-.3,.1))]:
        aim(camera, offset)
        scene.render.filepath = str(out / ('preview_' + label + '.png'))
        bpy.ops.render.render(write_still=True)
    aim(camera, (.6,-2,.5))
    for area in bpy.context.screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.region_3d.view_perspective = 'CAMERA'
    bpy.data.libraries.write(str(out / 'source' / (name + '.blend')), {scene}, fake_user=True, compress=True)
    print(json.dumps(report))


def build():
    scene = new_scene('event_socket')
    graphite = material('archive_graphite', (.048,.060,.073))
    accent = material('event_emphasis', (.12,.42,.48))
    # Continuous stepped disk, with an integral cyan ring and recessed central face.
    body = lathe('SocketBody', [(.060,.051),(.064,.055),(.082,.055),(.087,.050),
        (.087,.042),(.0875,.040),(.0875,.033),(.085,.031)], [graphite, accent], (4,5,6))
    upper = lathe('UpperMount',[(.048,.012),(.065,.012),(.068,.010)], [graphite], axis='Y', segments=16)
    lower = lathe('LowerMount',[(-.068,.010),(-.065,.012),(-.048,.012)], [graphite], axis='Y', segments=16)
    # Move vertices, keeping exported object transforms identity.
    for obj in [upper, lower]:
        for vertex in obj.data.vertices:
            vertex.co.y -= .074
    finish(scene,[body,upper,lower],OUT,'event_socket',10,(0,0,.074),.136)


if __name__ == '__main__':
    build()
