"""Refresh changed package receipts and record this editing delivery's evidence."""
from hashlib import sha256
import json
from pathlib import Path

REVIEW = Path(__file__).resolve().parent
ASSETS = REVIEW.parent


def receipt(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": sha256(data).hexdigest()}


for name in ("record_stack_shelf_bay", "record_stack_end_cap",
             "archive_record_small", "archive_record_large",
             "archive_island_review", "adaptive_library_review", "modular_library_review"):
    folder = ASSETS / name
    manifest_path = folder / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest["files"]
    base = ASSETS if manifest.get("root") == "src/assets" else folder
    extra = "cassette_slot_instances.gd"
    additions = ({f"{name}/{extra}" if base == ASSETS else extra}
                 if name == "record_stack_shelf_bay" else set())
    if isinstance(entries, list):
        names = {entry["path"] for entry in entries} | additions
        manifest["files"] = [{"path": relative, **receipt(base / relative)}
                             for relative in sorted(names)]
    else:
        for relative in sorted(set(entries) | additions):
            value = receipt(base / relative)
            entries[relative] = value["sha256"] if manifest.get("algorithm") == "sha256" else value
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")

manifest = {
    "issues": [28, 29, 31, 33],
    "files": {path.name: receipt(path) for path in sorted(REVIEW.iterdir())
              if path.is_file() and path.name != "manifest.json"},
    "production_scripts": {
        relative: receipt(ASSETS / relative) for relative in (
            "record_stack_end_cap/configurable_shelf_row.gd",
            "record_stack_shelf_bay/configurable_cassette_shelf_bay.gd",
            "record_stack_shelf_bay/packed_cassette_shelf_bay.gd",
            "record_stack_shelf_bay/cassette_slot_instances.gd")
    },
    "reused_models": {name: {
        "source": receipt(ASSETS / name / "source" / f"{name}.blend"),
        "glb": receipt(ASSETS / name / f"{name}.glb"),
    } for name in ("record_stack_shelf_bay", "record_stack_end_cap",
                   "archive_record_small", "archive_record_medium", "archive_record_large")},
}
(REVIEW / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
print("Updated seven package/review receipts and archive editing manifest.")
