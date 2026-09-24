"""Issue #12. Execute through live Blender MCP; preserves all existing scenes."""
from pathlib import Path
import runpy
import math
import bpy
import bmesh
from mathutils import Vector

OUT = Path(__file__).resolve().parent
H = runpy.run_path(str(OUT.parent / 'event_socket/build_asset.py'))


def xyz(p):
    return Vector((p[0], -p[2], p[1]))


def empty(name, location, parent=None):
    ob = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    ob.location = xyz(location)
    return ob


def mesh(name, verts, faces, mat, parent=None):
    data = bpy.data.meshes.new(name)
    data.from_pydata([xyz(v) for v in verts], [], faces)
    data.materials.append(mat)
    ob = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(ob)
    ob.parent = parent
    return ob


def finish_mesh(ob):
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(ob.data)
    bm.free()
    ob.data.update()
    uv = ob.data.uv_layers.new(name='UVMap')
    for face in ob.data.polygons:
        points = [ob.data.vertices[ob.data.loops[i].vertex_index].co for i in face.loop_indices]
        u = (points[1]-points[0]).normalized()
        v = face.normal.cross(u).normalized()
        for loop, p in zip(face.loop_indices, points):
            d = p-points[0]
            uv.data[loop].uv = (d.dot(u), d.dot(v))
    return ob


def box(name, center, size, mat, parent=None, bevel=.002):
    verts = [tuple(center[i]+s[i]*size[i]/2 for i in range(3))
             for s in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                       (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    ob = mesh(name, verts, [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),
                            (2,3,7,6),(3,0,4,7)], mat, parent)
    bm = bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2)
    bm.to_mesh(ob.data); bm.free()
    return finish_mesh(ob)


def cylinder(name, rings, mat, axis='Y', center=(0,0,0), parent=None):
    ob = H['lathe'](name, rings, [mat], segments=24)
    for v in ob.data.vertices:
        x,y,z = v.co.x,v.co.z,-v.co.y
        p = (z,x,y) if axis == 'X' else ((x,z,y) if axis == 'Y' else (x,y,z))
        v.co = xyz(tuple(p[i]+center[i] for i in range(3)))
    ob.parent = parent
    # X/Z mappings preserve handedness; Y swaps axes, so recalculate normals.
    ob.data.uv_layers.remove(ob.data.uv_layers[0])
    return finish_mesh(ob)


def yoke(mat, parent):
    # Single U profile avoids overlapping coplanar faces at the bridge/cheeks.
    profile=[(-.039,.016),(.039,.016),(.039,.128),(.026,.128),
             (.026,.034),(-.026,.034),(-.026,.128),(-.039,.128)]
    verts=[(x,y,z) for z in [-.022,.022] for x,y in profile]
    faces=[tuple(reversed(range(8))),tuple(range(8,16))]
    faces += [(i,(i+1)%8,(i+1)%8+8,i+8) for i in range(8)]
    ob=mesh('YawYoke',verts,faces,mat,parent)
    bm=bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bmesh.ops.bevel(bm,geom=list(bm.edges),offset=.001,segments=2)
    bm.to_mesh(ob.data); bm.free()
    return finish_mesh(ob)


def build():
    scene = H['new_scene']('event_strip_rear_pivot')
    graphite = H['material']('archive_graphite', (.048,.060,.073))
    bearing = H['material']('archive_basalt_ceramic', (.095,.112,.125))
    base = cylinder('ConnectorSeat', [(0,.010),(.004,.016),(.026,.016),(.030,.014)], graphite)
    yaw = empty('Yaw', (0,.030,0))
    collar = cylinder('YawBearing', [(0,.014),(.003,.022),(.014,.022),(.018,.020)], bearing, parent=yaw)
    fork = yoke(graphite,yaw)
    pitch = empty('Pitch',(0,.110,0),yaw)
    axle = cylinder('PitchAxle',[(-.026,.018),(-.023,.022),(.023,.022),(.026,.018)], bearing,'X',parent=pitch)
    neck = cylinder('PanelStem',[(.015,.013),(.072,.013)],graphite,'Z',parent=pitch)
    flange = cylinder('PanelFlange',[(.070,.022),(.074,.028),(.081,.028),(.085,.024)],graphite,'Z',parent=pitch)
    empty('PanelAttachment',(0,0,.085),pitch)
    parts = [base,collar,fork,axle,neck,flange]
    H['finish'](scene,parts,OUT,'event_strip_rear_pivot',12,(0,.085,.030),.19)
    # Explicitly select transform nodes so glTF retains the editable two-axis hierarchy.
    for ob in scene.objects:
        ob.select_set(ob.type in {'MESH','EMPTY'})
    bpy.ops.export_scene.gltf(filepath=str(OUT/'event_strip_rear_pivot.glb'),
        use_selection=True,use_active_scene=True,export_animations=False,
        export_cameras=False,export_lights=False,export_yup=True)


if __name__ == '__main__':
    build()
