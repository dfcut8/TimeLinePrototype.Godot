"""Issue #13. Original closed rounded shell, authored in live Blender MCP."""
from pathlib import Path
import runpy
import math

OUT = Path(__file__).resolve().parent
P = runpy.run_path(str(OUT.parent/'event_strip_rear_pivot/build_asset.py'))
H = P['H']


def outline(w,h,r,z):
    points=[]
    for cx,cy,start in [(w/2-r,h/2-r,0),(-w/2+r,h/2-r,90),
                        (-w/2+r,-h/2+r,180),(w/2-r,-h/2+r,270)]:
        for i in range(5):
            a=math.radians(start+i*22.5)
            points.append((cx+r*math.cos(a),cy+r*math.sin(a),z))
    return points


def shell(mat):
    # One continuous closed basin: finished back, chamfer, lip, inner wall and floor.
    profiles=[(.892,.192,.008,.006),(.900,.200,.012,.010),
              (.900,.200,.012,.027),(.894,.194,.009,.030),
              (.876,.176,.006,.030),(.876,.176,.006,.015)]
    verts=[p for profile in profiles for p in outline(*profile)]
    n=20
    faces=[tuple(reversed(range(n)))]
    for j in range(len(profiles)-1):
        for i in range(n):
            k=(i+1)%n
            faces.append((j*n+i,j*n+k,(j+1)*n+k,(j+1)*n+i))
    faces.append(tuple(range((len(profiles)-1)*n,len(profiles)*n)))
    return P['finish_mesh'](P['mesh']('StripShell',verts,faces,mat))


def build():
    scene=H['new_scene']('event_strip_casing')
    graphite=H['material']('archive_graphite',(.048,.060,.073))
    body=shell(graphite)
    mount=P['cylinder']('RearMount',[(0,.024),(.004,.028),(.008,.028)],graphite,'Z')
    H['finish'](scene,[body,mount],OUT,'event_strip_casing',13,(0,0,.015),.9)


if __name__ == '__main__':
    build()
