"""Refresh the four changed package receipts and this review's evidence."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent
PACKAGES = {
    "timeline_rail_housing": "configurable_timeline_rail.gd",
    "catalog_lectern": "configurable_catalog_station.gd",
    "reading_bench": "configurable_reading_alcove.gd",
    "archive_display_plinth": "configurable_archive_display.gd",
}


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for package, script in PACKAGES.items():
    folder = ASSETS / package
    path = folder / "manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    base = ASSETS if manifest.get("root") == "src/assets" else folder
    names = ["README.md", script]
    for name in names:
        relative = f"{package}/{name}" if base == ASSETS else name
        value = receipt(folder / name)
        entries = manifest["files"]
        if isinstance(entries, list):
            entries[:] = [entry for entry in entries if entry["path"] != relative]
            entries.append({"path": relative, **value})
            entries.sort(key=lambda entry: entry["path"])
        else:
            entries[relative] = value["sha256"] if manifest.get("algorithm") == "sha256" else value
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

manifest = {
    "issues": [5, 34, 35, 36],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "production_scripts": {f"{package}/{script}": receipt(ASSETS / package / script)
                           for package, script in PACKAGES.items()},
    "reused_models": {package: {
        "source": receipt(ASSETS / package / "source" / f"{package}.blend"),
        "glb": receipt(ASSETS / package / f"{package}.glb"),
    } for package in (*PACKAGES, "archive_record_small", "archive_record_medium", "archive_record_large")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
print("Updated four package receipts and assembly editing evidence.")
