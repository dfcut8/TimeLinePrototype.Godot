"""Refresh receipts for additions and retain the reused-source identities."""
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
    "wall_infill_bay": ["catalog_perimeter.gd", "catalog_perimeter.tscn", "library_catalog_perimeter.tscn"],
    "passage_portal_bay_frame": ["catalog_entrance_sector.tscn"],
    "catalog_lectern": ["configurable_catalog_station.gd", "configurable_catalog_station.tscn"],
    "archive_display_plinth": [],
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
            value = receipt(base / relative)
            entries[relative] = value["sha256"] if manifest.get("algorithm") == "sha256" else value
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

manifest = {
    "issues": [24, 25, 34, 36],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "assembly": {"path": "assemblies/catalog_library_room.tscn",
                 **receipt(SOURCE / "assemblies/catalog_library_room.tscn")},
    "reused_objects": {name: {
        "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
        "glb": receipt(ASSETS / name / f"{name}.glb"),
    } for name in ("wall_infill_bay", "passage_portal_bay_frame", "catalog_lectern",
                   "archive_display_plinth", "archive_record_small", "archive_record_medium", "archive_record_large")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
