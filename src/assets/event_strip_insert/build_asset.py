"""Issue #14. Run in Blender; creates an isolated scene without clearing user data.

This delivery used a background Blender fallback after both live MCP checks failed.
Coordinates below are Godot metres: +Y up, +Z front.
"""
from pathlib import Path
import runpy
import math
import bpy
import bmesh

OUT = Path(__file__).resolve().parent
H = runpy.run_path(str(OUT.parent / 'event_socket/build_asset.py'))


def outline(w, h, r, z, cy=0):
    points = []
    for cx, y, start in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),
                          (-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
        for i in range(5):
            angle = math.radians(start+i*22.5)
            points.append((cx+r*math.cos(angle), y+cy+r*math.sin(angle), z))
    return points


def plate(name, profiles, materials, cy=0):
    verts = [p for profile in profiles for p in outline(*profile, cy=cy)]
    n = 20
    faces = [tuple(reversed(range(n)))]
    for j in range(len(profiles)-1):
        faces += [(j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i) for i in range(n)]
    faces.append(tuple(range((len(profiles)-1)*n,len(profiles)*n)))
    data = bpy.data.meshes.new(name)
    data.from_pydata([(x,-z,y) for x,y,z in verts],[],faces)
    for mat in materials:
        data.materials.append(mat)
    data.polygons[-1].material_index = len(materials)-1
    bm = bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bmesh.ops.triangulate(bm, faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    data.update()
    uv = data.uv_layers.new(name='UVMap')
    # Presentation triangles share a continuous, correctly oriented full-face UV.
    # Remaining triangles use separate, nonoverlapping grid islands for uniform trim.
    count = len(data.polygons)
    grid = math.ceil(math.sqrt(count))
    for index, face in enumerate(data.polygons):
        points = [data.vertices[data.loops[i].vertex_index].co for i in face.loop_indices]
        front = face.normal.y < -.999 and all(abs(-p.y-profiles[-1][3]) < 1e-7 for p in points)
        if front:
            for loop, p in zip(face.loop_indices, points):
                uv.data[loop].uv = (p.x/profiles[-1][0]+.5,(p.z-cy)/profiles[-1][1]+.5)
        else:
            u = (points[1]-points[0]).normalized()
            v = face.normal.cross(u).normalized()
            coords = [((p-points[0]).dot(u),(p-points[0]).dot(v)) for p in points]
            lo = [min(p[a] for p in coords) for a in range(2)]
            span = max(max(p[a] for p in coords)-lo[a] for a in range(2))
            for loop,p in zip(face.loop_indices,coords):
                uv.data[loop].uv = ((index%grid+.05+.9*(p[0]-lo[0])/span)/grid,
                                   (index//grid+.05+.9*(p[1]-lo[1])/span)/grid)
    obj = bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def build():
    scene = H['new_scene']('event_strip_insert')
    edge = H['material']('insert_edge',(.025,.032,.040))
    front = H['material']('presentation_dark',(.012,.017,.024))
    shader = next(n for n in front.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    shader.inputs['Metallic'].default_value = 0
    shader.inputs['Roughness'].default_value = .82
    obj = plate('BlankInsert',[(.873,.173,.0045,0),(.874,.174,.005,.0005),
                (.874,.174,.005,.0025),(.873,.173,.0045,.003)],[edge,front])
    H['finish'](scene,[obj],OUT,'event_strip_insert',14,(0,0,.0015),.9)


if __name__ == '__main__':
    build()
