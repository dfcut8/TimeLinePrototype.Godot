"""Record delivered file hashes; rerun after edits or verification."""
import hashlib,json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
for name in ('wall_infill_bay','passage_portal_bay_frame','wall_portal_review'):
    folder=root/name
    files={str(p.relative_to(folder)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(folder.rglob('*')) if p.is_file() and p.name!='manifest.json'}
    (folder/'manifest.json').write_text(json.dumps({'algorithm':'sha256','files':files},indent=2))
