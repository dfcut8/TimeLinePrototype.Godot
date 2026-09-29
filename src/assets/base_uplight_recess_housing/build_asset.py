"""Uses the floor/fixture family authoring source."""
import runpy
from pathlib import Path
runpy.run_path(str(Path(__file__).resolve().parent.parent/'main_floor_slab'/'build_asset.py'))['build'](True)
