"""Refresh receipts for changed object packages and the four-issue review."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent
SOURCE = ASSETS.parent


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name, additions in {
    "timeline_rail_housing": ["centered_timeline_rail.tscn"],
    "archive_record_small": ["dense_shelf_bay.tscn"],
    "archive_record_large": ["dense_shelf_bay.tscn"],
    "record_stack_shelf_bay": ["packed_cassette_shelf_bay.gd", "packed_cassette_shelf_bay.tscn"],
    "reading_bench": ["configurable_reading_alcove.gd", "configurable_reading_alcove.tscn"],
}.items():
    folder = ASSETS / name
    manifest_path = folder / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest["files"]
    base = ASSETS if manifest.get("root") == "src/assets" else folder
    prefix = f"{name}/" if base == ASSETS else ""
    added = {prefix + item for item in additions}
    if isinstance(entries, list):
        names = {entry["path"] for entry in entries} | added
        manifest["files"] = [{"path": relative, **receipt(base / relative)}
                             for relative in sorted(names)]
    else:
        for relative in sorted(set(entries) | added):
            entries[relative] = receipt(base / relative)
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

manifest = {
    "issues": [5, 31, 33, 35],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "assembly": {"path": "assemblies/adaptive_library_room.tscn",
                 **receipt(SOURCE / "assemblies/adaptive_library_room.tscn")},
    "reused_objects": {name: {
        "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
        "glb": receipt(ASSETS / name / f"{name}.glb"),
    } for name in ("timeline_rail_housing", "archive_record_small", "archive_record_medium",
                   "archive_record_large", "record_stack_shelf_bay", "reading_bench")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
