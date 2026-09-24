"""Issue #15. Isolated Blender scene, original era label and rail-top mount."""
from pathlib import Path
import runpy

OUT = Path(__file__).resolve().parent
P = runpy.run_path(str(OUT.parent / 'event_strip_insert/build_asset.py'))
H = P['H']


def build():
    scene = H['new_scene']('era_label_tab')
    graphite = H['material']('archive_graphite',(.048,.060,.073))
    ceramic = H['material']('archive_basalt_ceramic',(.095,.112,.125))
    base = H['lathe']('RailTopSeat',[(0,.009),(.002,.012),(.010,.012),(.012,.010)],
                      [graphite],axis='Y',segments=16)
    stem = H['lathe']('HairlineMount',[(.009,.004),(.011,.005),(.085,.005),(.087,.004)],
                      [graphite],axis='Y',segments=16)
    tab = P['plate']('EraLabel',[(.318,.068,.003,-.004),(.320,.070,.004,-.003),
                     (.320,.070,.004,.003),(.318,.068,.003,.004)],
                     [graphite,ceramic],cy=.120)
    H['finish'](scene,[base,stem,tab],OUT,'era_label_tab',15,(0,.08,0),.34)


if __name__ == '__main__':
    build()
