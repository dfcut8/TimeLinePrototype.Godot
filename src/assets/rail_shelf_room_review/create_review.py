"""Build reusable mixed shelves using existing, independently instanced cassettes."""
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent
lines = ['[gd_scene load_steps=5 format=3]',
         '[ext_resource type="PackedScene" path="res://assets/record_stack_shelf_bay/illuminated_shelf_bay.tscn" id="shelf"]']
sizes = ('small', 'medium', 'large')
for size in sizes:
    lines.append(f'[ext_resource type="PackedScene" path="res://assets/archive_record_{size}/archive_record_{size}.tscn" id="{size}"]')
lines += ['[node name="MixedCassetteShelfBay" type="Node3D"]',
          '[node name="Shelf" parent="." instance=ExtResource("shelf")]']
for tier, y in enumerate((.16, .72, 1.28, 1.84)):
    for slot in range(9):
        size = sizes[slot % 3]
        z = (.08, .055, .03)[slot % 3]
        lines += [f'[node name="Record_{tier}_{slot}" parent="." instance=ExtResource("{size}")]',
                  f'position = Vector3({(slot-4)*.15:.6f}, {y:.6f}, {z:.6f})']
(ASSETS / 'record_stack_shelf_bay/mixed_cassette_shelf_bay.tscn').write_text('\n\n'.join(lines)+'\n', encoding='utf-8')
