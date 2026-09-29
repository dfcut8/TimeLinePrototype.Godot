"""Write simple dimension sheets and integrity manifests after validation."""
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
for name,width,notes in [
    ('record_stack_shelf_bay',1.6,['Overall 1.600 W x 2.400 H x 0.440 D m','Shelf tops: 0.160 / 0.720 / 1.280 / 1.840 m','Openings: 1.500 W x 0.520 H x 0.400 D m','Repeat pitch 1.600 m; bottom-center origin','Front +Z, up +Y; Blender front -Y, up +Z']),
    ('record_stack_end_cap',.082,['Envelope 0.082 W x 2.400 H x 0.440 D m','Structural thickness 0.080 m; base 0.120 m','Origin: floor attachment plane, +X outward','Right: X +0.800, yaw 0; left: X -0.800, yaw 180','Single bay centered at origin; scale always 1'])]:
    out=ROOT/name
    svg=['<svg xmlns="http://www.w3.org/2000/svg" width="960" height="720" viewBox="0 0 960 720">','<rect width="960" height="720" fill="#18212c"/>','<g fill="none" stroke="#91aabd" stroke-width="2">']
    front_width=width*170
    svg.append(f'<rect x="70" y="80" width="{front_width}" height="408"/>')
    svg.append('<rect x="420" y="80" width="74.8" height="408"/>')
    if 'bay' in name:
        for top in [.16,.72,1.28,1.84]:
            svg.append(f'<path d="M70 {488-top*170}h272 M420 {488-top*170}h74.8"/>')
    svg+=['</g>','<g fill="#e0eaf2" font-family="sans-serif" font-size="18">',f'<text x="40" y="35">{name} — resolved dimensions (meters)</text>','<text x="70" y="65">Front</text><text x="420" y="65">Side / depth</text>','<text x="540" y="260">Height 2.400 m</text>']
    for i,note in enumerate(notes):
        svg.append(f'<text x="40" y="{545+30*i}">{note}</text>')
    svg+=['</g></svg>']
    (out/'dimensions.svg').write_text('\n'.join(svg),encoding='utf-8')
for name in ['record_stack_shelf_bay','record_stack_end_cap','record_stack_family']:
    folder=ROOT/name
    files=[]
    for p in sorted(folder.rglob('*')):
        if not p.is_file() or p.name=='manifest.json' or p.suffix=='.pyc': continue
        data=p.read_bytes()
        files.append({'path':p.relative_to(folder).as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
    (folder/'manifest.json').write_text(json.dumps({'files':files},indent=2))
    for row in files:
        assert hashlib.sha256((folder/row['path']).read_bytes()).hexdigest()==row['sha256']
    print(name,len(files),'files verified')
