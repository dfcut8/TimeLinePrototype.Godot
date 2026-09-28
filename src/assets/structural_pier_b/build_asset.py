"""Narrow pier variant using the family's common source and interfaces."""
from pathlib import Path
import runpy

if __name__ == '__main__':
    runpy.run_path(str(Path(__file__).resolve().parent.parent / 'structural_pier_a' / 'build_asset.py'))['build'](True)
