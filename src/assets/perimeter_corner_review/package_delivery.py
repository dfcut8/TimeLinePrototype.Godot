"""Hash repository-native deliveries and make review contact sheets (no CLI certification)."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent
NAMES = ['curved_floor_perimeter_wedge', 'record_stack_corner']


def contact(paths, output):
    sheet = Image.new('RGB', (960, 520), '#171c24')
    draw = ImageDraw.Draw(sheet)
    for i, path in enumerate(paths):
        im = Image.open(path).convert('RGB')
        im.thumbnail((240, 230))
        x, y = (i % 4)*240, (i // 4)*260
        sheet.paste(im, (x+(240-im.width)//2, y))
        draw.text((x+8, y+234), path.stem, fill='white')
    sheet.save(output)


for name, tag in zip(NAMES, ['floor', 'corner']):
    folder = ASSETS/name
    contact([folder/f'preview_{v}.png' for v in ['front', 'rear', 'side', 'underside']] +
            [HERE/f'godot_{tag}_{v}.png' for v in ['front', 'rear', 'join_detail' if tag == 'floor' else 'side', 'underside']],
            folder/'review_contact_sheet.png')
    (folder/'godot_validation.json').write_text((HERE/'godot_validation.json').read_text())

for folder in [*(ASSETS/n for n in NAMES), HERE]:
    files = {}
    for path in sorted(folder.rglob('*')):
        if path.is_file() and path.name != 'manifest.json' and not path.name.endswith(('.blend1', '.pyc')):
            content = path.read_bytes()
            files[path.relative_to(folder).as_posix()] = {'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()}
    manifest = {'format': 'repository-native-asset-delivery-v1', 'files': files,
                'provenance': 'Original project modeling; no external mesh or paid provider',
                'license': 'No new redistribution license assigned',
                'validation': 'See validation.json and shared Godot report; live MCP unavailable'}
    (folder/'manifest.json').write_text(json.dumps(manifest, indent=2))
    for relative, expected in files.items():
        assert hashlib.sha256((folder/relative).read_bytes()).hexdigest() == expected['sha256']
    print(f'{folder.name}: verified {len(files)} file hashes')
