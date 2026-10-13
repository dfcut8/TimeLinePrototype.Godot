"""Refresh the two object receipts and this review's scene/evidence hashes."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name, additions in {
    "record_stack_end_cap": ["capped_mixed_shelf_row.tscn"],
    "reading_bench": ["reading_alcove.tscn"],
}.items():
    folder = ASSETS / name
    manifest_path = folder / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest["files"]
    if isinstance(entries, list):
        names = {entry["path"] for entry in entries} | set(additions)
        manifest["files"] = [{"path": relative, **receipt(folder / relative)}
                             for relative in sorted(names)]
    else:
        for relative in sorted(set(entries) | set(additions)):
            entries[relative] = receipt(folder / relative)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

files = {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
         if path.is_file() and path.name != "manifest.json"}
manifest = {"issues": [29, 35], "files": files,
            "reused_objects": {name: {
                "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
                "glb": receipt(ASSETS / name / f"{name}.glb"),
            } for name in ("record_stack_end_cap", "reading_bench")}}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
