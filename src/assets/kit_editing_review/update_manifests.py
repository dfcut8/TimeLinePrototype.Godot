"""Refresh changed delivery receipts; retain original source/GLB identities."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name, additions in {
    "wall_infill_bay": [],
    "passage_portal_bay_frame": ["passage_portal_bay_frame.gd", "single_record_catalog_entrance.tscn"],
    "catalog_lectern": ["single_record_catalog_station.tscn"],
    "archive_display_plinth": ["empty_archive_display.tscn"],
}.items():
    folder = ASSETS / name
    path = folder / "manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    entries = manifest["files"]
    base = ASSETS if manifest.get("root") == "src/assets" else folder
    prefix = f"{name}/" if base == ASSETS else ""
    names = {prefix + item for item in additions}
    if isinstance(entries, list):
        names.update(entry["path"] for entry in entries)
        manifest["files"] = [{"path": relative, **receipt(base / relative)} for relative in sorted(names)]
    else:
        for relative in sorted(set(entries) | names):
            value = receipt(base / relative)
            entries[relative] = value["sha256"] if manifest.get("algorithm") == "sha256" else value
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

# Its staging helper now also accepts extra resource roots for follow-up suites.
previous = ASSETS / "catalog_perimeter_review"
path = previous / "manifest.json"
manifest = json.loads(path.read_text(encoding="utf-8"))
manifest["files"]["prepare_review.py"] = receipt(previous / "prepare_review.py")
path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

manifest = {
    "issues": [24, 25, 34, 36],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "reused_objects": {name: {
        "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
        "glb": receipt(ASSETS / name / f"{name}.glb"),
    } for name in ("wall_infill_bay", "passage_portal_bay_frame", "catalog_lectern",
                   "archive_display_plinth", "archive_record_small", "archive_record_medium", "archive_record_large")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
