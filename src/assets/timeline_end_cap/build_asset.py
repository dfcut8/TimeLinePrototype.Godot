"""Named later-end variant using the start cap's shared profile and authoring code."""
from pathlib import Path
import runpy

if __name__ == '__main__':
    shared = Path(__file__).resolve().parent.parent / 'timeline_start_cap' / 'build_asset.py'
    runpy.run_path(str(shared))['build_cap'](later=True)
