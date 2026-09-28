"""Build, validate, export and render issue #31 with Blender --background --python."""
from pathlib import Path
OUT = Path(__file__).resolve().parent
scope = {"OUTPUT_DIR": str(OUT), "SIZE": "small", "ISSUE": 31}
for filename in ["build_geometry.py", "export_validate.py", "render_previews.py"]:
    path = OUT.parent / "archive_record_family" / filename
    scope["__file__"] = str(path)
    exec(compile(path.read_text(), str(path), "exec"), scope)
