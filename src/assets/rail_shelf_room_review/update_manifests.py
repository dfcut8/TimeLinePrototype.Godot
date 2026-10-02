"""Refresh delivery hashes after source/docs/evidence changes."""
import hashlib
import json
from pathlib import Path

assets = Path(__file__).resolve().parent.parent
for name in ('archive_record_medium', 'record_stack_shelf_bay',
             'timeline_rail_housing', 'rail_shelf_room_review'):
    folder = assets / name
    path = folder / 'manifest.json'
    data = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {
        'asset': name, 'issues': [5, 28], 'format': 'local asset handoff manifest v1'}
    data['files'] = [
        {'path': item.relative_to(folder).as_posix(), 'bytes': item.stat().st_size,
         'sha256': hashlib.sha256(item.read_bytes()).hexdigest()}
        for item in sorted(folder.rglob('*'))
        if item.is_file() and item != path and '__pycache__' not in item.parts
        and item.suffix not in ('.pyc', '.uid')
    ]
    path.write_text(json.dumps(data, indent=2)+'\n', encoding='utf-8')
