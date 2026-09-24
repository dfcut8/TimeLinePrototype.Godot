"""Read GLB structure and write inspection/hash receipts for issues 14 and 15.

Run from any working directory with Python 3.10+. No external dependencies.
Not a substitute for Blender topology checks or Godot GPU validation.
"""
from pathlib import Path
import hashlib
import json
import struct

ASSETS = Path(__file__).resolve().parent.parent


def inspect(folder):
    name = folder.name
    raw = (folder / (name + '.glb')).read_bytes()
    magic, version, length = struct.unpack_from('<4sII', raw)
    assert magic == b'glTF' and version == 2 and length == len(raw)
    json_size, json_type = struct.unpack_from('<II', raw, 12)
    assert json_type == 0x4E4F534A
    doc = json.loads(raw[20:20+json_size])
    assert all('uri' not in b for b in doc.get('buffers', []))
    assert not doc.get('images') and not doc.get('animations')
    assert not doc.get('cameras') and not doc.get('skins')
    meshes = []
    for mesh in doc['meshes']:
        rows = []
        for prim in mesh['primitives']:
            assert prim.get('mode',4) == 4
            assert {'POSITION','NORMAL','TEXCOORD_0'} <= prim['attributes'].keys()
            index = doc['accessors'][prim['indices']]
            assert index['count'] % 3 == 0
            pos = doc['accessors'][prim['attributes']['POSITION']]
            rows.append(dict(triangles=index['count']//3, material=doc['materials'][prim['material']]['name'],
                             bounds_min=pos['min'],bounds_max=pos['max']))
        meshes.append(dict(name=mesh['name'],surfaces=rows))
    for material in doc['materials']:
        assert material.get('alphaMode','OPAQUE') == 'OPAQUE'
        assert not any(material.get('emissiveFactor',[0,0,0]))
    triangle_count = sum(p['triangles'] for m in meshes for p in m['surfaces'])
    assert triangle_count == (156 if name == 'event_strip_insert' else 404)
    engine = json.loads((folder/'godot_validation.json').read_text())
    assert engine['passed'] and not engine['failures']
    report = dict(asset=name,glb_version=version,bytes=length,triangles=triangle_count,
                  meshes=meshes,materials=doc['materials'],external_dependencies=[],passed=True)
    (folder/'glb_inspection.json').write_text(json.dumps(report,indent=2)+'\n')
    files = []
    for path in sorted(folder.rglob('*')):
        if path.is_file() and path.name != 'manifest.json':
            data = path.read_bytes()
            files.append(dict(path=path.relative_to(folder).as_posix(),bytes=len(data),
                              sha256=hashlib.sha256(data).hexdigest()))
    manifest = dict(asset=name,provenance='Original project geometry; background Blender fallback after failed live MCP checks',
                    license='No new license assigned; no third-party assets',files=files)
    (folder/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    for entry in files:
        assert hashlib.sha256((folder/entry['path']).read_bytes()).hexdigest() == entry['sha256']
    print(f'{name}: GLB v2, {triangle_count} triangles, {len(files)} hashed files, engine pass')


if __name__ == '__main__':
    for asset in ['event_strip_insert','era_label_tab']:
        inspect(ASSETS/asset)
