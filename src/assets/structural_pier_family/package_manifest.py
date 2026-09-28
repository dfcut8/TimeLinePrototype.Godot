"""Validate GLB bytes and refresh per-directory SHA-256 manifests after review."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
for variant in ('a', 'b'):
    name = 'structural_pier_' + variant
    folder = ROOT / name
    data = (folder / (name + '.glb')).read_bytes()
    magic, version, length = struct.unpack_from('<4sII', data)
    assert magic == b'glTF' and version == 2 and length == len(data)
    chunk_length, chunk_type = struct.unpack_from('<II', data, 12)
    assert chunk_type == 0x4e4f534a
    gltf = json.loads(data[20:20+chunk_length])
    assert gltf['asset']['version'] == '2.0'
    assert len(gltf['meshes']) == 1 and len(gltf['materials']) == 2
    assert not gltf.get('images') and not gltf.get('animations')
    assert not any('uri' in buffer for buffer in gltf['buffers'])
    triangles = 0
    for primitive in gltf['meshes'][0]['primitives']:
        assert primitive.get('mode', 4) == 4
        assert all(key in primitive['attributes'] for key in ('POSITION','NORMAL','TEXCOORD_0'))
        triangles += gltf['accessors'][primitive['indices']]['count'] // 3
    assert triangles == 76
    (folder / 'glb_validation.json').write_text(json.dumps(dict(
        gltf_version=version, triangles=triangles, materials=2,
        self_contained=True, images=0, animations=0, passed=True), indent=2))

for name in ('structural_pier_a','structural_pier_b','structural_pier_family'):
    folder = ROOT / name
    entries = []
    for path in sorted(folder.rglob('*')):
        if path.is_file() and path.name != 'manifest.json':
            data = path.read_bytes()
            entries.append(dict(path=path.relative_to(folder).as_posix(), bytes=len(data),
                sha256=hashlib.sha256(data).hexdigest()))
    (folder / 'manifest.json').write_text(json.dumps(dict(files=entries),indent=2))
    print(name, len(entries), 'files hashed')
