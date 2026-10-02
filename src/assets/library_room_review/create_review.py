"""Compose the existing V5 assets at their resolved, unscaled dimensions."""
from math import cos, sin, radians
from pathlib import Path

OUT = Path(__file__).resolve().parent
ASSETS = ('wall_infill_bay/wall_infill_bay',
          'passage_portal_bay_frame/passage_portal_bay_frame',
          'window_bay_frame/window_bay_frame', 'structural_pier_a/structural_pier_a',
          'archive_record_small/shelf_assembly', 'archive_record_large/shelf_assembly',
          'timeline_rail_housing/configurable_timeline_rail')
lines = ['[gd_scene load_steps=8 format=3]']
for i, asset in enumerate(ASSETS, 1):
    lines.append(f'[ext_resource type="PackedScene" path="res://assets/{asset}.tscn" id="{i}"]')
lines.append('[node name="LibraryRoomAssembly" type="Node3D"]')
for group in ('Perimeter', 'Shelves'):
    lines.append(f'[node name="{group}" type="Node3D" parent="."]')

def place(name, parent, resource, angle, radius):
    a = radians(angle)
    lines.extend([f'[node name="{name}" parent="{parent}" instance=ExtResource("{resource}")]',
                  f'position = Vector3({radius*sin(a):.9f}, 0, {-radius*cos(a):.9f})',
                  f'rotation_degrees = Vector3(0, {-angle}, 0)'])

for i in range(24):
    resource = 2 if i in (0, 12) else 3 if i in (6, 18) else 1
    place(f'Bay{i}', 'Perimeter', resource, i*15, 24.8*cos(radians(7.5)))
    place(f'Pier{i}', 'Perimeter', 4, i*15-7.5, 24.8)
for j, i in enumerate((2, 4, 8, 10, 14, 16, 20, 22)):
    place(f'Shelf{j}', 'Shelves', 5+j%2, i*15, 23.0)
lines.extend(['[node name="Timeline" parent="." instance=ExtResource("7")]',
              'position = Vector3(-7, 1.5, 0)', 'module_count = 7'])
(OUT/'library_room_assembly.tscn').write_text('\n\n'.join(lines)+'\n')
