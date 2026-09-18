"""Issue #11. Run through live Blender MCP after inspecting the current scene."""
from pathlib import Path
import runpy

OUT = Path(__file__).resolve().parent
helper = runpy.run_path(str(OUT.parent / 'event_socket' / 'build_asset.py'))
scene = helper['new_scene']('event_connector_arm')
graphite = helper['material']('archive_graphite', (.048,.060,.073))
lathe = helper['lathe']
# Only the straight shaft stretches. Chamfered terminal pieces translate intact.
base = lathe('ConnectorBase', [(0,.010),(.004,.014),(.028,.014),(.035,.009)],
             [graphite], axis='Y', segments=16)
shaft = lathe('ConnectorShaft', [(0,.009),(.394,.009)],
              [graphite], axis='Y', segments=16)
shaft.location.z = .028  # Blender Z maps to Godot Y.
tip = lathe('ConnectorTip', [(-.035,.009),(-.028,.014),(-.004,.014),(0,.010)],
            [graphite], axis='Y', segments=16)
tip.location.z = .45
helper['finish'](scene,[base,shaft,tip],OUT,'event_connector_arm',11,(0,.225,0),.45)
