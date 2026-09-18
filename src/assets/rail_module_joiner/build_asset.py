"""Issue #7 rear saddle, using the shared live-Blender authoring helper."""
from pathlib import Path
import runpy

OUT = Path(__file__).resolve().parent
helper = runpy.run_path(str(OUT.parent / 'rail_recessed_light_insert' / 'build_asset.py'))
# Open-front rear saddle: 0.5 mm face clearance, 2.5 mm wall, 80 mm overlap span.
profile = [(-.020,-.063),(-.0472,-.063),(-.063,-.0472),(-.063,.0472),
           (-.0472,.063),(-.020,.063),(-.020,.0605),(-.0462,.0605),
           (-.0605,.0462),(-.0605,-.0462),(-.0462,-.0605),(-.020,-.0605)]
helper['build']('rail_module_joiner', OUT, profile, (-.04,.04), (.048,.060,.073), 0, 7)
