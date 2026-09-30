"""Hash this delivery without touching existing dependencies."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
for name in ("reading_bench", "archive_display_plinth", "furniture_review"):
    folder = root / name
    files = {
        str(path.relative_to(folder)).replace("\\", "/"): {
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        }
        for path in sorted(folder.rglob("*"))
        if path.is_file() and path.name != "manifest.json"
    }
    (folder / "manifest.json").write_text(json.dumps({"files": files}, indent=2))
