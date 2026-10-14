"""Stage an isolated dependency closure without changing the open project."""
from pathlib import Path
import re
import shutil
import sys

SOURCE = Path(__file__).resolve().parents[2]
target = Path(sys.argv[1]).resolve()
if not target.is_relative_to(SOURCE / ".godot") or target.exists():
    raise ValueError("Use a new review directory under src/.godot")
pending = ["assets/catalog_perimeter_review/review_room.tscn",
           "assets/catalog_perimeter_review/verify_catalog.gd",
           "assets/catalog_display_review/verify_display.gd",
           "assets/modular_library_review/verify_modular.gd",
           "assets/modular_library_review/review_sector.tscn"]
copied = set()
while pending:
    relative = pending.pop()
    if relative in copied:
        continue
    source = (SOURCE / relative).resolve()
    if not source.is_relative_to(SOURCE) or not source.is_file():
        raise ValueError(f"Invalid resource: {relative}")
    destination = target / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    copied.add(relative)
    if source.suffix in (".tscn", ".gd", ".tres"):
        pending.extend(path for path in re.findall(
            r'"res://([^"\n]+\.(?:tscn|gd|tres|glb))"', source.read_text(encoding="utf-8"))
            if "%" not in path)
    if source.suffix == ".glb":
        shutil.copy2(str(source) + ".import", str(destination) + ".import")
(target / "project.godot").write_text('''config_version=5
[application]
run/main_scene="res://assets/catalog_perimeter_review/review_room.tscn"
[rendering]
renderer/rendering_method="forward_plus"
rendering_device/driver.windows="d3d12"
anti_aliasing/quality/msaa_3d=2
''', encoding="utf-8")
print(f"Copied {len(copied)} resources to {target}")
