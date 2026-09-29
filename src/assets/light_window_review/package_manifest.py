"""Check portable deliveries and refresh hashes after authoring/engine review."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
for name in ('shelf_light_channel', 'window_bay_frame'):
    folder = ROOT / name
    data = (folder / (name + '.glb')).read_bytes()
    magic, version, length = struct.unpack_from('<4sII', data)
    assert (magic, version, length) == (b'glTF', 2, len(data))
    chunk_length = struct.unpack_from('<I', data, 12)[0]
    gltf = json.loads(data[20:20 + chunk_length])
    assert not gltf.get('images') and not gltf.get('animations')
    assert len(gltf['materials']) == 3
    assert all('uri' not in buffer for buffer in gltf['buffers'])
    triangles = 0
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            assert {'POSITION', 'NORMAL', 'TEXCOORD_0'} <= primitive['attributes'].keys()
            triangles += gltf['accessors'][primitive['indices']]['count'] // 3
    validation = json.loads((folder / 'validation.json').read_text())
    assert validation['passed'] and triangles == validation['triangles']
    assert hashlib.sha256(data).hexdigest() == validation['glb_sha256']
    assert (folder / 'source' / (name + '.blend')).is_file()
    assert (folder / (name + '.tscn')).is_file()

report = json.loads((ROOT / 'light_window_review/godot_validation.json').read_text())
assert report['passed'] and not report['failures']
for name in ('shelf_light_channel', 'window_bay_frame', 'light_window_review'):
    folder = ROOT / name
    files = []
    for path in sorted(folder.rglob('*')):
        if not path.is_file() or path.name == 'manifest.json' or '__pycache__' in path.parts:
            continue
        files.append({'path': path.relative_to(folder).as_posix(),
                      'bytes': path.stat().st_size,
                      'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
    (folder / 'manifest.json').write_text(json.dumps({'files': files}, indent=2) + '\n')
print('Both GLBs, sources, scenes, validation reports and manifests passed.')
