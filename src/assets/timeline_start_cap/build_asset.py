"""Shared cap source. Execute through live Blender MCP; existing scenes survive."""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parent.parent
# The same closed octagonal cross-section serves both ends. Its full face closes
# the light recess as well as the housing, with no sleeve or internal penetration.
PROFILE = [(-.046,-.060),(.046,-.060),(.060,-.046),(.060,.046),
           (.046,.060),(-.046,.060),(-.060,.046),(-.060,-.046)]

def build_cap(later=False):
    name = 'timeline_end_cap' if later else 'timeline_start_cap'
    out = ROOT / name
    (out / 'source').mkdir(parents=True, exist_ok=True)
    (out / 'source' / '.gdignore').touch()
    helper = runpy.run_path(str(ROOT / 'rail_recessed_light_insert' / 'build_asset.py'))
    helper['build'](name, out, PROFILE, (0,.004) if later else (-.004,0),
                    (.048,.060,.073), 0, 9 if later else 8)

if __name__ == '__main__':
    build_cap()
