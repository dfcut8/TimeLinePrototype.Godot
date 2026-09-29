"""Check exported GLB bytes, then hash the delivered files."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
for name, triangles, materials in [('main_floor_slab',20,{'archive_basalt_ceramic'}),
        ('base_uplight_recess_housing',40,{'archive_graphite','archive_warm_diffuser'})]:
    folder=ROOT/name
    data=(folder/(name+'.glb')).read_bytes()
    magic,version,length=struct.unpack_from('<4sII',data)
    assert magic==b'glTF' and version==2 and length==len(data)
    chunk_length,chunk_type=struct.unpack_from('<II',data,12)
    assert chunk_type==0x4e4f534a
    gltf=json.loads(data[20:20+chunk_length])
    assert {m['name'] for m in gltf['materials']}==materials
    assert not gltf.get('images') and not gltf.get('animations')
    assert not any('uri' in b for b in gltf['buffers'])
    measured=0
    for mesh in gltf['meshes']:
        for p in mesh['primitives']:
            assert p.get('mode',4)==4 and 'material' in p
            assert all(a in p['attributes'] for a in ('POSITION','NORMAL','TEXCOORD_0'))
            measured+=gltf['accessors'][p['indices']]['count']//3
    assert measured==triangles
    (folder/'glb_validation.json').write_text(json.dumps(dict(passed=True,glTF=version,triangles=triangles,materials=sorted(materials),self_contained=True),indent=2))
for name in ('main_floor_slab','base_uplight_recess_housing','floor_uplight_review'):
    folder=ROOT/name
    files=[]
    for p in sorted(folder.rglob('*')):
        if p.is_file() and p.name!='manifest.json':
            data=p.read_bytes()
            files.append(dict(path=p.relative_to(folder).as_posix(),bytes=len(data),sha256=hashlib.sha256(data).hexdigest()))
    (folder/'manifest.json').write_text(json.dumps(dict(files=files),indent=2))
    print(name, len(files),'files verified and hashed')
