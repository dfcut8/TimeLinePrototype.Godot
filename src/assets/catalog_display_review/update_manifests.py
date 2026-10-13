"""Refresh receipts for the four object packages and their shared review."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name, additions in {
    "archive_record_small": ["plinth_display.tscn"],
    "archive_record_large": ["plinth_display.tscn"],
    "archive_display_plinth": ["configurable_archive_display.gd", "configurable_archive_display.tscn"],
    "catalog_lectern": ["catalog_comparison_station.tscn"],
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
    "issues": [31, 33, 34, 36],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "reused_objects": {name: {
        "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
        "glb": receipt(ASSETS / name / f"{name}.glb"),
    } for name in ("archive_record_small", "archive_record_medium", "archive_record_large",
                   "archive_display_plinth", "catalog_lectern")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
