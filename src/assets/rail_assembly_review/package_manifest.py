"""Refresh hashes for the two deliveries without changing component assets."""
import hashlib
import json
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--rail-only', action='store_true', help='Leave the independent lectern delivery unchanged')
args = parser.parse_args()
assets = Path(__file__).resolve().parent.parent
for name in (('rail_assembly_review',) if args.rail_only else ('catalog_lectern', 'rail_assembly_review')):
    folder = assets / name
    paths = [p for p in sorted(folder.rglob('*')) if p.is_file() and p.name != 'manifest.json']
    if name == 'rail_assembly_review':
        paths.append(assets / 'timeline_rail_housing/capped_timeline_rail.tscn')
        paths += [assets / 'timeline_rail_housing' / ('configurable_timeline_rail' + ext)
                  for ext in ('.gd', '.tscn')]
        for component in ('timeline_rail_housing', 'rail_recessed_light_insert',
                          'rail_module_joiner', 'timeline_start_cap', 'timeline_end_cap'):
            paths += [assets / component / (component + extension) for extension in ('.glb', '.tscn')]
        paths.append(assets / 'rail_module_joiner/illuminated_rail_module.tscn')
    files = {str(p.relative_to(assets)).replace('\\', '/'): {
        'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()
    } for p in paths}
    (folder / 'manifest.json').write_text(json.dumps({'root': 'src/assets', 'files': files}, indent=2))

# Preserve the original housing manifest schema while adding its reusable assembly.
folder = assets / 'timeline_rail_housing'
manifest_path = folder / 'manifest.json'
manifest = json.loads(manifest_path.read_text())
for row in manifest['files']:
    path = folder / row['path']
    row.update(bytes=path.stat().st_size, sha256=hashlib.sha256(path.read_bytes()).hexdigest())
for filename in ('capped_timeline_rail.tscn', 'configurable_timeline_rail.tscn',
                 'configurable_timeline_rail.gd'):
    assembly = folder / filename
    if not any(row['path'] == assembly.name for row in manifest['files']):
        manifest['files'].append({'path': assembly.name, 'bytes': assembly.stat().st_size,
                                 'sha256': hashlib.sha256(assembly.read_bytes()).hexdigest()})
manifest_path.write_text(json.dumps(manifest, indent=2))
