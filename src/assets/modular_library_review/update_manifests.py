"""Refresh four package receipts, preserving their existing manifest formats."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent
ADDITIONS = {
    "wall_infill_bay": [
        "configurable_bay_arc.gd", "configurable_bay_arc.tscn", "library_perimeter.tscn",
    ],
    "passage_portal_bay_frame": ["portal_bay_arc.tscn", "library_entrance_sector.tscn"],
    "record_stack_shelf_bay": [
        "configurable_cassette_shelf_bay.gd", "configurable_cassette_shelf_bay.tscn",
    ],
    "record_stack_end_cap": [
        "configurable_populated_shelf_row.gd", "configurable_populated_shelf_row.tscn",
    ],
}


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name, additions in ADDITIONS.items():
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
        hashes_only = all(isinstance(value, str) for value in entries.values())
        for relative in sorted(set(entries) | added):
            details = receipt(base / relative)
            entries[relative] = details["sha256"] if hashes_only else details
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n",
                             encoding="utf-8", newline="\n")

reused = {}
for name in (*ADDITIONS, "structural_pier_a", "window_bay_frame", "shelf_light_channel",
             "archive_record_small", "archive_record_medium", "archive_record_large"):
    folder = ASSETS / name
    reused[name] = {
        "source": receipt(folder / "source" / f"{name}.blend"),
        "glb": receipt(folder / f"{name}.glb"),
    }
manifest = {
    "issues": [24, 25, 28, 29],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "reused_objects": reused,
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n",
                                     encoding="utf-8", newline="\n")
